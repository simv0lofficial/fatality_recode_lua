-- Keystrokes Overlay for Fatality Recode
-- Strictly registers physical keyboard input (immune to Anti-Aim and movement helpers)

local ui_enabled = gui.add_checkbox("Keystrokes Overlay", "lua>tab a")
local ui_color = gui.add_colorpicker("lua>tab a>Keystrokes Overlay", true, { r = 140, g = 95, b = 255, a = 235 })
local ui_pos_x = gui.add_slider("Keystrokes Pos X", "lua>tab a", 0, 2560, 1)
local ui_pos_y = gui.add_slider("Keystrokes Pos Y", "lua>tab a", 0, 1440, 1)
local ui_size = gui.add_slider("Key Size", "lua>tab a", 24, 60, 1)
local ui_gap = gui.add_slider("Key Spacing", "lua>tab a", 2, 10, 1)
local ui_rounding = gui.add_slider("Key Rounding", "lua>tab a", 0, 12, 1)
local ui_layout = gui.add_combo("Bottom Layout", "lua>tab a", { "Wide Rows", "Split (Ctrl | Space)" })
local ui_labels = gui.add_combo("Labels Mode", "lua>tab a", { "WASD / SPACE / CTRL", "WASD / JUMP / DUCK" })

-- Initial defaults
local initialized = false
local function init_defaults()
    if initialized then return end
    if ui_pos_x:get_int() == 0 and ui_pos_y:get_int() == 0 then
        local sw, sh = render.get_screen_size()
        ui_pos_x:set_int(35)
        ui_pos_y:set_int(math.floor(sh / 2 - 80))
        ui_size:set_int(36)
        ui_gap:set_int(4)
        ui_rounding:set_int(4)
        ui_enabled:set_bool(true)
    end
    initialized = true
end

-- Fonts with fallback
local font_main = render.create_font("verdana.ttf", 12, render.font_flag_shadow)
local font_small = render.create_font("verdana.ttf", 10, render.font_flag_shadow)
if not font_main or font_main == 0 then font_main = render.font_esp end
if not font_small or font_small == 0 then font_small = render.font_esp end

-- Helper: linear interpolation
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Animation progress storage
local anim_keys = {
    w = 0.0,
    a = 0.0,
    s = 0.0,
    d = 0.0,
    space = 0.0,
    ctrl = 0.0,
}

-- Dragging support when menu is opened
local is_dragging = false
local drag_offset_x = 0
local drag_offset_y = 0

local function handle_drag(x, y, w, h)
    if not gui.is_menu_open() then
        is_dragging = false
        return
    end

    local cursor_x, cursor_y = input.get_cursor_pos()
    local mouse_down = input.is_key_down(1) -- VK_LBUTTON

    if mouse_down then
        if not is_dragging then
            if cursor_x >= x - 4 and cursor_x <= x + w + 4 and cursor_y >= y - 4 and cursor_y <= y + h + 4 then
                is_dragging = true
                drag_offset_x = cursor_x - x
                drag_offset_y = cursor_y - y
            end
        else
            local target_x = math.max(0, math.floor(cursor_x - drag_offset_x))
            local target_y = math.max(0, math.floor(cursor_y - drag_offset_y))
            ui_pos_x:set_int(target_x)
            ui_pos_y:set_int(target_y)
        end
    else
        is_dragging = false
    end

    -- Visual bounding outline when cheat menu is open
    local drag_border_col = is_dragging and { r = 180, g = 140, b = 255, a = 200 } or { r = 90, g = 90, b = 110, a = 120 }
    render.rect(x - 3, y - 3, x + w + 3, y + h + 3, drag_border_col)
end

-- Render a single key button
local function draw_key_button(x, y, w, h, label, anim, active_col, rounding, font_override)
    local r_active = active_col.r or 140
    local g_active = active_col.g or 95
    local b_active = active_col.b or 255
    local a_active = active_col.a or 235

    -- Background color interpolation (Idle dark -> Active accent)
    local bg_col = {
        r = math.floor(lerp(18, r_active, anim)),
        g = math.floor(lerp(20, g_active, anim)),
        b = math.floor(lerp(26, b_active, anim)),
        a = math.floor(lerp(175, a_active, anim)),
    }

    -- Border outline interpolation
    local border_col = {
        r = math.floor(lerp(42, math.min(255, r_active + 30), anim)),
        g = math.floor(lerp(46, math.min(255, g_active + 30), anim)),
        b = math.floor(lerp(58, math.min(255, b_active + 30), anim)),
        a = math.floor(lerp(190, 255, anim)),
    }

    -- Text color interpolation
    local text_col = {
        r = math.floor(lerp(185, 255, anim)),
        g = math.floor(lerp(190, 255, anim)),
        b = math.floor(lerp(205, 255, anim)),
        a = math.floor(lerp(210, 255, anim)),
    }

    local fnt = font_override or font_main

    if rounding > 0 then
        -- Outer rounded border
        render.rect_filled_rounded(x, y, x + w, y + h, border_col, rounding, render.all)
        -- Inner rounded fill (1px padding)
        local inner_rounding = math.max(0, rounding - 1)
        render.rect_filled_rounded(x + 1, y + 1, x + w - 1, y + h - 1, bg_col, inner_rounding, render.all)
        -- Upper highlight sheen when pressed
        if anim > 0.05 then
            render.line(x + rounding, y + 1, x + w - rounding, y + 1, { r = 255, g = 255, b = 255, a = math.floor(75 * anim) })
        end
    else
        -- Flat rect fill and border
        render.rect_filled(x, y, x + w, y + h, bg_col)
        render.rect(x, y, x + w, y + h, border_col)
        if anim > 0.05 then
            render.line(x + 1, y + 1, x + w - 1, y + 1, { r = 255, g = 255, b = 255, a = math.floor(75 * anim) })
        end
    end

    -- Centered text label
    local cx = x + w / 2
    local cy = y + h / 2
    render.text(fnt, cx, cy, label, text_col, render.align_center, render.align_center)
