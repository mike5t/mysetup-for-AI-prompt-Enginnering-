#!/usr/bin/env bash
# Install the pinned Pi coding agent CLI into ~/.local.
#
# Invoked by rebuild.sh after the Home Manager switch so that a fresh machine
# gets the same Pi version that the rest of this configuration expects.
set -euo pipefail

# Keep this in sync with the version documented in README.md.
PI_VERSION="0.83.0"

export NPM_CONFIG_PREFIX="${HOME}/.local"
export PATH="${HOME}/.nix-profile/bin:${HOME}/.local/bin:${PATH}"

# Check the Home Manager-managed location explicitly so a separate nvm install
# cannot mask a missing or outdated ~/.local/bin/pi.
pi_bin="${HOME}/.local/bin/pi"
if [ -x "${pi_bin}" ] &&
	[ "$("${pi_bin}" --version 2>/dev/null || true)" = "${PI_VERSION}" ]; then
	echo "pi ${PI_VERSION} is already installed at ${pi_bin}"
	exit 0
fi

npm_bin="$(command -v npm || true)"
if [ -z "${npm_bin}" ]; then
	echo "error: npm not found. Run ./rebuild.sh first so Nix provides Node.js." >&2
	exit 1
fi

echo "Installing @earendil-works/pi-coding-agent@${PI_VERSION} into ${NPM_CONFIG_PREFIX} ..."
"${npm_bin}" install --global "@earendil-works/pi-coding-agent@${PI_VERSION}"

hash -r 2>/dev/null || true
echo "Installed pi $(pi --version) at $(command -v pi)"
