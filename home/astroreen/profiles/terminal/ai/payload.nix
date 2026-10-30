# Payload shared by opencode and claude-code: the global prompt plus the
# agents, commands and skills both CLIs get. The custom.ai.* options are not
# per-CLI, so this lives in one file that both profiles import (the module
# system imports it once). Items limited to one CLI use
# `<kind>.definitions.<name>.targets`.
_: {
  custom.ai = {
    # Global prompt (AGENTS.md for opencode, CLAUDE.md for claude-code). The
    # module appends the caveman always-on snippet when it is enabled.
    prompt = ./CustomPrompt.md;

    # Bundled payload (home/modules/terminal/ai/<kind>/<name>.md, metadata in
    # <kind>/definitions.nix). The modules render a header per CLI and wire
    # both programs from these lists. Per-item tweaks go in
    # `<kind>.definitions.<name>` (e.g. `agent.definitions.atlas.temperature`).
    agent.local.include = [
      "atlas"
      "explore"
      "hephaestus"
      "librarian"
      "metis"
      "momus"
      "multimodal-looker"
      "oracle"
      "prometheus"
      "scribe"
      "sisyphus"
      "sisyphus-junior"
    ];

    command.local.include = [
      # "goal"
      # "handoff"
      # "hyperplan"
      # "refactor"
      # "remove-ai-slops"
      "start-work"
    ];

    skill = {
      # Bundled local skills (home/modules/terminal/ai/skills/<name>) to deploy.
      local.include = [
        "commit-message"
        "design-taste-frontend"
        "docx"
        "frontend-design"
        "spike"
        # "subagent-driven-development"
        # "systematic-debugging"
        # "test-driven-development"
        # user-invoked: its SKILL.md sets disable-model-invocation, so the model
        # never auto-loads it (pick it via /skills or @unslop); from
        # github:cursor/plugins pstack/skills/unslop
        "unslop"
        # "verify-before-done"
      ];

      # Caveman — on-demand only (alwaysOn off since 2026-10-12, experiment).
      # include trims the upstream set: keep core + local tools + native
      # workflow guards; drop the Caveman Cloud suite (setup, discover,
      # evidence-review, manage, optimize, learn) — no gateway in use.
      caveman = {
        enable = false;
        alwaysOn = false;
        include = [
          # core + local skills
          "caveman"
          "caveman-commit"
          "caveman-review"
          "caveman-compress"
          "caveman-help"
          "caveman-stats"
          "caveman-explore"
          "cavecrew"
          # native workflow guards (classified, auto-applied by task type)
          "native"
          "investigate-first"
          "lean-build"
          "migration"
          "safe-refactor"
          "surgical-patch"
          "verify-and-stop"
          # infra referenced by the skills above
          "compile.mjs"
          "verbs-gate.mjs"
          "engine-mcp-tools.json"
          "registry.json"
        ];
      };

      # Matt Pocock skills — fetched from the mattpocock-skills flake input.
      # To adopt a new upstream skill: `nix flake update mattpocock-skills`,
      # then add its name here.
      matt-pocock = {
        enable = true;
        include = [
          # engineering
          "tdd"
          "diagnosing-bugs"
          "code-review"
          "pr"
          "retro"
          "codebase-design"
          # productivity
          "grilling"
          "grill-me"
          "handoff"
          "writing-for-agents"
          "wait-what"
        ];
      };
    };
  };
}
