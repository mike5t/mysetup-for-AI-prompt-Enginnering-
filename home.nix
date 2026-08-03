{ config, pkgs, ... }:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  home.username = "miket5";
  home.homeDirectory = "/home/miket5";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    neovim
    git
    ripgrep
    starship
    wezterm
    zellij
    fd
    jq
    bat
    eza
    gh
    shellcheck
    shfmt
    tree
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      v = "nvim";
      ls = "ls --color=auto";
    };
    initContent = ''
      eval "$(starship init zsh)"
      bindkey '^f' autosuggest-accept
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Edit-in-place symlinks for configuration.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";

  # Global agent memory files.
  home.file.".claude.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".cursorrules".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";

  programs.home-manager.enable = true;
}
