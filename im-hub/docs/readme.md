# ArchDT-dots

Setup Arch + Hyprland com theming dinâmico: as cores do sistema inteiro acompanham o wallpaper via pywal.

## Problema

Manter um desktop tiling bonito e um theming consistente entre terminal, bar, GTK/Qt e shell exigia editar dezenas de configs a cada troca. Faltava um setup versionado e reinstalável com um comando.

## O que foi construído

- `DOTS/`, espelho versionado de `~/.config/`: Hyprland modular (`hypr/conf/*.conf`, 59 atalhos), shell Quickshell `archdt` (bar, sidebar, overview, OSD), kitty + starship, swww/awww, waypaper, wlogout, qt5ct/qt6ct e GTK.
- `install.sh` standalone: dry-run (`--check`), symlink ou cópia (`--copy`), pulo de pacotes (`--no-packages`), backup com timestamp em `~/.config-backup-archdt-*`.
- Theming dinâmico: `wal` gera a paleta; kitty, starship e Quickshell acompanham. Timer `change_wallpaper` troca o papel de parede a cada hora.
- Mais de 140 wallpapers em `Wallpaper/` e listas de pacotes (`packages.txt`, `packages-repo.txt`, `packages-aur.txt`).

## Como instalar

```bash
git clone https://github.com/IagoMonte/ArchDT-dots.git
cd ArchDT-dots
./install.sh --check   # dry-run
./install.sh           # symlink (padrão) ou ./install.sh --copy
```

No Arch do zero, o repo ArchDT (`user_configuration.json` do archinstall) já clona este repo e copia `DOTS/*` para `~/.config/`.
