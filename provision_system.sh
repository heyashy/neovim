#!/usr/bin/env bash
# provision_lazyvim_scaffold.sh
# Ubuntu-only. Installs CLI deps + latest stable Neovim. Does NOT install LazyVim itself.

set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1; }
require_sudo() { if [ "$(id -u)" -ne 0 ]; then sudo -v; fi; }
log() { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33mWARN:\033[0m %s\n" "$*"; }
die() {
  printf "\033[1;31mERR :\033[0m %s\n" "$*"
  exit 1
}

require_sudo

export DEBIAN_FRONTEND=noninteractive

log "Refresh APT and base packages"
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  ca-certificates gnupg lsb-release software-properties-common \
  build-essential pkg-config unzip tar curl wget git stow \
  ripgrep fzf fd-find \
  lua5.4 luarocks \
  ca-certificates gnupg lsb-release software-properties-common \
  cmake ninja-build gettext libtool libtool-bin autoconf automake \
  g++ libstdc++-12-dev

# Ensure fd is available as `fd` (Ubuntu names it fdfind)
if ! need_cmd fd; then
  log "Symlink fdfind -> fd"
  sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
fi

# lazygit latest release (GitHub)
install_lazygit() {
  if need_cmd lazygit; then
    log "lazygit already present: $(lazygit --version | head -n1 || true)"
    return
  fi
  log "Install lazygit latest release"
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit -D -t /usr/local/bin/
  rm -rf lazygit.tar.gz lazygit
  log "lazygit installed: $(lazygit --version | head -n1 || true)"
}
install_lazygit

# Install tree-sitter CLI (≥ 0.25.0)
if ! need_cmd tree-sitter; then
  log "Installing tree-sitter CLI"
  npm install --global tree-sitter-cli@latest
fi

# Neovim stable (PPA), fallback to AppImage if PPA fails
install_neovim() {
  if need_cmd nvim; then
    log "Neovim already present: $(nvim --version | head -n1)"
    return
  fi

  log "Install Neovim from official stable PPA"
  if sudo add-apt-repository -y ppa:neovim-ppa/stable; then
    sudo apt-get update -y
    sudo apt-get install -y neovim
  else
    warn "PPA add failed. Using AppImage fallback."
    local tmpdir appimg
    tmpdir="$(mktemp -d)"
    appimg="${tmpdir}/nvim.appimage"
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o "$appimg"
    chmod +x "$appimg"
    sudo mv "$appimg" /usr/local/bin/nvim.appimage
    # Extract AppImage to avoid FUSE dependency
    sudo /usr/local/bin/nvim.appimage --appimage-extract >/dev/null
    sudo mv squashfs-root /opt/nvim
    sudo ln -sf /opt/nvim/AppRun /usr/local/bin/nvim
    rm -rf "$tmpdir"
  fi

  log "Neovim installed: $(nvim --version | head -n1)"
}
install_neovim

# Lua tooling commonly expected by plugins via Luarocks
log "Install common Lua rocks used by tooling (safe if already present)"
sudo luarocks --lua-version=5.4 install luafilesystem || true
sudo luarocks --lua-version=5.4 install luasocket || true

# Quality-of-life shell completions for fzf if available
if [ -d /usr/share/doc/fzf/examples ]; then
  log "Optionally source fzf keybindings in your shell RC"
  warn "Add:  source /usr/share/doc/fzf/examples/key-bindings.bash"
fi

log "Create fd symlink again to be sure"
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd

log "Done. Launch nvim. Your dotfiles can handle LazyVim setup."
