# home/modules/tui/ai — AI Tools

HM modules configuring all AI tooling: opencode, meridian proxy, MCPs, skills, fabric.

## STRUCTURE

```
ai/
├── default.nix      # custom.ai options root — configDir setting (default: .config/opencode)
├── mcps.nix         # MCP server definitions — ALL disabled by default (lib.mkDefault true)
├── meridian.nix     # custom.ai.meridian — Claude Pro/Max local proxy, systemd user service
├── skills/          # custom.ai.skill.{learn,caveman} — copies skills to configDir at activation
├── opencode/        # programs.opencode config + activations (AGENTS.md, agents/, commands/)
├── fabric/          # fabric-ai CLI tool
├── claude/          # DORMANT — not imported, do not use
├── agents/          # Opencode agent definitions → copied to ~/.config/opencode/agents/
└── commands/        # Opencode slash commands → copied to ~/.config/opencode/commands/
```

## WHERE TO LOOK

| Task | File |
|------|------|
| Add MCP server | `mcps.nix` — add entry to `servers` attrset |
| Enable MCP per-host | host config — `programs.mcp.servers.<name>.disabled = false` |
| Add opencode plugin | `opencode/default.nix` — `programs.opencode.settings.plugin` list |
| Change opencode theme | `opencode/default.nix` — `programs.opencode.tui.theme` |
| Add skill option | `skills/default.nix` — new `custom.ai.skill.*` option |
| Add agent definition | `agents/` — `.md` file, deployed to opencode at activation |
| Add slash command | `commands/` — `.md` file, deployed to opencode at activation |
| Meridian port/host | `meridian.nix` — `custom.ai.meridian.settings.{port,host}` (defaults: 127.0.0.1:3456) |
| Change configDir | `default.nix` — `custom.ai.settings.configDir` |

## KEY PATTERNS

- All opencode config files deployed via `home.activation` copy (chmod 777) — NOT `home.file` symlinks. Files must stay mutable for runtime edits by opencode/caelestia.
- Meridian installed via `npm install` in activation script (not a Nix package). nix-ld provides native binary support for libsql.
- `caveman.alwaysOn = true` appends caveman-always-on snippet to the deployed AGENTS.md (runs after `copyOpencodeAgentsDoc`).
- Skills sourced from Nix store paths (learn/) or flake inputs (caveman from `inputs.caveman`) → copied to `$configDir/skills/`.

## ANTI-PATTERNS

- NEVER symlink opencode config files — breaks runtime mutability
- NEVER set `disabled = false` in `mcps.nix` — all MCPs opt-in per-host
- NEVER import `claude/` — dormant, incomplete
- NEVER add opencode settings to `meridian.nix` — keep proxy concerns isolated
