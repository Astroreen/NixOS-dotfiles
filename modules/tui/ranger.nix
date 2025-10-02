{config, lib, pkgs, ...}:
{
    programs.ranger = {
      enable = true;
      extraConfig = ''
        set preview_images true
        set preview_images_method kittay
        set show_hidden true
        map <C-h> move left
        map <C-l> move right
        map <C-j> move down
        map <C-k> move up
        '';
    };
}