end

function on_paint()
    init_defaults()

    if not ui_enabled:get_bool() then
        return
    end

    local dt = math.min(global_vars.frametime or 0.016, 0.1)
    local anim_rate = dt * 18.0

    -- Strict physical keyboard input checking:
    -- VK_W = 0x57, VK_A = 0x41, VK_S = 0x53, VK_D = 0x44
    -- VK_SPACE = 0x20
    -- VK_CONTROL = 0x11, VK_LCONTROL = 0xA2, VK_RCONTROL = 0xA3
    -- This ignores any usercmd/buttons injected by anti-aim, fake duck, or autostop
    local w_down = input.is_key_down(0x57)
    local a_down = input.is_key_down(0x41)
    local s_down = input.is_key_down(0x53)
    local d_down = input.is_key_down(0x44)
    local space_down = input.is_key_down(0x20)
    local ctrl_down = input.is_key_down(0x11) or input.is_key_down(0xA2) or input.is_key_down(0xA3)

    -- Update smooth transitions
    local function update_anim(current, target_active)
        if target_active then
            return math.min(1.0, current + anim_rate)
        else
            return math.max(0.0, current - anim_rate)
        end
    end

    anim_keys.w = update_anim(anim_keys.w, w_down)
    anim_keys.a = update_anim(anim_keys.a, a_down)
    anim_keys.s = update_anim(anim_keys.s, s_down)
    anim_keys.d = update_anim(anim_keys.d, d_down)
    anim_keys.space = update_anim(anim_keys.space, space_down)
    anim_keys.ctrl = update_anim(anim_keys.ctrl, ctrl_down)

    -- Layout measurements
    local origin_x = ui_pos_x:get_int()
    local origin_y = ui_pos_y:get_int()
    local size = ui_size:get_int()
    local gap = ui_gap:get_int()
    local rounding = ui_rounding:get_int()
    local active_col = ui_color:get_color()
    local is_split = ui_layout:get_int() == 1
    local alt_labels = ui_labels:get_int() == 1

    local total_width = size * 3 + gap * 2
    local bar_h = math.max(18, math.floor(size * 0.65))

    local space_label = alt_labels and "JUMP" or "SPACE"
    local ctrl_label = alt_labels and "DUCK" or "CTRL"

    -- Calculate bounding box for drag handling
    local total_height = 0
    if is_split then
        total_height = size * 2 + gap + bar_h
    else
        total_height = size * 2 + bar_h * 2 + gap * 3
    end

    handle_drag(origin_x, origin_y, total_width, total_height)

    -- Row 0: W (Centered above S)
    local w_x = origin_x + size + gap
    local w_y = origin_y
    draw_key_button(w_x, w_y, size, size, "W", anim_keys.w, active_col, rounding, font_main)

    -- Row 1: A, S, D
    local row1_y = origin_y + size + gap
    local a_x = origin_x
    local s_x = origin_x + size + gap
    local d_x = origin_x + (size + gap) * 2
    draw_key_button(a_x, row1_y, size, size, "A", anim_keys.a, active_col, rounding, font_main)
    draw_key_button(s_x, row1_y, size, size, "S", anim_keys.s, active_col, rounding, font_main)
    draw_key_button(d_x, row1_y, size, size, "D", anim_keys.d, active_col, rounding, font_main)

    -- Bottom controls (SPACE / CTRL)
    if is_split then
        -- Row 2: CTRL | SPACE side-by-side
        local row2_y = row1_y + size + gap
        local half_w = math.floor((total_width - gap) / 2)
        local ctrl_x = origin_x
        local space_x = origin_x + half_w + gap

        draw_key_button(ctrl_x, row2_y, half_w, bar_h, ctrl_label, anim_keys.ctrl, active_col, rounding, font_small)
        draw_key_button(space_x, row2_y, half_w, bar_h, space_label, anim_keys.space, active_col, rounding, font_small)
    else
        -- Row 2: SPACE (Full width bar)
        local row2_y = row1_y + size + gap
        draw_key_button(origin_x, row2_y, total_width, bar_h, space_label, anim_keys.space, active_col, rounding, font_small)

        -- Row 3: CTRL (Full width bar)
        local row3_y = row2_y + bar_h + gap
        draw_key_button(origin_x, row3_y, total_width, bar_h, ctrl_label, anim_keys.ctrl, active_col, rounding, font_small)
    end
end

function on_shutdown()
end
