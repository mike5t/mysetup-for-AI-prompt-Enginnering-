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
- The **Pi coding agent** with its configuration, pinned version, and skills.

This is configuration, not a standalone application. Running it changes the
user's development environment; it does not create a new operating system.

## What happens when the setup runs

The main command is:

```bash
./rebuild.sh
```

That script performs four actions:

1. `git add .` stages the current repository changes. This prepares changes
   for a possible commit, but it does **not** commit or push anything.
2. Home Manager reads `flake.nix` and `home.nix`, installs the requested tools,
   and activates the configuration for the user `miket5`.
3. `scripts/install-pi.sh` installs the pinned Pi coding agent CLI into
   `~/.local/bin` (and does nothing when that exact version is already there).
4. `scripts/install-agent-tools.sh` installs the pinned agent CLIs, the
   no-mistakes gate, and the Playwright browser (also idempotent).

The configuration follows this path:

```text
flake.nix
  -> selects Nix packages, Home Manager, and the Linux system type
  -> loads home.nix
       -> installs command-line tools
       -> configures Zsh, fzf, direnv, and Home Manager
       -> links Neovim, WezTerm, Pi, and AI instruction files into the home folder

rebuild.sh
  -> runs the Home Manager switch above
  -> runs scripts/install-pi.sh to install the pinned Pi CLI
  -> runs scripts/install-agent-tools.sh for the other agent tooling
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
to be installed separately first. It also installs the pinned Pi coding agent
CLI into `~/.local/bin`; see [Pi coding agent](#pi-coding-agent) below for the
one secret that has to be restored by hand.

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
| `home/.pi/agent/settings.json` | Pi settings, default model, and pinned Pi packages. |
| `home/.pi/agent/models.json` | Pi model overrides (DeepSeek model metadata). |
| `home/.pi/agent/trust.json` | Directories Pi treats as trusted. |
| `home/.pi/agent/skills/` | Personal Pi skills stored in this repository. |
| `home/.agents/skills/` | Skills shared by Pi and other agent harnesses. |
| `scripts/install-pi.sh` | Installs the pinned Pi CLI into `~/.local/bin`. |
| `scripts/install-agent-tools.sh` | Installs the pinned agent CLIs, no-mistakes, and Playwright. |
| `scripts/fm-chromium-libs` | User-space Chromium runtime for WSL/Debian/Ubuntu. |
| `home/.no-mistakes/config.yaml` | Seed configuration for the no-mistakes gate. |
| `.gitignore` | Prevents temporary editor files and other unwanted files from being committed. |

## Software and shell configuration

The setup installs these command-line tools:

- Node.js 24 (`nodejs_24`), which provides the `npm` used to install Pi
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
recreated. Pi reads the same guidance through `~/.pi/agent/AGENTS.md`, which is
linked to `home/agents.md`.

## Pi coding agent

Pi is installed from npm at a pinned version. `rebuild.sh` calls
`scripts/install-pi.sh`, which installs
`@earendil-works/pi-coding-agent@0.83.0` into `~/.local` using the Node.js from
the Nix profile. The script is idempotent: it skips the install when the
requested version is already on `PATH`.

Configuration lives in `home/.pi/agent/` and is linked into `~/.pi/agent/`:

- `settings.json` selects DeepSeek as the default provider, pins the
  `deepseek-flash` model, and declares the `pi-image-view` package. Pi installs
  missing packages automatically on startup.
- `models.json` supplies the DeepSeek model overrides.
- `trust.json` marks `/home/miket5` as trusted.

### Skills

Pi loads skills from `~/.pi/agent/skills/` and `~/.agents/skills/` by default,
so no `skills` entry is needed in `settings.json`. Two kinds of skills are
installed:

- **Anthropic's public skills** are pinned as the `anthropics-skills` flake
  input and linked read-only to `~/.pi/agent/skills/anthropic`.
- **Personal skills** (`planning-with-files`, `no-mistakes`, `playwright-cli`)
  are stored in this repository and linked into place, so they remain editable.

Some personal skills expect external commands to be present (for example the
`no-mistakes` and `playwright-cli` CLIs). `scripts/install-agent-tools.sh`
installs them, as described in [Agent tooling](#agent-tooling-alongside-pi).

### The one manual step: the API key

The DeepSeek API key is a secret and is intentionally **not** committed. After
cloning on a new machine, restore it in one of these two ways:

1. Put the credentials file at `~/.config/pi/auth.json` (outside this
   repository). The next rebuild links it to `~/.pi/agent/auth.json`.
2. Export `DEEPSEEK_API_KEY` in your shell, or enter the key through the Pi
   login prompt on first run.

Keep the key in a password manager so it survives a machine reset.

## Agent tooling alongside Pi

`scripts/install-agent-tools.sh` (called by `rebuild.sh`) installs and pins the
tools that the skills rely on:

- npm CLIs installed into `~/.local`: `@openai/codex`, `@playwright/cli`,
  `chrome-devtools-axi`, `gh-axi`, `lavish-axi`, `quota-axi`, `tasks-axi`, and
  `hardhat`.
- The `no-mistakes` gate binary from its GitHub releases (pinned, checksum
  verified) at `~/.no-mistakes/bin/no-mistakes`, linked into `~/.local/bin`.
  `home/.no-mistakes/config.yaml` seeds its configuration on a fresh machine
  without overwriting an existing one.
- The Playwright Chromium browser, which the `playwright-cli` skill drives.
- On Debian/Ubuntu (including WSL) `scripts/fm-chromium-libs` extracts the
  shared libraries Chromium needs into `~/.local`, so no system-wide packages
  or root access are required, and writes the `chrome-devtools-axi` launchers.

Versions are pinned near the top of each script. To move to a newer release,
update the version there, run `./rebuild.sh`, and commit the change. Override
the no-mistakes version for a single run with `NO_MISTAKES_VERSION=v1.79.0
./scripts/install-agent-tools.sh`.

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
committed. Secrets should be kept outside this repository. Pi's credentials
file (`home/.pi/agent/auth.json`) is listed in `.gitignore` as an extra guard.

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
