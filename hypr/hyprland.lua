-- Şafak - Hyprland v0.55+ Resmi Lua Konfigürasyonu
-- Referans: https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------
-- Monitör konfigürasyonları dinamik olarak script tarafından yönetilen dosyadan yükleniyor
pcall(dofile, os.getenv("HOME") .. "/.config/hypr/monitors.lua")




---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "~/.config/rofi/launchers/type-7/launcher.sh"


-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function ()
    -- Bildirim Yöneticisi (Dunst)
    hl.exec_cmd("dunst")

    -- Duvar kağıdı motorunu başlatır (Waypaper'ın en son duvar kağıdını yükler)
    hl.exec_cmd("waypaper --restore &")

    -- Kimlik Doğrulama Ajanı (KDE Polkit)
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- XDG Portals ve D-Bus Entegrasyonu
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    --Bluetooth hoparlöre otomatik bağlanma 
    hl.exec_cmd("~/.config/hypr/scripts/connect_bluetooth.sh &")

    --- Swayos servisi (ses çubuğu) ---
    hl.exec_cmd("swayosd-server --style ~/.config/swayosd/style.css --top-margin 0.92 &")
    
    --- Waybar (Durum Çubuğu — monitör başına bağımsız auto-hide)
    hl.exec_cmd("sh -c 'pkill -f autohide-multi.sh; killall -q waybar; sleep 1.5; exec ~/.config/waybar/autohide-multi.sh'")    
    

    hl.exec_cmd("wl-clip-persist --clipboard regular &")

    -- Start daemon on login
    hl.exec_cmd("snappy-switcher --daemon")

    -- Monitor align script
    hl.exec_cmd("~/.config/hypr/scripts/align_monitors.sh &")

end)









-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- KDE/Plasma Çakışma Önleyiciler & Wayland Ortam Ayarları
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("GDK_BACKEND", "wayland,x11")


-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10, -- Pencerelerin dış boşluğunu biraz daralttık (daha derli toplu durur)

        border_size = 0,

        col = {
            -- Aktif pencere: En açık yeşilden bir tık koyu yeşile doğru 45 derece gradyan
            active_border   = { 
                colors = { "rgba(4a6741ff)", "rgba(3f5a36ff)", "rgba(374f2fff)" }, 
                angle = 45 
            },
            
            -- İnaktif pencereler: Paletin en koyu, göz yormayan orman tabanı yeşili
            inactive_border = "rgba(22311dff)",
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    

    
    decoration = {
        rounding       = 0,
        rounding_power = 10,

        active_opacity   = 0.92,
        inactive_opacity = 0.85,
        
        

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 9,       -- Yarıçapı artırdık (Daha yumuşak geçiş)
            passes    = 3,       -- İşleme sayısını artırdık (Reddit tarzı derin blur)
            vibrancy  = 0.1696,
            new_optimizations = true,
            
        },
    },
    animations = {
        enabled = true,
    },
})

-- Eğriler ve Animasyonlar (Varsayılan Akıcı Ayarlar)
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,  bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "quick", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "quick", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "quick", style = "slide" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })


------------------
---- LAYOUTS -----
------------------
hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    scrolling = {
        fullscreen_on_one_column = true,
    },
})


----------------
----  MISC  ----
----------------
hl.config({
    misc = {
        force_default_wallpaper = 0,     -- Anime maskotlu arka planları kapatır, sadeleştirir
        disable_hyprland_logo   = true,  -- Başlangıçtaki logoyu kapatır
    },
})


---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout  = "tr", -- Klavye düzenini Türkçe yaptık
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        -- --- FARE HASSASİYET AYARLARI ---
        follow_mouse = 1,
        sensitivity = -0.50, 
        accel_profile = "flat",

        touchpad = {
            natural_scroll = false,
        },
    },
    
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})


---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("~/.config/wlogout/launch.sh"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 0"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- PrintScreen (PrtSc) tuşuna basınca alanı seçip panoya kopyalar
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/screenshot.sh"))
-- Alt+Tab (standard MRU)
hl.bind("ALT + Tab", hl.dsp.exec_cmd("snappy-switcher next --mod alt"),
  { description = "Snappy Switcher" })-- Super+Tab (workspace-filtered)


-- Super+Tab: workspace-filtered switching
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("snappy-switcher next --workspace --mod super"),
  { description = "Snappy Switcher (Workspace)" })

-- Yön Tuşları ile Pencere Odaklama
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Çalışma Alanları (Workspaces) Döngüsü
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Özel Scratchpad Alanı (SUPER + S)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse Scroll ile Çalışma Alanları Arasında Geçiş
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse ile Taşıma ve Boyutlandırma (SUPER + Sol/Sağ Tık)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Ses ve Parlaklık Kısayolları (Pipewire / Wireplumber Uyumlu)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Medya Kontrolleri
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- Akıllı Boşluklar (Smart Gaps): Ekranda tek pencere varken boşlukları, kenarlıkları ve yuvarlamaları sıfırla
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

hl.window_rule({
    name = "smart-gaps-tiled",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding = 0,
})
hl.window_rule({
    name = "smart-gaps-fullscreen",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding = 0,
})

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Waybar katman kuralları (auto-hide slide animasyonu)
hl.layer_rule({
    match = { namespace = "waybar" },
    animation = "slide bottom",
})

hl.layer_rule({
    match = { namespace = "logout_dialog" },
    blur = true,
    ignore_alpha = 0.5,
    animation = "fade",
})
hl.layer_rule({
    match = { namespace = "gtk-layer-shell" },
})

-- Dunst bildirimleri için cam efekti (buzlu arka plan)
hl.layer_rule({
    match = { namespace = "notifications" },
    animation = "slide right",
})

-- EWW katman kuralları (Ekran kararmasını çözer ve dışarı tıklamayı yakalar)
hl.layer_rule({
    match = { namespace = "eww" },
    -- Başka yere odaklanınca veya tıklayınca katmanı otomatik kapatır:
    above_lock = 0
})

-- EWW penceresi için güncellenmiş kesin çözüm Lua kural tanımı
hl.window_rule({
    name = "eww-brightness-popup",
    match = { class = "eww" },
    float = true,
    pin = true,
    border_size = 0,    
    no_anim = true,
    opaque = false, -- Ekranın kararmasını önleyen kritik parametre
    opacity = "1.0 override 1.0 override" 
})

-- VSCode (Code-OSS) için Blur ve Şeffaflık Kuralı
hl.window_rule({
    name = "vscode-blur",
    match = { class = "code-oss" },
    float = false,
    -- Aktif ve inaktif opaklığı dokümantasyona tam uyumlu string olarak veriyoruz:
    opacity = "0.85 override 0.85 override"
})


-- Gamescope (Oyunlar) için Şeffaflığı ve Bulanıklığı Tamamen Kapatma Rule'u
hl.window_rule({
    name = "gamescope-opaque",
    match = { class = "gamescope" },
    float = true,
    border_size = 0,
    no_blur = true,
    opaque = true,
    opacity = "1.0 override 1.0 override"
})



-- (Garanti Çözüm) Tam Ekrandaki Tüm Pencereleri Opak Yapma Rule'u
hl.window_rule({
    name = "fullscreen-opaque-force",
    match = { fullscreen = true },
    opaque = true,
    opacity = "1.0 override 1.0 override"
})


-- Matugen Material You Renk Paleti (Geçersiz kılmak için en sonda yüklenir)
pcall(dofile, os.getenv("HOME") .. "/.config/hypr/colors.lua")
