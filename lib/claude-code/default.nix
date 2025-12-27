# Claude Code configuration functions (skills, LSP)
{ lib, ... }:

let
  inherit (lib) concatStringsSep elem filter flatten hasSuffix
    listToAttrs optionalAttrs removeSuffix splitString trim;

  # ============================================================================
  # Skills
  # ============================================================================

  # Parse simple YAML frontmatter from markdown content
  parseSkillMd = content:
    let
      lines = splitString "\n" content;
      firstLine = if lines != [] then builtins.head lines else "";
      hasFrontmatter = firstLine == "---";

      findClosing = idx: ls:
        if idx >= builtins.length ls then null
        else if idx > 0 && (builtins.elemAt ls idx) == "---" then idx
        else findClosing (idx + 1) ls;

      closingIdx = if hasFrontmatter then findClosing 1 lines else null;

      frontmatterLines =
        if closingIdx != null
        then lib.sublist 1 (closingIdx - 1) lines
        else [];

      contentLines =
        if closingIdx != null
        then lib.sublist (closingIdx + 1) (builtins.length lines - closingIdx - 1) lines
        else lines;

      parseLine = line:
        let
          match = builtins.match "([^:]+):(.*)" line;
          hasColon = match != null;
          key = if hasColon then trim (builtins.elemAt match 0) else null;
          value = if hasColon then trim (builtins.elemAt match 1) else null;
        in
        if hasColon && key != "" then { ${key} = value; } else {};

      frontmatter = lib.foldl' (a: b: a // b) {} (map parseLine frontmatterLines);
    in
    { inherit frontmatter; content = concatStringsSep "\n" contentLines; };

  # Generate SKILL.md with proper YAML frontmatter
  mkSkillMd = { name, description, content, allowedTools ? null, model ? null }:
    let
      frontmatter = concatStringsSep "\n" (
        [ "---" "name: ${name}" "description: ${description}" ]
        ++ lib.optional (allowedTools != null) "allowed-tools: ${allowedTools}"
        ++ lib.optional (model != null) "model: ${model}"
        ++ [ "---" "" ]
      );
    in
    frontmatter + content;

  # Load skills from external plugin repo
  loadPluginSkills = { src, plugins ? null, blacklist ? [] }:
    let
      pluginsPath = "${src}/plugins";
      hasPlugins = builtins.pathExists pluginsPath;

      pluginDirs =
        if !hasPlugins then []
        else if plugins != null then plugins
        else builtins.attrNames (builtins.readDir pluginsPath);

      loadPlugin = pluginName:
        let
          skillsPath = "${pluginsPath}/${pluginName}/skills";
          hasSkills = builtins.pathExists skillsPath;
          skillFiles = if hasSkills then builtins.readDir skillsPath else {};

          loadSkill = filename:
            let
              skillPath = "${skillsPath}/${filename}";
              rawContent = builtins.readFile skillPath;
              parsed = parseSkillMd rawContent;
              baseName = removeSuffix ".md" filename;
              skillName = parsed.frontmatter.name or baseName;
            in
            {
              name = skillName;
              description = parsed.frontmatter.description or "Skill from ${pluginName}";
              content = parsed.content;
              allowedTools = parsed.frontmatter.allowed-tools or null;
              model = parsed.frontmatter.model or null;
            };

          mdFiles = filter (n: hasSuffix ".md" n) (builtins.attrNames skillFiles);
          skills = map loadSkill mdFiles;
        in
        filter (s: !(elem s.name blacklist)) skills;
    in
    flatten (map loadPlugin pluginDirs);

  # Convert skill attrsets to home.file entries
  mkSkillFiles = skills:
    listToAttrs (map (skill: {
      name = ".claude/skills/${skill.name}/SKILL.md";
      value = {
        text = mkSkillMd skill;
      };
    }) skills);

  # ============================================================================
  # LSP
  # ============================================================================

  # Generate .lsp.json content from LSP server config
  mkLspJson = lspConfig:
    let
      serverConfig = {
        command = lspConfig.command;
        args = lspConfig.args;
        extensionToLanguage = lspConfig.extensionToLanguage;
      } // optionalAttrs (lspConfig.transport != "stdio") {
        transport = lspConfig.transport;
      } // optionalAttrs (lspConfig.initializationOptions != {}) {
        initializationOptions = lspConfig.initializationOptions;
      } // optionalAttrs (lspConfig.settings != {}) {
        settings = lspConfig.settings;
      } // optionalAttrs (lspConfig.env != null) {
        env = lspConfig.env;
      } // optionalAttrs (lspConfig.startupTimeout != null) {
        startupTimeout = lspConfig.startupTimeout;
      } // optionalAttrs (lspConfig.restartOnCrash != null) {
        restartOnCrash = lspConfig.restartOnCrash;
      } // optionalAttrs (lspConfig.maxRestarts != 3) {
        maxRestarts = lspConfig.maxRestarts;
      };
    in
    builtins.toJSON { ${lspConfig.languageId} = serverConfig; };

  # Generate plugin.json metadata
  mkPluginJson = { name, description, ... }:
    builtins.toJSON {
      inherit name description;
      version = "0.1.0";
    };

  # Convert LSP configs to home.file entries
  mkLspFiles = lspConfigs:
    let
      mkPluginFiles = lsp: [
        {
          name = ".claude/plugins/${lsp.name}/plugin.json";
          value.text = mkPluginJson lsp;
        }
        {
          name = ".claude/plugins/${lsp.name}/.lsp.json";
          value.text = mkLspJson lsp;
        }
      ];
    in
    listToAttrs (flatten (map mkPluginFiles lspConfigs));

in
{
  "claude-code" = {
    skills = {
      inherit parseSkillMd mkSkillMd loadPluginSkills mkSkillFiles;
    };
    lsp = {
      inherit mkLspJson mkPluginJson mkLspFiles;
    };
  };
}
