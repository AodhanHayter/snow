{ inputs, ... }:
final: prev:
let
  # Original claude-code package
  originalClaudeCode = inputs.claude-code-nix.packages.${prev.stdenv.hostPlatform.system}.default;

  # Fetch acorn JS parser for AST manipulation
  acorn = prev.fetchurl {
    url = "https://unpkg.com/acorn@8.14.0/dist/acorn.js";
    sha256 = "sha256-vsGUuauxAUfTu3flRNlc8ce0+fQtrQDfyDeRkJ6/Scc=";
  };

  # The LSP patch script (based on https://gist.github.com/Zamua/f7ca58ce5dd9ba61279ea195a01b190c)
  lspPatchScript = prev.writeText "lsp-patch.js" ''
    const fs = require('fs');
    const acorn = require(process.env.ACORN_PATH);

    const cliPath = process.argv[2];
    let code = fs.readFileSync(cliPath, 'utf-8');

    // Strip shebang for parsing
    let shebang = "";
    if (code.startsWith('#!')) {
      const idx = code.indexOf('\n');
      shebang = code.slice(0, idx + 1);
      code = code.slice(idx + 1);
    }

    // Check if already patched
    if (code.includes('let{servers:_S}=await') && code.includes('.set(_N,_I)')) {
      console.log('Already patched');
      process.exit(0);
    }

    // Parse the JavaScript
    let ast;
    try {
      ast = acorn.parse(code, { ecmaVersion: 2022, sourceType: 'module' });
    } catch (e) {
      console.error('Failed to parse cli.js:', e.message);
      process.exit(1);
    }

    // AST helpers
    const src = (node) => code.slice(node.start, node.end);

    function findNodes(node, predicate, results = []) {
      if (!node || typeof node !== 'object') return results;
      if (predicate(node)) results.push(node);
      for (const key in node) {
        if (node[key] && typeof node[key] === 'object') {
          if (Array.isArray(node[key])) {
            node[key].forEach(child => findNodes(child, predicate, results));
          } else {
            findNodes(node[key], predicate, results);
          }
        }
      }
      return results;
    }

    function containsString(node, text) {
      const strings = findNodes(node, n => n.type === 'Literal' && typeof n.value === 'string');
      return strings.some(s => s.value.includes(text));
    }

    function containsTemplate(node, text) {
      const templates = findNodes(node, n => n.type === 'TemplateLiteral');
      return templates.some(t => t.quasis.map(q => q.value.raw).join("").includes(text));
    }

    // Find functions
    const allFunctions = findNodes(ast, n =>
      n.type === 'FunctionDeclaration' || n.type === 'FunctionExpression'
    );

    // 1. Find createLspServer() - contains "restartOnCrash"
    let createServerFunc = null;
    for (const fn of allFunctions) {
      if (containsString(fn, 'restartOnCrash') || containsTemplate(fn, 'restartOnCrash')) {
        createServerFunc = fn;
        break;
      }
    }
    if (!createServerFunc) {
      console.error('Could not find createLspServer function');
      process.exit(1);
    }
    const createServerName = createServerFunc.id?.name;
    console.log('Found createLspServer:', createServerName);

    // 2. Find loadLspServersFromPlugins() - contains "Loaded" + "LSP server"
    let loadServersFunc = null;
    for (const fn of allFunctions) {
      const hasLoaded = containsString(fn, 'Loaded') || containsTemplate(fn, 'Loaded');
      const hasLsp = containsString(fn, 'LSP server') || containsTemplate(fn, 'LSP server');
      if (hasLoaded && hasLsp) {
        loadServersFunc = fn;
        break;
      }
    }
    if (!loadServersFunc) {
      console.error('Could not find loadLspServersFromPlugins function');
      process.exit(1);
    }
    const loadServersName = loadServersFunc.id?.name;
    console.log('Found loadLspServersFromPlugins:', loadServersName);

    // 3. Find LSP manager with empty initialize()
    let lspManagerFunc = null;
    let emptyInitFunc = null;
    let mapVars = [];

    for (const fn of allFunctions) {
      const varDecls = findNodes(fn, n => n.type === 'VariableDeclaration');
      const mapInits = [];

      for (const decl of varDecls) {
        for (const d of decl.declarations) {
          if (d.init?.type === 'NewExpression' && d.init.callee?.name === 'Map') {
            mapInits.push(d.id.name);
          }
        }
      }

      if (mapInits.length >= 3) {
        const asyncFuncs = findNodes(fn, n => n.type === 'FunctionDeclaration' && n.async);
        for (const inner of asyncFuncs) {
          const body = inner.body?.body;
          if (body?.length === 0 ||
              (body?.length === 1 && body[0].type === 'ReturnStatement' && !body[0].argument)) {
            lspManagerFunc = fn;
            emptyInitFunc = inner;
            mapVars = mapInits;
            break;
          }
        }
      }
      if (lspManagerFunc) break;
    }

    if (!lspManagerFunc || !emptyInitFunc) {
      console.error('Could not find LSP manager with empty initialize()');
      process.exit(1);
    }

    const initFuncName = emptyInitFunc.id?.name;
    const serverMap = mapVars[0];
    const extMap = mapVars[1];

    console.log('Found empty initialize():', initFuncName);
    console.log('Server registry map:', serverMap);
    console.log('Extension map:', extMap);

    // Build the patch
    const newInitBody = "async function " + initFuncName + "(){" +
      "let{servers:_S}=await " + loadServersName + "();" +
      "for(let[_N,_C]of Object.entries(_S)){" +
        "let _I=" + createServerName + "(_N,_C);" +
        serverMap + ".set(_N,_I);" +
        "for(let[_E,_L]of Object.entries(_C.extensionToLanguage||{})){" +
          "let _M=" + extMap + ".get(_E)||[];" +
          "_M.push(_N);" +
          extMap + ".set(_E,_M)" +
        "}" +
      "}" +
    "}";

    // Apply patch
    const newCode = shebang + code.slice(0, emptyInitFunc.start) + newInitBody + code.slice(emptyInitFunc.end);
    fs.writeFileSync(cliPath, newCode);

    // Verify
    if (fs.readFileSync(cliPath, 'utf-8').includes(newInitBody)) {
      console.log('LSP patch applied successfully!');
    } else {
      console.error('Patch verification failed');
      process.exit(1);
    }
  '';
in
{
  # Patched claude-code with LSP fix
  claude-code = prev.stdenv.mkDerivation {
    pname = "claude-code-patched";
    version = originalClaudeCode.version or "2.0.76";

    dontUnpack = true;

    nativeBuildInputs = [ prev.nodejs ];

    installPhase = ''
      # Copy the original package
      cp -r ${originalClaudeCode} $out
      chmod -R u+w $out

      # Apply LSP patch
      echo "Applying LSP initialization patch..."
      export ACORN_PATH="${acorn}"
      ${prev.nodejs}/bin/node ${lspPatchScript} $out/lib/node_modules/@anthropic-ai/claude-code/cli.js

      # Fix wrapper script to point to patched package
      echo "Fixing wrapper script paths..."
      for wrapper in $out/bin/*; do
        if [ -f "$wrapper" ]; then
          sed -i "s|${originalClaudeCode}|$out|g" "$wrapper"
        fi
      done
    '';

    meta = originalClaudeCode.meta or { };
  };
}
