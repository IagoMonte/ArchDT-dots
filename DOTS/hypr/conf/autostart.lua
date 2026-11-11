-- Executado uma vez, no inicio da sessao (equivalente ao exec-once)
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    -- hl.exec_cmd("waybar")
    -- hl.exec_cmd("hyprpaper")
    -- hl.exec_cmd("dunst")
    hl.exec_cmd("kbuildsycoca6")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")  -- so texto
    hl.exec_cmd("wl-paste --type image --watch cliphist store") -- so imagem
    hl.exec_cmd("qs -p ~/.config/quickshell/archdt/")
end)
