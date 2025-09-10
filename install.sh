#!/usr/bin/env bash


set -Eeuo pipefail
umask 022

############################
# ====== VARIABLES ======  #
############################

# ---- repo to clone (expects a ./config directory inside) ----
REPO_URL="${https://github.com/SATUNIX/dotfiles/new/aurora}"         
REPO_BRANCH="${REPO_BRANCH:aurora}"        
REPO_DIR_NAME="${REPO_DIR_NAME:-aurora-config}"

# ---- packages (official repos via pacman) ----
PACMAN_PKGS_DEFAULT=(
  # core / desktop
  hyprland hyprpaper hyprshot waybar
  xdg-desktop-portal-hyprland
  # lock + extras
  gtklock gtklock-powerbar-module swayidle
  # terminal + utils
  foot grim slurp wl-clipboard libnotify jq light fish sddm
  # fonts
  ttf-jetbrains-mono
)

# ---- packages (AUR via paru) ----
AUR_PKGS_DEFAULT=(
  # nerd-fonts-jetbrains-mono   # uncomment if you want Nerd Font from AUR
  # theme.sh                    # uncomment if you rely on Aurora's theme.sh
)

# ---- behavior toggles ----
DO_FULL_UPGRADE="${DO_FULL_UPGRADE:-true}"   # pacman -Syu before installs
INSTALL_AUR="${INSTALL_AUR:-true}"           # install AUR_PKGS_DEFAULT with paru
DEPLOY_CONFIG="${DEPLOY_CONFIG:-true}"       # clone repo & copy ./config → ~/.config

# ---- locations ----
WORKDIR="${WORKDIR:-$HOME/.local/src}"
PARU_AUR_URL="https://aur.archlinux.org/paru.git"

# ---- backup naming ----
BACKUP_TS="$(date -u +'%Y-%m-%dT%H-%M-%SZ')"
CONFIG_BACKUP="$HOME/.${BACKUP_TS}.config.bak"

# ---- misc ----
PACMAN_FLAGS="${PACMAN_FLAGS:---needed --noconfirm}"
PARU_FLAGS="${PARU_FLAGS:---needed --noconfirm}"

############################
# ====== FUNCTIONS ======  #
############################

log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
err() { printf '\033[1;31mEE\033[0m %s\n' "$*" >&2; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || return 1; }

require_arch() {
  if ! need_cmd pacman; then
    err "This script expects an Arch-based system (pacman not found)."
    exit 1
  fi
}

require_sudo() {
  if ! need_cmd sudo; then
    err "sudo not found. Please install and configure sudo first."
    exit 1
  fi
}

no_root() {
  if [ "$EUID" -eq 0 ]; then
    err "Do NOT run this as root. Use a regular user with sudo privileges."
    exit 1
  fi
}

ensure_dir() { mkdir -p "$1"; }

pacman_install() {
  local pkgs=("$@")
  if [ "${#pkgs[@]}" -gt 0 ]; then
    log "Installing (pacman): ${pkgs[*]}"
    sudo pacman -S ${PACMAN_FLAGS} "${pkgs[@]}"
  fi
}

paru_install() {
  local pkgs=("$@")
  if [ "${#pkgs[@]}" -gt 0 ]; then
    log "Installing (paru/AUR): ${pkgs[*]}"
    paru -S ${PARU_FLAGS} "${pkgs[@]}"
  fi
}

install_paru_if_needed() {
  if need_cmd paru; then
    log "paru already installed."
    return 0
  fi
  log "Installing paru (AUR helper)…"
  sudo pacman -S ${PACMAN_FLAGS} base-devel git rust
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  git clone --depth=1 "$PARU_AUR_URL" "$tmp/paru"
  pushd "$tmp/paru" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf "$tmp"
  trap - EXIT
  log "paru installed."
}

clone_repo() {
  local url="$1" branch="$2" dir="$3"
  if [ -z "$url" ] || [ "$url" = "__FILL_ME__" ]; then
    warn "REPO_URL is not set; skipping config deployment."
    return 2
  fi
  ensure_dir "$WORKDIR"
  local target="$WORKDIR/$dir"
  if [ -d "$target/.git" ]; then
    log "Repo exists at $target; pulling latest from $branch…"
    git -C "$target" fetch --depth=1 origin "$branch"
    git -C "$target" checkout -q "$branch"
    git -C "$target" pull --ff-only origin "$branch"
  else
    log "Cloning $url → $target (branch: $branch)…"
    git clone --branch "$branch" --depth=1 "$url" "$target"
  fi
  printf '%s' "$target"
}

