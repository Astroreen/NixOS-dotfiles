{ pkgs, ... }: {
  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
    ibm-plex

    # Microsoft document fonts (Times New Roman, Arial, Courier New, Georgia,
    # Verdana, Tahoma, Trebuchet MS, Comic Sans, Impact, Andale Mono, Webdings)
    corefonts
    # Windows Vista ClearType fonts (Calibri, Cambria, Candara, Consolas,
    # Constantia, Corbel)
    vista-fonts
  ];
}
