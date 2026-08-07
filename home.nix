{ config, pkgs, herdr, firstmate, ... }:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  herdrPackage = herdr.packages.${pkgs.system}.default;
in
{
  home.username = "miket5";
  home.homeDirectory = "/home/miket5";
  home.stateVersion = "24.11";

  # Keep Homebrew tools available; Herdr itself is declared below from its
  # upstream flake and is shadowed into ~/.local/bin ahead of Homebrew.
  home.sessionPath = [
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
  ];

  home.packages = with pkgs; [
    neovim
    git
    ripgrep
    starship
    wezterm
    fd
    jq
    bat
    eza
    gh
    shellcheck
    shfmt
    tree
    herdrPackage
  ];

  # Herdr is also installed by Homebrew on this machine. This link makes the
  # Nix-declared build take precedence without removing the Homebrew formula.
  home.file.".local/bin/herdr".source = "${herdrPackage}/bin/herdr";

  # Firstmate is a repository/distro, not a standalone executable. Keep a
  # pinned, reproducible source snapshot in the Home Manager profile while
  # leaving the live ~/github/firstmate checkout untouched.
  home.file.".local/share/firstmate-source".source = firstmate;

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
  home.file.".pi/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/agents.md";

  programs.home-manager.enable = true;
}
