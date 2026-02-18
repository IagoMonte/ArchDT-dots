#!/usr/bin/bash
#inicie o swww
#WALLPAPERS_DIR= $HOME/Wallpapers/current
#WALLPAPER=$(find "$WALLPAPERS_DIR" -type f | shuf -n 1)
#swww img "$WALLPAPER" && wal -i "$WALLPAPER"

# Set the path to the wallpapers directory
wallpapersDir="$HOME/Wallpaper/current"

# Get a list of all image files in the wallpapers directory
wallpapers=("$wallpapersDir"/*)


if [ ${#wallpapers[@]} -eq 0 ]; then
        # If the array is empty, refill it with the image files
        wallpapers=("$wallpapersDir"/*)
    fi

    # Select a random wallpaper from the array
    wallpaperIndex=$(( RANDOM % ${#wallpapers[@]} ))
    selectedWallpaper="${wallpapers[$wallpaperIndex]}"

    # Update the wallpaper using the swww img command
    swww img "$selectedWallpaper" && wal -i "$selectedWallpaper"

WAL_COLORS="$HOME/.cache/wal/colors.json"

# Verifica se o arquivo existe
if [ ! -f "$WAL_COLORS" ]; then
    echo "Arquivo colors.json não encontrado em $WAL_COLORS"
    exit 1
fi

# Extrair cores principais usando jq
background=$(jq -r '.special.background' "$WAL_COLORS")
accent=$(jq -r '.special.foreground' "$WAL_COLORS")  # azul como exemplo de borda ativa

rgba_background=${background#?}
rgba_accent=${accent#?}


hyprctl keyword general:col.active_border "0xff$rgba_accent"
hyprctl keyword general:col.inactive_border "0xff$rgba_background"
/bin/bash ~/.config/wal/hooks/rofi-theme.sh