deploy_config_dir() {
  local repo_path="$1"
  local src="$repo_path/config"
  local dst="$HOME/.config"

  if [ ! -d "$src" ]; then
    warn "Expected '$src' not found; skipping config deployment."
    return 2
  fi

  if [ -d "$dst" ]; then
    log "Backing up existing ~/.config → $CONFIG_BACKUP"
    cp -a "$dst" "$CONFIG_BACKUP"
  fi
  ensure_dir "$dst"
  log "Copying $src → $dst"
  # Copy contents of ./config into ~/.config (preserve perms/attrs)
  shopt -s dotglob
  cp -a "$src"/* "$dst"/
  shopt -u dotglob
}

hypr_post_steps() {
  # create store files
  ensure_dir "$HOME/.config/hypr/store"
  : > "$HOME/.config/hypr/store/dynamic_out.txt"
  : > "$HOME/.config/hypr/store/prev.txt"
  : > "$HOME/.config/hypr/store/latest_notif"

  # chmod executables if present
  for path in \
    "$HOME/.config/hypr/scripts/tools" \
    "$HOME/.config/hypr/scripts" \
    "$HOME/.config/hypr"
  do
    if [ -d "$path" ]; then
      log "Marking executables in $path"
      # avoid errors if globs are empty
      find "$path" -maxdepth 1 -type f -print0 2>/dev/null | xargs -0 -r chmod +x
      # also mark nested tools/* if that folder exists
      if [ -d "$path/tools" ]; then
        find "$path/tools" -type f -print0 2>/dev/null | xargs -0 -r chmod +x
      fi
    fi
  done
}

show_last_24h_txn_summary() {
  log "Last 24h pacman/paru installs/upgrades/removals:"
  local since
  since="$(date -d '24 hours ago' -Is)"
  awk -v since="$since" '
    match($0, /\[([0-9T:+-]+)\].*\] (installed|upgraded|removed) ([^ ]+)/, a) {
      if (a[1] >= since) { print a[2] " " a[3] }
    }
  ' /var/log/pacman.log \
  | sort -u \
  | while read -r action pkg; do
      repo="$(pacman -Si "$pkg" 2>/dev/null | awk "/^Repository/{print \$3}")"
      if [ -z "$repo" ]; then
        if command -v paru >/dev/null 2>&1 && paru -Si "$pkg" >/dev/null 2>&1; then
          repo="aur"
        else
          repo="unknown"
        fi
      fi
      printf "%-9s %-35s %s\n" "$action" "$pkg" "$repo"
    done | column -t || true
}

############################
# =======  MAIN  ========  #
############################

no_root
require_arch
require_sudo

# Update & install
if [ "$DO_FULL_UPGRADE" = "true" ]; then
  log "Synchronizing package databases and upgrading system…"
  sudo pacman -Syu --noconfirm
fi

# Ensure core tools
pacman_install git curl

# Install paru (if we need AUR or user wants it around)
install_paru_if_needed

# Install official repo packages
pacman_install "${PACMAN_PKGS_DEFAULT[@]}"

# Install AUR packages (optional)
if [ "$INSTALL_AUR" = "true" ] && [ "${#AUR_PKGS_DEFAULT[@]}" -gt 0 ]; then
  paru_install "${AUR_PKGS_DEFAULT[@]}"
fi

# Clone + deploy config (optional)
REPO_PATH=""
if [ "$DEPLOY_CONFIG" = "true" ]; then
  if REPO_PATH="$(clone_repo "$REPO_URL" "$REPO_BRANCH" "$REPO_DIR_NAME")"; then
    deploy_config_dir "$REPO_PATH" || true
  fi
fi

# Hypr extras (store files, chmods)
hypr_post_steps

# Summary for context
show_last_24h_txn_summary

log "Done. You may need to log out/in or restart services (e.g., SDDM) for changes to take effect."
