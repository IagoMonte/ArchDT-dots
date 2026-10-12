# Arquitetura — ArchDT-dots

## Stack

Hyprland, Quickshell, pywal, kitty + starship, awww-daemon + waypaper, wlogout, Bash.

## Estrutura

```text
ArchDT-dots/
├── .bashrc                  # prompt starship + aliases
├── Wallpaper/current/       # 140+ wallpapers
├── DOTS/                    # espelho de ~/.config/
│   ├── hypr/conf/*.conf     # hyprland modular
│   ├── quickshell/archdt/   # shell (bar, sidebar, overview, OSD)
│   ├── kitty/kitty.conf     # inclui colors-kitty do pywal
│   ├── wal/templates/       # starship.toml gerado pelo pywal
│   ├── swww/                # scripts awww + pywal
│   └── systemd/user/        # serviços e timer de wallpaper
├── install.sh               # instalador standalone
└── packages*.txt            # listas pacman e AUR
```

## Decisões

- **Espelho, não gerador**: `DOTS/` reflete o `~/.config/` real; o instalador só linka ou copia, sem templating.
- **pywal como fonte da verdade**: `awww img <wall> && wal -i <wall>` gera a paleta em `~/.cache/wal/`; starship é symlink para o arquivo gerado.
- **Segurança do instalador**: backup com timestamp antes de mexer, `cp -rn` (no-clobber) para wallpapers e `.bashrc`, nunca sobrescreve `dconf/user`.
- **Serviços por usuário**: swww-daemon e troca horária de wallpaper via `systemd --user`, sem root.
