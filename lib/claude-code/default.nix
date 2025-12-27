# Claude Code configuration functions
{ lib, ... }:

let
  inherit (lib) concatStringsSep elem filter flatten hasSuffix
    listToAttrs removeSuffix splitString trim foldl';

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

      frontmatter = foldl' (a: b: a // b) {} (map parseLine frontmatterLines);
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

  # Generate skill files for ~/.claude/skills/
  mkSkillFiles = skills:
    listToAttrs (map (skill: {
      name = ".claude/skills/${skill.name}/SKILL.md";
      value.text = mkSkillMd skill;
    }) skills);

in
{
  "claude-code" = {
    inherit parseSkillMd mkSkillMd loadPluginSkills mkSkillFiles;
  };
}
