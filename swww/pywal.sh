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