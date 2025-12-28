# Default Claude Code plugin marketplace definitions
{ lib, ... }:

{
  defaults = {
    # Official Anthropic plugins marketplace
    "claude-plugins-official" = {
      source = {
        type = "github";
        url = "anthropics/claude-plugins-official";
      };
    };

    # Official Anthropic skills
    "anthropic-agent-skills" = {
      source = {
        type = "github";
        url = "anthropics/skills";
      };
    };
  };
}
