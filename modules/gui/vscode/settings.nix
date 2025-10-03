{
  # Font settings
  "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono', 'bold', bold";
  "editor.fontSize" = 15;

  # Themes
  "workbench.colorTheme" = "Gruvbox Dark Medium";
  "workbench.iconTheme" = "material-icon-theme";
  "material-icon-theme.hidesExplorerArrows" = true;
  "workbench.tree.indent" = 14;

  # Confirm pop up on drag and drop
  "explorer.confirmDragAndDrop" = false;
  "explorer.confirmDelete" = true;

  # Disable the bar at the bottom
  "workbench.sideBar.location" = "right";
  "workbench.statusBar.visible" = false;

  # Disable the code map on the right
  "editor.scrollbar.horizontal" = "hidden";
  "editor.scrollbar.vertical" = "visible";
  "editor.minimap.enabled" = false;
  "editor.matchBrackets" = "always";
  "editor.occurrencesHighlight" = "off";
  "editor.overviewRulerBorder" = false;
  "editor.hideCursorInOverviewRuler" = true;
  "editor.stickyScroll.enabled" = false;

  # Hide panel on the right with git; run; debug; plugins; etc.
  "workbench.activityBar.location" = "top";

  # Disable panel that manipulates window
  "chat.commandCenter.enabled" = false;
  "workbench.layoutControl.enabled" = false;
  "window.titleBarStyle" = "native";
  "window.menuBarVisibility" = "toggle";
  "explorer.decorations.badges" = false;
  "git.decorations.enabled" = false;
  "scm.diffDecorations" = "none";

  # Always use the tabs; that you pasted yourself
  "editor.detectIndentation" = false;

  # Not show all opened bookmarks
  "workbench.editor.showTabs" = "single";

  # Cursor settings
  "editor.multiCursorModifier" = "ctrlCmd";
  "editor.cursorBlinking" = "solid";

  # Add one empty line in the end of the file to avoid mistake
  "files.insertFinalNewline" = true;

  # Tips for new users
  "workbench.tips.enabled" = false;

  # Autosave
  "files.autoSave" = "afterDelay";
  "workbench.colorCustomizations" = { };

  # Git settings
  "git.autofetch" = true;
  "github.copilot.nextEditSuggestions.enabled" = true;
  "git.confirmSync" = false;

  # Startup settings
  "workbench.startupEditor" = "welcomePage";

  # Terminal settings
  "terminal.integrated.defaultProfile.linux" = "zsh";

  ##############
  # Extensions #
  ##############

  # Formatters
  "editor.defaultFormatter" = "esbenp.prettier-vscode";
  "editor.formatOnSave" = true;
  "editor.formatOnPaste" = true;
  "notebook.defaultFormatter" = "esbenp.prettier-vscode";
  "nix.formatterPath" = "nixfmt";
  "[nix]" = {
    "editor.defaultFormatter" = "jnoortheen.nix-ide";
    "editor.tabSize" = 2;
  };
  "editor.tabSize" = 4;
  "prettier.tabWidth" = 4;

  # Disable telemetry
  "telemetry.telemetryLevel" = "off";
  "redhat.telemetry.enabled" = false;
  "sonarlint.disableTelemetry" = true;
}
