hl.config({
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})

-- Tela cheia: não trocar a saída para modo HDR/10 bits automaticamente
hl.config({
    render = {
        cm_auto_hdr = 0,
    },
})
