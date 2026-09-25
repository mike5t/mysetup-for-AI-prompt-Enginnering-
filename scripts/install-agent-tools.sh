#!/usr/bin/env bash
# Install the agent tooling that is used alongside Pi.
#
# This complements scripts/install-pi.sh. It installs the pinned npm CLIs, the
# no-mistakes gate binary, the Playwright Chromium browser, and (on Debian or
# Ubuntu, including WSL) the user-space Chromium runtime managed by
# scripts/fm-chromium-libs. Every step is idempotent, so ./rebuild.sh can call
# it on every run.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Home Manager installs Node.js; prefer its npm and the ~/.local prefix that
# scripts/install-pi.sh already uses.
export NPM_CONFIG_PREFIX="${HOME}/.local"
export PATH="${HOME}/.nix-profile/bin:${NPM_CONFIG_PREFIX}/bin:${PATH}"

# Pinned to the versions this configuration was captured from. Bump them
# deliberately, and keep README.md in sync.
NPM_PACKAGES=(
	"@openai/codex@0.146.0"
	"@playwright/cli@0.1.21"
	"gh-axi@0.1.29"
	"lavish-axi@0.1.45"
	"quota-axi@0.1.17"
	"tasks-axi@0.2.4"
	"hardhat@3.4.4"
)

# On Debian/Ubuntu, scripts/fm-chromium-libs installs its own recent
# chrome-devtools-axi and owns ~/.local/bin/chrome-devtools-axi, so the npm
# copy would only collide with that launcher. Install it from npm everywhere
# else.
has_chromium_runtime() {
	command -v apt-get >/dev/null 2>&1 && command -v dpkg >/dev/null 2>&1
}
if ! has_chromium_runtime; then
	NPM_PACKAGES+=("chrome-devtools-axi@0.1.28")
fi

NO_MISTAKES_VERSION="${NO_MISTAKES_VERSION:-v1.41.2}"
NO_MISTAKES_REPO="kunchenguid/no-mistakes"
NO_MISTAKES_INSTALL_DIR="${NO_MISTAKES_INSTALL_DIR:-${HOME}/.no-mistakes/bin}"
NO_MISTAKES_BIN="${NO_MISTAKES_INSTALL_DIR}/no-mistakes"
NO_MISTAKES_LINK="${NPM_CONFIG_PREFIX}/bin/no-mistakes"
NO_MISTAKES_CONFIG="${HOME}/.no-mistakes/config.yaml"
NO_MISTAKES_CONFIG_SEED="${repo_root}/home/.no-mistakes/config.yaml"

