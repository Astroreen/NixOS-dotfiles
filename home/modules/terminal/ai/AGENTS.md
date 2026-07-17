# AGENTS.md — home/modules/terminal/ai/

Reusable Home Manager module (not a per-host profile) providing MCP servers, the Meridian
Claude-proxy, and the opencode skill-deployment mechanism. Imported once from
`home/astroreen/common/imports.nix` (as `../profiles/terminal/ai/{fabric,opencode,claude}`) plus
directly wired via `custom.ai.*` options declared here.

---

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Entry point. Imports `mcps.nix`, `skills/`, `meridian.nix`. Declares `custom.ai.settings.configDir` (default `.config/opencode`) — the base dir all skill/agent files get copied into. |
| `mcps.nix` | Declares `programs.mcp.servers` — 10 servers (context7, playwright, youtube-transcript, persistent-memory, sequential-thinking, magic-ui-components, token-optimizer, cloudflare-docs, excel, drawio). All wrapped `disabled = lib.mkDefault true` — opt-in per host via `programs.mcp.servers.<name>.disabled = false`. |
| `meridian.nix` | `custom.ai.meridian.{enable,enableOpencodeIntegration,settings}`. When enabled: installs Meridian via `npm install` activation script (not a Nix package — nix-ld supplies libsql), runs it as `systemd.user.services.meridian` (default port 3456), and optionally wires an opencode plugin + routes `provider.anthropic` through the local proxy. |
| `skills/default.nix` | `custom.ai.skill.{learn,caveman}.enable` (+ `caveman.alwaysOn`). Copies skill directories into `${configDir}/skills/<name>` via `home.activation` (`chmod 777` then dirs back to `755` — **not symlinked**, files must stay mutable). `caveman.alwaysOn` appends a snippet to the user's opencode `AGENTS.md` after opencode's own copy activation (`copyOpencodeAgentsDoc`). |
| `skills/learn/SKILL.md` | The `learn` skill payload, copied verbatim by `copyLearnSkills`. |
| `commands/example.md` | Example slash-command doc (not currently wired to an activation script in this dir — command deployment for real commands is not yet implemented here). |
| `lmstudio.nix` | `home.packages = [ pkgs.lmstudio ]`. **Not imported by `default.nix`** — wired directly by `home/astroreen/server/home.nix` (`../../modules/terminal/ai/lmstudio.nix`), so it's server-only, not part of this module's own default import chain. |

---

## Conventions specific to this module

- Options live under `custom.ai.*` (`custom.ai.settings`, `custom.ai.meridian.*`, `custom.ai.skill.*`) — no `let cfg = config.custom.<x>;` alias in `default.nix` itself, but `meridian.nix` and `skills/default.nix` both do `cfg = config.custom.ai.<sub>;` at the top.
- Skill/agent payloads are copied at activation time, **not symlinked**, because opencode/caveman mutate them at runtime (feedback data, learned state). Any new skill dir needs its own `home.activation.copyXSkills` entry following the `copyDir` helper pattern in `skills/default.nix`.
- Activation ordering matters: `cavemanAlwaysOnSnippet` explicitly runs `entryAfter [ "copyOpencodeAgentsDoc" ]` (an activation script defined by opencode's own HM module, not this one) so it appends to the file opencode just wrote, not a stale copy.
- Real MCP credentials/URLs are hardcoded in `mcps.nix` (context7, cloudflare-docs use public HTTP endpoints; others spawn `npx`/`docker`/`uvx` on demand) — no secrets file needed for the default set.

## Anti-patterns (this module)

- Don't symlink skill/agent/command files into `configDir` — breaks runtime mutation (learn skill's feedback log, caveman state).
- Don't enable an MCP server by editing `mcps.nix`'s `disabled` default — override per-host instead (`programs.mcp.servers.<name>.disabled = false` in the host's `home.nix`), keeping this module's defaults host-agnostic.
- Don't assume `lmstudio.nix` is active — it's present in this dir but not in `default.nix`'s `imports`.
