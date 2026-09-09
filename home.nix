{ config, pkgs, firstmate, ... }:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
{
  home.username = "miket5";
  home.homeDirectory = "/home/miket5";
  home.stateVersion = "24.11";

  # Keep Homebrew tools available. Herdr is managed by Homebrew only (see
  # below): the previous Nix-declared build is removed because running a
  # Nix 0.8.0 server alongside the Homebrew 0.9.0 client caused a client/
  # server protocol mismatch (22 vs 19) that made agents stop the server.
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
  ];

  # Herdr is installed by Homebrew (Cellar 0.9.0). Keeping a single install
  # avoids client/server version skew, so do not re-add the Nix build here.
  # ~/.local/bin/herdr is manually symlinked to the Homebrew binary.
  home.file.".local/bin/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "/home/linuxbrew/.linuxbrew/bin/herdr";

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
