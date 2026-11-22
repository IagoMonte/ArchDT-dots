#!/bin/bash
# Reinicia o Quickshell (para quando o hot-reload não resolve ou o shell trava)
CFG="$HOME/.config/quickshell/archdt/"
qs kill -p "$CFG"
sleep 0.5
qs -p "$CFG" -d
