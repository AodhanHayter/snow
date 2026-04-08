{ lib, ... }:

let
  inherit (lib) mkOption types mapAttrsToList concatStringsSep imap0 sort lessThan
    escapeShellArg mapAttrs mapAttrs' attrValues;
  inherit (builtins) attrNames listToAttrs hashString substring toString;
in
{
  avm = rec {

    macFromName = name:
      let h = hashString "sha256" name;
      in "02:00:00:${substring 0 2 h}:${substring 2 2 h}:${substring 4 2 h}";

    assignPorts = vmDefs:
      let
        sorted = sort lessThan (attrNames vmDefs);
        indexed = imap0 (i: name: { inherit name i; def = vmDefs.${name}; }) sorted;
      in
      listToAttrs (map (vm: {
        name = vm.name;
        value = {
          sshPort = if vm.def.sshPort != 0 then vm.def.sshPort else 2222 + vm.i;
          gvproxyPort = if vm.def.gvproxyPort != 0 then vm.def.gvproxyPort else 17777 + vm.i;
        };
      }) indexed);

    # Shared option submodule — used by both darwin and nixos modules
    vmSubmodule = types.submodule {
      options = {
        mem = lib.modernage.mkOpt types.int 4096 "Memory in MiB (avoid 2048 — QEMU bug).";
        vcpu = lib.modernage.mkOpt types.int 2 "Number of virtual CPUs.";
        projects = lib.modernage.mkOpt (types.attrsOf types.str) { } "Project directories to share. { name = \"/host/path\"; }";
        forwardPorts = mkOption {
          type = types.listOf (types.submodule {
            options = {
              host = lib.modernage.mkOpt types.port 0 "Host port.";
              guest = lib.modernage.mkOpt types.port 0 "Guest port.";
            };
          });
          default = [ ];
          description = "Additional ports to forward from host to guest.";
        };
        extraPackages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra packages to install in the guest.";
        };
        sshPort = lib.modernage.mkOpt types.int 0 "SSH port on host (0 = auto-assign from 2222).";
        gvproxyPort = lib.modernage.mkOpt types.int 0 "gvproxy API port (0 = auto-assign from 17777).";
        authorizedKeys = lib.modernage.mkOpt (types.listOf types.str) [ ] "SSH public keys for the agent user.";
      };
    };

    # Shared module config builder
    mkModuleConfig = {
      cfg,
      pkgs,
      inputs,
      guestSystem,
      mkLauncher,
      resolveKeys,
      isDarwin,
    }:
      let
        ports = assignPorts cfg.vms;

        guestSystems = mapAttrs (name: vmDef: mkGuestSystem {
          nixpkgs = inputs.nixpkgs;
          microvm = inputs.microvm;
          inherit name guestSystem;
          inherit (vmDef) mem vcpu projects forwardPorts extraPackages;
          sshPort = ports.${name}.sshPort;
          authorizedKeys = resolveKeys vmDef;
        }) cfg.vms;

        launchers = mapAttrs (name: vmDef: mkLauncher {
          inherit pkgs;
          vmName = name;
          guestConfig = guestSystems.${name};
          sshPort = ports.${name}.sshPort;
          gvproxyPort = ports.${name}.gvproxyPort;
          inherit (vmDef) projects forwardPorts;
        }) cfg.vms;

        sshBinary = if isDarwin then "/usr/bin/ssh" else "${pkgs.openssh}/bin/ssh";
        sshKeygen = if isDarwin then "/usr/bin/ssh-keygen" else "${pkgs.openssh}/bin/ssh-keygen";

        cli = mkCli {
          inherit pkgs ports launchers sshBinary sshKeygen;
          vmDefs = cfg.vms;
          sshKeyDir = "$HOME/.config/avm";
        };
      in {
        assertions = [
          {
            assertion = inputs ? microvm;
            message = "agent-dev-vm requires the 'microvm' flake input.";
          }
          {
            assertion = builtins.all (vm: vm.mem != 2048) (attrValues cfg.vms);
            message = "VM memory must not be 2048 MiB (QEMU hang bug). Use 4096 or other values.";
          }
        ];
        environment.systemPackages = [ cli ];
      };

    mkGuestSystem = {
      nixpkgs,
      microvm,
      name,
      mem,
      vcpu,
      projects,
      forwardPorts,
      extraPackages,
      authorizedKeys,
      sshPort,
      guestSystem,
    }:
      let
        projectMounts = mapAttrs' (pname: _: {
          name = "/mnt/${pname}";
          value = {
            device = pname;
            fsType = "virtiofs";
            options = [ "nofail" ];
          };
        }) projects;

        microvmForwardPorts = [
          { from = "host"; host.port = sshPort; guest.port = 22; }
        ] ++ map (p: {
          from = "host";
          host.port = p.host;
          guest.port = p.guest;
        }) forwardPorts;

      in nixpkgs.lib.nixosSystem {
        system = guestSystem;
        modules = [
          microvm.nixosModules.microvm
          {
            networking.hostName = name;

            microvm = {
              hypervisor = "qemu";
              inherit mem vcpu;
              interfaces = [{
                type = "user";
                id = "usernet";
                mac = macFromName name;
              }];
              forwardPorts = microvmForwardPorts;
              shares = [];
            };

            fileSystems = projectMounts;

            networking.useDHCP = true;
            systemd.network.networks."10-virtio" = {
              matchConfig.Driver = "virtio_net";
              addresses = [{ Address = "192.168.127.2/24"; }];
              routes = [{ Gateway = "192.168.127.1"; }];
              networkConfig.DNS = "192.168.127.1";
            };

            services.openssh = {
              enable = true;
              settings = {
                PasswordAuthentication = false;
                StreamLocalBindUnlink = true;
              };
            };

            users.users.agent = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              openssh.authorizedKeys.keys = authorizedKeys;
            };

            security.sudo.wheelNeedsPassword = false;

            environment.systemPackages = with nixpkgs.legacyPackages.${guestSystem}; [
              git curl wget htop tmux
              devenv
            ] ++ extraPackages;

            system.stateVersion = "25.11";
          }
        ];
      };

    mkVfkitLauncher = {
      pkgs,
      vmName,
      guestConfig,
      sshPort,
      gvproxyPort,
      projects,
      forwardPorts,
    }:
      let
        microvmCfg = guestConfig.config.microvm;
        kernelParams = concatStringsSep " " microvmCfg.kernelParams;

        gvproxyExposeCommands = concatStringsSep "\n" (
          [''curl -s http://127.0.0.1:${toString gvproxyPort}/services/forwarder/expose -X POST -d '{"local":":${toString sshPort}","remote":"192.168.127.2:22"}' || true'']
          ++ map (p:
            ''curl -s http://127.0.0.1:${toString gvproxyPort}/services/forwarder/expose -X POST -d '{"local":":${toString p.host}","remote":"192.168.127.2:${toString p.guest}"}' || true''
          ) forwardPorts
        );

        shareDevices = concatStringsSep " \\\n            " (
          mapAttrsToList (pname: hostPath:
            "--device virtio-fs,sharedDir=${escapeShellArg hostPath},mountTag=${pname}"
          ) projects
        );

      in pkgs.writeShellScriptBin "avm-start-${vmName}" ''
        set -euo pipefail

        VM_DIR="''${XDG_RUNTIME_DIR:-/tmp}/avm/${vmName}"
        VFKIT_SOCK="$VM_DIR/vfkit.sock"
        PID_FILE="$VM_DIR/vm.pid"

        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
          echo "${vmName} already running (PID $(cat "$PID_FILE"))"
          exit 0
        fi

        cleanup() {
          [ -n "''${VFKIT_PID:-}" ] && kill "$VFKIT_PID" 2>/dev/null || true
          [ -n "''${GVPROXY_PID:-}" ] && kill "$GVPROXY_PID" 2>/dev/null || true
          rm -f "$PID_FILE" "$VM_DIR/gvproxy.pid" "$VFKIT_SOCK" "$VM_DIR"/vfkit-*.sock
          wait 2>/dev/null || true
        }
        trap cleanup EXIT INT TERM

        mkdir -p "$VM_DIR"

        # Hard-link store disk from Nix store; fall back to copy if cross-device
        STORE_DISK="$VM_DIR/store.erofs"
        STORE_SRC="${microvmCfg.storeDisk}"
        if [ ! -f "$STORE_DISK" ] || [ "$(readlink -f "$STORE_SRC")" != "$(cat "$VM_DIR/.store-src" 2>/dev/null)" ]; then
          echo "Preparing store disk..."
          ln -f "$STORE_SRC" "$STORE_DISK" 2>/dev/null || cp "$STORE_SRC" "$STORE_DISK"
          chmod 644 "$STORE_DISK"
          readlink -f "$STORE_SRC" > "$VM_DIR/.store-src"
        fi

        ${pkgs.gvproxy}/bin/gvproxy \
          -listen-vfkit "unixgram://$VFKIT_SOCK" \
          -listen tcp://127.0.0.1:${toString gvproxyPort} \
          -ssh-port ${toString sshPort} &
        GVPROXY_PID=$!
        sleep 1

        ${pkgs.vfkit}/bin/vfkit \
          --cpus ${toString microvmCfg.vcpu} \
          --memory ${toString microvmCfg.mem} \
          --kernel ${microvmCfg.kernel}/Image \
          --initrd ${microvmCfg.initrdPath} \
          --kernel-cmdline '${kernelParams} console=hvc0 console=ttyAMA0 reboot=t panic=-1' \
          --device "virtio-blk,path=$STORE_DISK" \
          --device virtio-net,unixSocketPath=$VFKIT_SOCK,mac=${macFromName vmName} \
          --device virtio-serial,logFilePath=$VM_DIR/console.log \
          --device virtio-rng \
          ${shareDevices} &
        VFKIT_PID=$!
        echo "$VFKIT_PID" > "$PID_FILE"
        echo "$GVPROXY_PID" > "$VM_DIR/gvproxy.pid"

        # Poll for gvproxy readiness, then expose ports
        for _i in $(seq 1 30); do
          curl -s -o /dev/null http://127.0.0.1:${toString gvproxyPort}/services/forwarder/expose 2>/dev/null && break
          sleep 0.5
        done
        ${gvproxyExposeCommands}

        wait $VFKIT_PID
      '';

    mkQemuLauncher = {
      pkgs,
      vmName,
      guestConfig,
      sshPort,
      projects,
      forwardPorts,
      ...
    }:
      let
        microvmCfg = guestConfig.config.microvm;
        kernelParams = concatStringsSep " " microvmCfg.kernelParams;

        hostfwdArgs = concatStringsSep "," (
          [ "hostfwd=tcp::${toString sshPort}-:22" ]
          ++ map (p: "hostfwd=tcp::${toString p.host}-:${toString p.guest}") forwardPorts
        );

        shareArgs = concatStringsSep " \\\n            " (
          imap0 (i: pname:
            let hostPath = projects.${pname}; in
            "-fsdev 'local,id=fs${toString i},path=${hostPath},security_model=none' "
            + "-device 'virtio-9p-pci,fsdev=fs${toString i},mount_tag=${pname}'"
          ) (attrNames projects)
        );

        arch = if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64" else "x86_64";
        machineType = if arch == "aarch64"
          then "virt,accel=kvm:tcg,gic-version=max"
          else "q35,accel=kvm:tcg";
        consoleDevice = if arch == "aarch64" then "ttyAMA0" else "ttyS0";
        kernelImage = if arch == "aarch64" then "Image" else "bzImage";

      in pkgs.writeShellScriptBin "avm-start-${vmName}" ''
        set -euo pipefail

        VM_DIR="''${XDG_RUNTIME_DIR:-/tmp}/avm/${vmName}"
        PID_FILE="$VM_DIR/vm.pid"

        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
          echo "${vmName} already running (PID $(cat "$PID_FILE"))"
          exit 0
        fi

        cleanup() {
          rm -f "$PID_FILE"
        }
        trap cleanup EXIT INT TERM

        mkdir -p "$VM_DIR"

        ${pkgs.qemu}/bin/qemu-system-${arch} \
          -name ${vmName} \
          -M ${machineType} \
          -cpu host \
          -m ${toString microvmCfg.mem} \
          -smp ${toString microvmCfg.vcpu} \
          -nodefaults \
          -no-user-config \
          -no-reboot \
          -nographic \
          -serial mon:stdio \
          -device virtio-rng-pci \
          -kernel ${microvmCfg.kernel}/${kernelImage} \
          -initrd ${microvmCfg.initrdPath} \
          -append '${kernelParams} console=${consoleDevice} reboot=t panic=-1' \
          -drive 'id=store,format=raw,read-only=on,file=${microvmCfg.storeDisk},if=none' \
          -device 'virtio-blk-pci,drive=store' \
          -netdev 'user,id=usernet,${hostfwdArgs}' \
          -device 'virtio-net-pci,netdev=usernet,mac=${macFromName vmName}' \
          ${shareArgs} &
        echo $! > "$PID_FILE"
        wait
      '';

    mkCli = { pkgs, vmDefs, launchers, ports, sshKeyDir, sshBinary, sshKeygen }:
      let
        firstProject = vmDef:
          let names = attrNames vmDef.projects;
          in if names == [] then "" else builtins.head names;

        vmCases = concatStringsSep "\n" (mapAttrsToList (vmName: vmDef:
          let
            p = ports.${vmName};
            launcher = launchers.${vmName};
            proj = firstProject vmDef;
            projectCd = if proj != "" then "cd /mnt/${proj} 2>/dev/null || true" else "";
          in ''
            ${vmName})
              SSH_PORT=${toString p.sshPort}
              LAUNCHER="${launcher}/bin/avm-start-${vmName}"
              PROJECT_CD="${projectCd}"
              ;;''
        ) vmDefs);

        vmList = concatStringsSep ", " (attrNames vmDefs);

      in pkgs.writeShellScriptBin "avm" ''
        set -euo pipefail

        usage() {
          echo "Usage: avm <vm> <command> [args]"
          echo ""
          echo "VMs: ${vmList}"
          echo ""
          echo "Commands:"
          echo "  start       Boot the VM in background"
          echo "  stop        Stop the VM"
          echo "  shell       SSH into the VM"
          echo "  claude [--] Run Claude Code permissionless in the VM"
          echo "  status      Show VM state"
          echo "  destroy     Stop + clean runtime files"
          echo "  log         Tail console log"
        }

        if [ $# -lt 2 ]; then
          usage
          exit 1
        fi

        VM_NAME="$1"
        COMMAND="$2"
        shift 2

        case "$VM_NAME" in
          ${vmCases}
          *)
            echo "Unknown VM: $VM_NAME"
            echo "Available: ${vmList}"
            exit 1
            ;;
        esac

        VM_DIR="''${XDG_RUNTIME_DIR:-/tmp}/avm/$VM_NAME"
        PID_FILE="$VM_DIR/vm.pid"
        SSH_KEY="${sshKeyDir}/$VM_NAME/id_ed25519"
        SSH="${sshBinary}"
        SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

        ensure_key() {
          if [ ! -f "$SSH_KEY" ]; then
            mkdir -p "$(dirname "$SSH_KEY")"
            ${sshKeygen} -t ed25519 -f "$SSH_KEY" -N "" -C "avm-$VM_NAME" >/dev/null
            echo "Generated SSH key: $SSH_KEY"
            echo "Add this to authorizedKeys in your VM config:"
            cat "''${SSH_KEY}.pub"
            exit 1
          fi
        }

        vm_running() {
          [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
        }

        wait_ssh() {
          local retries=60
          while [ $retries -gt 0 ]; do
            if nc -z localhost "$SSH_PORT" 2>/dev/null; then
              return 0
            fi
            sleep 1
            retries=$((retries - 1))
          done
          echo "SSH not available after 60s" >&2
          return 1
        }

        case "$COMMAND" in
          start)
            mkdir -p "$VM_DIR"
            "$LAUNCHER" > "$VM_DIR/launcher.log" 2>&1 &
            disown
            echo "Starting $VM_NAME (SSH port $SSH_PORT)..."
            wait_ssh
            echo "$VM_NAME running."
            ;;
          stop)
            if vm_running; then
              kill "$(cat "$PID_FILE")" 2>/dev/null || true
              [ -f "$VM_DIR/gvproxy.pid" ] && kill "$(cat "$VM_DIR/gvproxy.pid")" 2>/dev/null || true
              rm -f "$PID_FILE" "$VM_DIR/gvproxy.pid"
              echo "$VM_NAME stopped."
            else
              echo "$VM_NAME not running."
            fi
            ;;
          shell)
            if ! vm_running; then
              echo "$VM_NAME not running. Start it with: avm $VM_NAME start" >&2
              exit 1
            fi
            ensure_key
            exec $SSH -A $SSH_OPTS -i "$SSH_KEY" -p "$SSH_PORT" agent@localhost \
              -t "''${PROJECT_CD:+$PROJECT_CD &&} exec \$SHELL -l" "$@"
            ;;
          claude)
            if ! vm_running; then
              echo "$VM_NAME not running. Start it with: avm $VM_NAME start" >&2
              exit 1
            fi
            ensure_key
            exec $SSH -A -t $SSH_OPTS -i "$SSH_KEY" -p "$SSH_PORT" agent@localhost \
              "''${PROJECT_CD:+$PROJECT_CD &&} exec claude --dangerously-skip-permissions" "$@"
            ;;
          status)
            if vm_running; then
              echo "$VM_NAME: running (PID $(cat "$PID_FILE"), SSH port $SSH_PORT)"
            else
              echo "$VM_NAME: stopped"
            fi
            ;;
          destroy)
            if vm_running; then
              kill "$(cat "$PID_FILE")" 2>/dev/null || true
              [ -f "$VM_DIR/gvproxy.pid" ] && kill "$(cat "$VM_DIR/gvproxy.pid")" 2>/dev/null || true
            fi
            rm -f "$VM_DIR/store.erofs" "$VM_DIR/.store-src" "$PID_FILE" "$VM_DIR/gvproxy.pid" "$VM_DIR/console.log" "$VM_DIR/launcher.log"
            rmdir "$VM_DIR" 2>/dev/null || true
            echo "$VM_NAME destroyed."
            ;;
          log)
            tail -f "$VM_DIR/console.log" 2>/dev/null || echo "No console log found."
            ;;
          *)
            usage
            exit 1
            ;;
        esac
      '';
  };
}
