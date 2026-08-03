# My Setup for AI Prompt Engineering

This repository contains the personal configuration for a Linux development
computer. It is sometimes called a **dotfiles repository** because it stores
configuration files that normally live in hidden directories such as
`~/.config`.

The goal is to make a development environment easier to understand, repeat,
back up, and use on another Linux computer. The setup uses:

- **Nix** to obtain software in a repeatable way.
- **Home Manager** to configure software in the user's home directory.
- **Git** to keep a history of the configuration.
- **Neovim, WezTerm, Zsh, and terminal tools** for day-to-day development.
- Shared instruction files for AI coding assistants.

This is configuration, not a standalone application. Running it changes the
user's development environment; it does not create a new operating system.

## What happens when the setup runs

The main command is:

```bash
./rebuild.sh
```

That script performs two actions:

1. `git add .` stages the current repository changes. This prepares changes
   for a possible commit, but it does **not** commit or push anything.
2. Home Manager reads `flake.nix` and `home.nix`, installs the requested tools,
   and activates the configuration for the user `miket5`.

The configuration follows this path:

```text
flake.nix
  -> selects Nix packages, Home Manager, and the Linux system type
  -> loads home.nix
       -> installs command-line tools
       -> configures Zsh, fzf, direnv, and Home Manager
       -> links Neovim, WezTerm, and AI instruction files into the home folder
```

Home Manager creates a new user-environment generation when it switches. If a
change causes a problem, Home Manager can be used to switch back to an older
generation.

## Quick start

The configuration expects this repository to be located at `~/.dotfiles`.
That location matters because `home.nix` creates links using that path.

For a new machine:

```bash
git clone https://github.com/mike5t/mysetup-for-AI-prompt-Enginnering-.git ~/.dotfiles
cd ~/.dotfiles
./rebuild.sh
```

The repository is private, so GitHub access must be configured before the
`git clone` command can work. Nix must also be installed, with flakes enabled.
The script downloads Home Manager through Nix, so Home Manager does not need
to be installed separately first.

If the repository is stored somewhere other than `~/.dotfiles`, update the
`dotfiles` path near the top of `home.nix` before running the rebuild.

## Important files

| File or directory | Purpose |
| --- | --- |
| `flake.nix` | Describes the Nix inputs and selects the `miket5` Home Manager profile. |
| `flake.lock` | Records exact versions of the Nix inputs used by the setup. |
| `home.nix` | Defines installed packages, shell settings, and links into the home directory. |
| `rebuild.sh` | Stages repository changes and activates the Home Manager configuration. |
| `home/.config/nvim` | Neovim settings and plugin definitions. |
| `home/.config/wezterm` | Reserved directory for WezTerm configuration. |
| `home/AGENTS.md` | Shared instructions for AI coding assistants. |
| `home/agents.md` | Additional copy of the agent guidance document. |
| `.gitignore` | Prevents temporary editor files and other unwanted files from being committed. |

## Software and shell configuration

The setup installs these command-line tools:

- Neovim and Git
- ripgrep, fd, jq, bat, eza, and tree for searching and inspecting files
- Starship for the shell prompt
- WezTerm and Zellij for terminal workspaces
- GitHub CLI (`gh`)
- ShellCheck and shfmt for checking and formatting shell scripts

It also configures Zsh with command completion, autosuggestions, and syntax
highlighting. fzf is integrated with Zsh for interactive searching, and
direnv with nix-direnv can load project-specific environment settings.

The aliases currently defined are:

```text
v  -> nvim
ls -> ls --color=auto
```

## Neovim configuration

The Neovim configuration uses `lazy.nvim` to install and manage plugins. The
first Neovim launch may download plugins from GitHub.

The leader key is Space. Some useful mappings are:

| Mapping | Action |
| --- | --- |
| `Space f` | Find files |
| `Space s` | Search text |
| `Space b` | List open buffers |
| `Space e` | Open the file explorer |
| `Space g` | Open Neogit |
| `g d` | Go to a definition when language-server support is available |
| `Ctrl+A` | Select the entire file in normal mode |
| `Esc` | Save while leaving insert mode, or save in normal mode |

Neovim also uses relative line numbers, two-space indentation, the system
clipboard, persistent undo, and extra scrolling space around the cursor.

## AI assistant instructions

`home/AGENTS.md` contains general instructions intended to be shared by AI
coding tools. Home Manager links it into the home directory as:

```text
~/.claude.md      -> ~/.dotfiles/home/AGENTS.md
~/.cursorrules   -> ~/.dotfiles/home/AGENTS.md
```

This means an AI assistant can use the same guidance regardless of which
supported editor or tool is being used. Editing `home/AGENTS.md` changes the
source file in the repository; run the rebuild if the link itself needs to be
recreated.

## Why symbolic links are used

The Neovim, WezTerm, and AI instruction files are linked back to this Git
repository instead of being copied. This has two benefits:

1. The active configuration is easy to find and edit.
2. Changes can be reviewed, committed, and pushed with Git.

Because the links point to the checkout, the checkout must remain at the path
expected by `home.nix`. Moving the repository without updating that path can
leave broken links.

## Customizing the setup

The current configuration is written for one computer and user. To use it for
another account, review these values:

```nix
homeConfigurations."miket5"
home.username = "miket5";
home.homeDirectory = "/home/miket5";
system = "x86_64-linux";
```

Change the username, home directory, and Home Manager profile name as needed.
Change the system value for a different CPU or operating system supported by
the selected Nix packages.

To add a package, add its Nix package name to `home.packages` in `home.nix`.
To change a shell alias, edit `programs.zsh.shellAliases`. To change Neovim,
edit the Lua files under `home/.config/nvim`.

## Updating safely

After changing the configuration:

```bash
cd ~/.dotfiles
git diff
./rebuild.sh
```

If the rebuild succeeds, inspect what was staged before committing:

```bash
git diff --cached
git status
git commit -m "Describe the configuration change"
git push
```

Remember that `rebuild.sh` stages all non-ignored changes. Review the staged
diff so that passwords, API keys, tokens, or other private information are not
committed. Secrets should be kept outside this repository.

## Troubleshooting

### `nix: command not found`

Install Nix first and open a new shell so that the `nix` command is available.

### Flakes are disabled

Enable the Nix command and flakes features in the Nix configuration, or run
the command using the appropriate `--extra-experimental-features` option for
the local Nix installation.

### Configuration links point to missing files

Confirm that the repository is at `~/.dotfiles`, or update the `dotfiles`
variable in `home.nix` to match the actual checkout path.

### A file already exists in the home directory

Home Manager may stop rather than overwrite an existing configuration file.
Back up the existing file, then run `./rebuild.sh` again. Do not delete a file
until its contents have been checked and backed up.

## Summary

This repository is a version-controlled recipe for a Linux development
environment. `flake.nix` chooses the Nix and Home Manager inputs, `home.nix`
describes the desired tools and settings, and `rebuild.sh` applies them. Git
then provides a history of the setup so it can be understood, restored, and
shared without manually repeating every configuration step.
