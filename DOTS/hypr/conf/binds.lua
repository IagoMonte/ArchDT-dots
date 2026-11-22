-- https://wiki.hypr.land/Configuring/Basics/Binds/
--
-- Formato lido pelo cheatsheet do Quickshell (scripts/hyprland/get_keybinds.py):
--   -- >>> Coluna        -- >> Secao
--   bind("MODS + KEY", dispatcher, "descricao")   -- "[hidden]" no inicio esconde do cheatsheet

local mainMod = "SUPER"
local dsp = hl.dsp

local function bind(keys, dispatcher, desc, opts)
    opts = opts or {}
    opts.description = desc
    hl.bind(keys, dispatcher, opts)
end
local function binde(keys, dispatcher, desc)  bind(keys, dispatcher, desc, { repeating = true }) end
local function bindm(keys, dispatcher, desc)  bind(keys, dispatcher, desc, { mouse = true }) end
local function bindrt(keys, dispatcher, desc) bind(keys, dispatcher, desc, { release = true, transparent = true }) end

-- >>> General

-- >> Window Management
bind(mainMod .. " + C",            dsp.window.close(),                                "Close current window")
bind(mainMod .. " + TAB",          dsp.window.float({ action = "toggle" }),           "Toggle between tiling and floating window")
bind(mainMod .. " + RETURN",       dsp.window.fullscreen({ mode = "maximized" }),     "Open the window in fullscreen")
bind(mainMod .. " + SHIFT + RETURN", dsp.window.fullscreen({ mode = "fullscreen" }),  "Toggle fullscreen")
bind(mainMod .. " + N",            dsp.window.pseudo(),                               "Pseudo float")
bind(mainMod .. " + J",            dsp.layout("togglesplit"),                         "Toggle dwindle split")

-- >> Focus Navigation
bind(mainMod .. " + left",  dsp.focus({ direction = "left" }),  "Move focus left")
bind(mainMod .. " + right", dsp.focus({ direction = "right" }), "Move focus right")
bind(mainMod .. " + up",    dsp.focus({ direction = "up" }),    "Move focus up")
bind(mainMod .. " + down",  dsp.focus({ direction = "down" }),  "Move focus down")

-- >> Applications
bind(mainMod .. " + T", dsp.exec_cmd("kitty"),   "Open kitty")
bind(mainMod .. " + E", dsp.exec_cmd("dolphin"), "Opens the filemanager")
-- bind(mainMod .. " + SPACE", dsp.exec_cmd("rofi -show drun"), "Open rofi")
bind(mainMod .. " + P", dsp.exec_cmd("vivaldi"), "Opens the browser")

-- >> System
bind(mainMod .. " + CTRL + SHIFT + K", dsp.exit(),                                           "Exit Hyprland")
bind(mainMod .. " + SHIFT + B", dsp.exec_cmd("~/.config/hypr/scripts/reload-quickshell.sh"), "Reload Quickshell")
bind(mainMod .. " + SHIFT + W", dsp.exec_cmd("~/.config/hypr/scripts/reload-hyprpaper.sh"),  "Random wallpaper")

-- >>> Quickshell

-- >> Overview & Tools
bind("ALT + TAB",          dsp.global("quickshell:hyprview"),                                       "Open Windows and Navigate to next")
binde("ALT + TAB",         dsp.exec_cmd("qs ipc -p .config/quickshell/archdt call hyprview next"),  "[hidden]")
bind("ALT + SHIFT + TAB", dsp.exec_cmd("qs ipc -p .config/quickshell/archdt call hyprview prev"),  "Previous window")
bindrt("ALT + ALT_L",      dsp.exec_cmd("qs ipc -p .config/quickshell/archdt call hyprview release"), "[hidden]")
bindrt("ALT + ALT_R",      dsp.exec_cmd("qs ipc -p .config/quickshell/archdt call hyprview release"), "[hidden]")
bind(mainMod .. " + SPACE",  dsp.global("quickshell:overviewSearchToggle"),    "Toggle Launcher")
bind(mainMod .. " + Slash",  dsp.global("quickshell:cheatsheetToggle"),        "Toggle cheatsheet")
bind(mainMod .. " + V",      dsp.global("quickshell:overviewClipboardToggle"), "Toggle clipboard")
bind(mainMod .. " + period", dsp.global("quickshell:overviewEmojiToggle"),     "Toggle Emojis")
bind(mainMod .. " + A",      dsp.exec_cmd("qs ipc -p .config/quickshell/archdt call sidebarRight toggle"),   "Toggle sidebar")
bind(mainMod .. " + D",      dsp.exec_cmd("qs ipc -p .config/quickshell/archdt call mediaControls toggle"),  "Toggle media controls")

-- >> Screenshots
bind(mainMod .. " + SHIFT + S",        dsp.global("quickshell:regionScreenshot"),         "Screenshot")
bind(mainMod .. " + SHIFT + R",        dsp.global("quickshell:regionRecord"),             "Screen Record")
bind(mainMod .. " + CTRL + SHIFT + R", dsp.global("quickshell:regionRecordWithSound"),    "Screen Record with audio")

-- >>> Workspaces

-- >> Switch Workspace
--/# SUPER | 1..0 | Switch to workspace (1, 2, 3,...)
-- >> Move to Workspace
--/# SUPER + SHIFT | 1..0 | Move window to workspace (1, 2, 3,...)
for i = 1, 10 do
    local key = i % 10 -- workspace 10 -> tecla 0
    bind(mainMod .. " + " .. key,           dsp.focus({ workspace = i }),          "[hidden]")
    bind(mainMod .. " + SHIFT + " .. key,   dsp.window.move({ workspace = i }),    "[hidden]")
end

-- >> Scroll Workspaces
bind(mainMod .. " + mouse_down", dsp.focus({ workspace = "e+1" }), "Scroll workspaces down")
bind(mainMod .. " + mouse_up",   dsp.focus({ workspace = "e-1" }), "Scroll workspaces up")

-- >>> Media & Hardware

-- >> Media Control
bind("CTRL + ALT + 0",     dsp.exec_cmd("playerctl previous"),   "Previous track")
bind("CTRL + ALT + Minus", dsp.exec_cmd("playerctl play-pause"), "Play/pause media")
bind("CTRL + ALT + Equal", dsp.exec_cmd("playerctl next"),       "Next track")

-- >> Volume & Brightness
bind("CTRL + SHIFT + Equal", dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up")
bind("CTRL + SHIFT + Minus", dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"), "Volume down")

-- >> Keyboard Controls
bind("CTRL + ALT + SHIFT + 1", dsp.exec_cmd("~/.config/hypr/scripts/k500KM.sh Full"),  "Keyboard profile: Full")
bind("CTRL + ALT + SHIFT + 2", dsp.exec_cmd("~/.config/hypr/scripts/k500KM.sh Setas"), "Keyboard profile: Setas")

-- >>> Mouse

-- >> Window Actions
bindm(mainMod .. " + mouse:272", dsp.window.drag(),   "Move window")
bindm(mainMod .. " + mouse:273", dsp.window.resize(), "Resize window")
