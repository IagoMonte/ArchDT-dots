#!/usr/bin/env bash
# ArchDT-dots standalone installer
# Default: symlink (por convencao). Use --copy para cp -rn (mais dificil quebrar).
# Sem ProfileSwitcherK500 (uso pessoal do autor, fora do standalone).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_DIR="$REPO_DIR/DOTS"
MODE="link"
DRY_RUN=0
SKIP_PACKAGES=0
BACKUP_BASE="$HOME/.config-backup-archdt"

PACMAN_PKGS=(
  hyprland hyprlock hypridle hyprcursor
  kitty dolphin dolphin-plugins ark kio-admin
  polkit-kde-agent xdg-desktop-portal xdg-desktop-portal-wlr
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  gtk3 gtk4 qt5-wayland qt6-wayland qt5ct qt6ct
  cliphist mpv pavucontrol-qt xdg-user-dirs-gtk
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
  papirus-icon-theme nwg-look
  quickshell awww starship fastfetch
  python-pywal wl-clipboard grim slurp wf-recorder
  polkit kde-cli-tools
)

AUR_PKGS=(
  wlogout waypaper
  python-pywal
)

usage() {
  cat <<EOF
Uso: ./install.sh [opcoes]

  --link        symlink DOTS/* -> ~/.config/* (default, convencao)
  --copy        cp -rn DOTS/* -> ~/.config/* (robusto, nao quebra se mover o repo)
  --check       dry-run, so mostra o que faria
  --no-packages pula instalacao de pacotes
  --backup DIR  diretorio de backup (default: $BACKUP_BASE-<data>)
  -h, --help    esta ajuda
EOF
}

log()  { echo -e "\033[1;34m[archdt]\033[0m $*"; }
dry()  { if [[ $DRY_RUN -eq 1 ]]; then echo "[dry-run] $*"; return 0; fi; return 1; }
run()  { if dry "$*"; then return 0; fi; eval "$@"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --link) MODE="link"; shift ;;
    --copy) MODE="copy"; shift ;;
    --check) DRY_RUN=1; shift ;;
    --no-packages) SKIP_PACKAGES=1; shift ;;
    --backup) BACKUP_BASE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opcao desconhecida: $1"; usage; exit 1 ;;
  esac
done

log "repo: $REPO_DIR | modo: $MODE"

# --- 1. pacotes ---
if [[ $SKIP_PACKAGES -eq 0 ]]; then
  if dry "sudo pacman -Syu --needed ${PACMAN_PKGS[*]}"; then :; else
    if ! command -v pacman &>/dev/null; then echo "pacman nao encontrado, so Arch suportado."; exit 1; fi
    sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"
  fi
  if dry "yay -S --needed ${AUR_PKGS[*]}"; then :; else
    if ! command -v yay &>/dev/null; then
      log "yay nao encontrado, instalando..."
      tmp="$(mktemp -d)"; git clone https://aur.archlinux.org/yay.git "$tmp/yay"
      (cd "$tmp/yay" && makepkg -si --noconfirm); rm -rf "$tmp"
    fi
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
  fi
else
  log "pulando pacotes (--no-packages)"
fi

# --- 2. backup ---
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_BASE-$STAMP"
log "backup em: $BACKUP_DIR"
if [[ $DRY_RUN -eq 0 ]]; then mkdir -p "$BACKUP_DIR"; fi

backup_one() { # $1 = caminho em $HOME
  local src="$1"
  [[ -e "$src" || -L "$src" ]] || return 0
  local rel="${src#$HOME/}"
  if dry "backup $src -> $BACKUP_DIR/$rel"; then return 0; fi
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  mv "$src" "$BACKUP_DIR/$rel"
}

# --- 3. deploy DOTS/* ---
log "deploy DOTS/* -> ~/.config/* ($MODE)"
mkdir -p "$HOME/.config"
for src in "$DOTS_DIR"/*; do
  name="$(basename "$src")"
  # pula binario maquina-especifica e perfis pessoais do teclado
  if [[ "$name" == "dconf" || "$name" == "k500Profiles" ]]; then log "pulando $name (local/pessoal)"; continue; fi
  dest="$HOME/.config/$name"
  if [[ "$MODE" == "link" ]]; then
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then log "ok (ja linkado): $name"; continue; fi
    backup_one "$dest"
    run "ln -sfn \"$src\" \"$dest\""
  else
    if dry "cp -rn $src -> $dest"; then continue; fi
    if [[ -d "$src" ]]; then
      mkdir -p "$dest"
      # cp -rn = no-clobber: nao sobrescreve o que ja existe (comportamento historico do ArchDT)
      cp -rn "$src/." "$dest/"
    else
      mkdir -p "$(dirname "$dest")"
      cp -n "$src" "$dest" 2>/dev/null || true
    fi
    log "copiado (no-clobber): $name"
  fi
done

# --- 4. .bashrc ---
if [[ "$MODE" == "link" ]]; then
  backup_one "$HOME/.bashrc"
  run "ln -sfn \"$REPO_DIR/.bashrc\" \"$HOME/.bashrc\""
else
  if [[ -f "$HOME/.bashrc" ]]; then
    if dry "backup + cp .bashrc"; then :; else
      mkdir -p "$BACKUP_DIR"; cp -n "$HOME/.bashrc" "$BACKUP_DIR/.bashrc" 2>/dev/null || true
      cp "$REPO_DIR/.bashrc" "$HOME/.bashrc"
      log ".bashrc copiado (backup em $BACKUP_DIR/.bashrc)"
    fi
  else
    run "cp \"$REPO_DIR/.bashrc\" \"$HOME/.bashrc\""
  fi
fi

# --- 5. Wallpaper (sempre copia, nunca symlink) ---
if dry "cp -rn Wallpaper -> ~/Wallpaper"; then :; else
  mkdir -p "$HOME/Wallpaper"
  cp -rn "$REPO_DIR/Wallpaper/." "$HOME/Wallpaper/"
  log "wallpapers copiados (no-clobber)"
fi

# --- 6. systemd user ---
log "habilitando services user (swww/awww + change_wallpaper)"
if dry "systemctl --user enable ..."; then :; else
  mkdir -p "$HOME/.config/systemd/user/default.target.wants"
  ln -sf "$HOME/.config/systemd/user/swww.service" \
    "$HOME/.config/systemd/user/default.target.wants/swww.service" 2>/dev/null || true
  ln -sf "$HOME/.config/systemd/user/change_wallpaper.service" \
    "$HOME/.config/systemd/user/default.target.wants/change_wallpaper.service" 2>/dev/null || true
  ln -sf "$HOME/.config/systemd/user/change_wallpaper.timer" \
    "$HOME/.config/systemd/user/default.target.wants/change_wallpaper.timer" 2>/dev/null || true
  systemctl --user daemon-reload || true
fi

# --- 7. pywal + starship ---
WALLPAPER_DEFAULT="$(find "$HOME/Wallpaper/current" -maxdepth 1 -type f | head -n 1)"
if [[ -n "${WALLPAPER_DEFAULT:-}" ]] && command -v wal &>/dev/null; then
  run "wal -i \"$WALLPAPER_DEFAULT\" || true"
fi
if [[ -f "$HOME/.cache/wal/starship.toml" ]]; then
  backup_one "$HOME/.config/starship.toml"
  run "ln -sfn \"$HOME/.cache/wal/starship.toml\" \"$HOME/.config/starship.toml\""
fi

log "pronto! Logue em Hyprland. Dica: waypaper backend atual = awww."
log "Para modo robusto sem symlink: ./install.sh --copy"
