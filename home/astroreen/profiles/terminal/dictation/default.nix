_: {
  imports = [ ../../../../modules/terminal/dictation ];

  # Vocabulary for Russian dictation with English terms mixed in, taken from
  # what astroreen actually writes in T3 Code. Without it Whisper spelled
  # "T3 Code" as "TifreCode", Hercules as "Пиркулес", threads as "дреды" and
  # PR as "пиар". The prompt is written the way astroreen types: Russian with
  # English names and terms in Latin script, and Whisper copies that.
  # Prompt + hotwords: ~195 of the ~220 tokens Whisper accepts.
  custom.dictation.server = {
    prompt = builtins.concatStringsSep " " [
      "Ты оркестратор: создай новый трэд в T3 Code, проверь PR и issues, смерджи в main, когда CI и e2e тесты зелёные."
      "Задеплой на Hercules и aktkc через tailnet, поправь NixOS и Hyprland в devenv."
      "В AstroTime подключи Nextcloud через CalDAV и собери APK."
      "В Caspian Logistics ERP синхронизируй Infinity, WhatsApp и Telegram."
    ];

    hotwords = [
      "T3 Code"
      "Hercules"
      "aktkc"
      "AstroTime"
      "Caspian Logistics ERP"
      "Infinity"
      "NixOS"
      "Hyprland"
      "devenv"
      "Tailscale"
      "tailnet"
      "Nextcloud"
      "CalDAV"
      "WebDAV"
      "worktree"
      "PR"
      "issues"
      "MCP"
      "Claude Code"
      "OpenCode"
      "whatsmeow"
    ];
  };
}