TMP_DIR=""
cleanup() { [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"; }
trap cleanup EXIT

log() { printf 'install-agent-tools: %s\n' "$*" >&2; }
die() {
	printf 'install-agent-tools: error: %s\n' "$*" >&2
	exit 1
}

# Print the installed version of a global package, or nothing when absent.
installed_version() {
	local manifest="${NPM_CONFIG_PREFIX}/lib/node_modules/$1/package.json"
	[ -f "$manifest" ] || return 0
	jq -r '.version' "$manifest" 2>/dev/null || true
}

install_npm_packages() {
	command -v npm >/dev/null 2>&1 ||
		die "npm not found; run ./rebuild.sh first"
	local spec name want have
	for spec in "${NPM_PACKAGES[@]}"; do
		name="${spec%@*}"
		want="${spec##*@}"
		have="$(installed_version "$name")"
		if [ "$have" = "$want" ]; then
			log "${name}@${want} already installed"
			continue
		fi
		log "installing ${name}@${want}"
		npm install --global --no-audit --no-fund "$spec"
	done
}

install_no_mistakes() {
	local have="" os arch filename url
	if [ -x "$NO_MISTAKES_BIN" ]; then
		have="$("$NO_MISTAKES_BIN" --version 2>/dev/null | awk '{print $3}')" || true
	fi
	if [ "$have" != "$NO_MISTAKES_VERSION" ]; then
		os="$(uname -s | tr '[:upper:]' '[:lower:]')"
		arch="$(uname -m)"
		case "$arch" in
		x86_64 | amd64) arch="amd64" ;;
		arm64 | aarch64) arch="arm64" ;;
		*) die "unsupported architecture: $arch" ;;
		esac
		case "$os" in
		linux | darwin) ;;
		*) die "unsupported OS: $os" ;;
		esac

		filename="no-mistakes-${NO_MISTAKES_VERSION}-${os}-${arch}.tar.gz"
		url="https://github.com/${NO_MISTAKES_REPO}/releases/download/${NO_MISTAKES_VERSION}/${filename}"
		TMP_DIR="$(mktemp -d)"

		log "downloading no-mistakes ${NO_MISTAKES_VERSION} (${os}/${arch})"
		curl -fsSL "$url" -o "${TMP_DIR}/${filename}" ||
			die "download failed: $url"

		if curl -fsSL \
			"https://github.com/${NO_MISTAKES_REPO}/releases/download/${NO_MISTAKES_VERSION}/checksums.txt" \
			-o "${TMP_DIR}/checksums.txt" 2>/dev/null; then
			(cd "$TMP_DIR" && grep -F " ${filename}" checksums.txt | sha256sum --check --status) ||
				die "checksum verification failed for ${filename}"
		else
			log "warning: could not fetch checksums.txt; skipping verification"
		fi

		tar -xzf "${TMP_DIR}/${filename}" -C "$TMP_DIR"
		[ -f "${TMP_DIR}/no-mistakes" ] || die "no-mistakes binary missing from archive"
		mkdir -p "$NO_MISTAKES_INSTALL_DIR"
		install -m 0755 "${TMP_DIR}/no-mistakes" "$NO_MISTAKES_BIN"
		rm -rf "$TMP_DIR"
		TMP_DIR=""
		log "installed no-mistakes ${NO_MISTAKES_VERSION} at ${NO_MISTAKES_BIN}"
	else
		log "no-mistakes ${NO_MISTAKES_VERSION} already installed"
	fi

	mkdir -p "$(dirname "$NO_MISTAKES_LINK")"
	ln -sfn "$NO_MISTAKES_BIN" "$NO_MISTAKES_LINK"

	# Seed the gate configuration on a fresh machine without clobbering a config
	# the binary or the user has already written.
	if [ ! -f "$NO_MISTAKES_CONFIG" ] && [ -f "$NO_MISTAKES_CONFIG_SEED" ]; then
		mkdir -p "$(dirname "$NO_MISTAKES_CONFIG")"
		install -m 0644 "$NO_MISTAKES_CONFIG_SEED" "$NO_MISTAKES_CONFIG"
		log "seeded ${NO_MISTAKES_CONFIG}"
	fi
}

install_playwright_browser() {
	local cli="${NPM_CONFIG_PREFIX}/bin/playwright-cli"
	[ -x "$cli" ] || {
		log "playwright-cli not installed; skipping browser download"
		return 0
	}
	if ls "${HOME}/.cache/ms-playwright"/chromium-* >/dev/null 2>&1; then
		log "Playwright Chromium already present"
		return 0
	fi
	log "installing Playwright Chromium"
	"$cli" install-browser chromium
}

# On Debian/Ubuntu (notably WSL without passwordless sudo) the Playwright
# Chromium build needs shared libraries that are not in the base image. The
# fm-chromium-libs helper extracts them into ~/.local and wires up the
# chrome-devtools-axi launchers. It is a no-op elsewhere.
install_chromium_runtime() {
	local helper="${repo_root}/scripts/fm-chromium-libs"
	[ -f "$helper" ] || return 0
	if ! has_chromium_runtime; then
		log "apt-get/dpkg not available; skipping user-space Chromium runtime"
		return 0
	fi
	log "ensuring user-space Chromium libraries and chrome-devtools-axi launchers"
	bash "$helper" --wire
}

main() {
	install_npm_packages
	install_no_mistakes
	install_playwright_browser
	install_chromium_runtime
	log "done"
}

main "$@"
