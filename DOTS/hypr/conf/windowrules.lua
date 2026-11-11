-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
local function opacity(name, class, value)
    hl.window_rule({ name = name, match = { class = class }, opacity = value })
end

opacity("opacity-mousepad",   "org.xfce.mousepad",         0.6)
opacity("opacity-code",       "code",                      0.9)
opacity("opacity-texteditor", "org.gnome.TextEditor",      0.8)
opacity("opacity-pavucontrol","org.pulseaudio.pavucontrol",0.8)
opacity("opacity-simplenote", "Simplenote",                0.9)

hl.window_rule({
    name  = "pip",
    match = { title = "Picture in picture" },
    float = true,
    pin   = true,
})
