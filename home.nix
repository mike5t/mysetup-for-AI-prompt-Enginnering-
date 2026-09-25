{ config, pkgs, lib, firstmate, anthropicsSkills, ... }:
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
    # Node.js provides npm so scripts/install-pi.sh can install the pinned Pi
    # coding agent CLI into ~/.local/bin without relying on a separate nvm.
    nodejs_24
  ];

  # Herdr is installed by Homebrew (Cellar 0.9.0). Keeping a single install
  # avoids client/server version skew, so do not re-add the Nix build here.
  # ~/.local/bin/herdr is manually symlinked to the Homebrew binary.
  home.file.".local/bin/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "/home/linuxbrew/.linuxbrew/bin/herdr";

  # User-space Chromium runtime helper (WSL/Debian/Ubuntu). scripts/
  # install-agent-tools.sh runs it to provide the shared libraries that the
  # Playwright Chromium build needs without system-wide packages.
  home.file.".local/bin/fm-chromium-libs".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/scripts/fm-chromium-libs";

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

  # Pi coding agent configuration. These files stay editable in place because
  # they point back at this repository. The API key is a secret and is never
  # committed: if ~/.config/pi/auth.json exists it is linked into place, and
  # otherwise Pi falls back to the DEEPSEEK_API_KEY environment variable.
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/trust.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/trust.json";
  home.file.".pi/agent/auth.json" = lib.mkIf
    (builtins.pathExists "${config.home.homeDirectory}/.config/pi/auth.json")
    {
      source = config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/.config/pi/auth.json";
    };

  # Pi skills. Anthropic's public skills come from the pinned flake input and
  # are read-only; personal skills live in this repository and stay editable.
  home.file.".pi/agent/skills/anthropic".source = anthropicsSkills;
  home.file.".pi/agent/skills/planning-with-files".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/skills/planning-with-files";
  home.file.".agents/skills/no-mistakes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills/no-mistakes";
  home.file.".agents/skills/playwright-cli".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills/playwright-cli";

  programs.home-manager.enable = true;
}
