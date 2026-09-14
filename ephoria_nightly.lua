--.name Ephoria Nightly
--.description Kill everything in your path
--.author CrazyTaco x Spoofer

print("Thank for buy lua Ephoria") 

print(" _____________________________________ ")
print("| Ephoria                             |")
print("| Kill everything in your path        |")
print("| Coder: CrazyTaco x Spoofer          |")
print("|_____________________________________|")

local color = render.color

local k = nil
if pcall then
    local ok, res = pcall(require, 'clipboard')
    if ok and res then k = res end
end
if not k then
    k = {
        _val = "",
        get = function() return k._val end,
        set = function(v) k._val = tostring(v) end
    }
end

local function safe_get_config_item(path)
    if pcall then
        local ok, item = pcall(gui.get_config_item, path)
        if ok and item then return item end
        local dummy = {}
        function dummy:get_bool() return false end
        function dummy:get_int() return 0 end
        function dummy:get_float() return 0.0 end
        function dummy:get_string() return "" end
        function dummy:get_color() return render.color(255, 255, 255, 255) end
        function dummy:set_bool(v) end
        function dummy:set_int(v) end
        function dummy:set_float(v) end
        function dummy:set_string(v) end
        function dummy:set_color(v) end
        return dummy
    else
        return gui.get_config_item(path)
    end
end

local function safe_set_visible(path, visible)
    if pcall then
        pcall(gui.set_visible, path, visible)
    else
        gui.set_visible(path, visible)
    end
end

local function get_velocity(ent)
    if not ent or not ent:is_valid() then return 0, 0, 0, 0 end
    local vx, vy, vz = ent:get_prop('m_vecVelocity')
    vx = vx or 0
    vy = vy or 0
    vz = vz or 0
    return vx, vy, vz, math.sqrt(vx * vx + vy * vy)
end

local j = { anim_list = {} }
j.math_clamp = function(k, j, s) return math.min(s, math.max(j, k)) end
j.math_lerp = function(k, s, c)
    local N = j.math_clamp(.02, 0, 1)
    if type(k) == 'userdata' or type(k) == 'table' then
        local r, g, b, a_val = k.r, k.g, k.b, k.a
        local e_r, e_g, e_b, e_a = s.r, s.g, s.b, s.a
        r = j.math_lerp(r, e_r, N)
        g = j.math_lerp(g, e_g, N)
        b = j.math_lerp(b, e_b, N)
        a_val = j.math_lerp(a_val, e_a, N)
        return render.color(r, g, b, a_val)
    end

    local m = s - k
    m = m * N
    m = m + k
    if s == 0 and (m < .01 and m > -0.01) then
        m = 0
    elseif s == 1 and (m < 1.01 and m > .99) then
        m = 1
    end
    return m
end
j.vector_lerp = function(k, j, s) return k + (j - k) * s end
j.anim_new = function(k, s, c, N)
    if not j.anim_list[k] then
        j.anim_list[k] = {}
        j.anim_list[k].color = render.color(0, 0, 0, 0)
        j.anim_list[k].number = 0
        j.anim_list[k].call_frame = true
    end
    if c == nil then j.anim_list[k].call_frame = true end
    if N == nil then N = .1 end
    if type(s) == 'userdata' or type(s) == 'table' then
        local lerp = j.math_lerp(j.anim_list[k].color, s, N)
        j.anim_list[k].color = lerp
        return lerp
    end
    local lerp = j.math_lerp(j.anim_list[k].number, s, N)
    j.anim_list[k].number = lerp
    return lerp
end

local function gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, text)
    local output = ""
    local len = #text-1
    local rinc = (r2 - r1) / len
    local ginc = (g2 - g1) / len
    local binc = (b2 - b1) / len
    local ainc = (a2 - a1) / len
    for i=1, len+1 do
        output = output .. ("\a%02x%02x%02x%02x%s"):format(r1, g1, b1, a1, text:sub(i, i))
        r1 = r1 + rinc
        g1 = g1 + ginc
        b1 = b1 + binc
        a1 = a1 + ainc
    end

    return output
end

local s_b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function c(k)
    return (k:gsub('.', function(k)
        local j, s = '', k:byte()
        for k = 8, 1, -1 do j = j .. (s % 2 ^ k - s % 2 ^ (k - 1) > 0 and '1' or '0') end
        return j
    end) .. '0000'):gsub('%d%d%d?%d?%d?', function(k)
        if #k < 6 then return '' end
        local j = 0
        for s = 1, 6, 1 do j = j + (k:sub(s, s) == '1' and 2 ^ (6 - s) or 0) end
        return s:sub(j + 1, j + 1)
    end) .. ({ '', '==', '=' })[#k % 3 + 1]
end
local function N(k)
    k = string.gsub(k, '[^' .. (s_b64 .. '=]'), '')
    return (k:gsub('.', function(k)
        if k == '=' then return '' end
        local j, c = '', s_b64:find(k) - 1
        for k = 6, 1, -1 do j = j .. (c % 2 ^ k - c % 2 ^ (k - 1) > 0 and '1' or '0') end
        return j
    end)):gsub('%d%d%d?%d?%d?%d?', function(k)
        if #k ~= 8 then return '' end
        local j = 0
        for s = 1, 8, 1 do j = j + (k:sub(s, s) == '1' and 2 ^ (8 - s) or 0) end
        return string.char(j)
    end)
end

local function encode_base64(str)
    if utils and utils.base64_encode then
        local ok, res = pcall(utils.base64_encode, str)
        if ok and res then return res end
    end
    return c(str)
end

local function decode_base64(str)
    if utils and utils.base64_decode then
        local ok, res = pcall(utils.base64_decode, str)
        if ok and res then return res end
    end
    return N(str)
end

local function m(k, j)
    local s = {}
    for k in string.gmatch(k, '([^' .. (j .. ']+)')) do s[#s + 1] = string.gsub(k, '\n', ' ') end
    return s
end
local function D(k)
    if k == 'true' or k == 'false' then
        return k == 'true'
    else
        return k
    end
end

local H = 'lua>tab a>'
local v = 'lua>tab b>'
local l = gui.add_listbox('Ephoria', H, 7, true, { '<--Global-->', '<--Rage-->',  '<--AntiAim-->', '<--Visuals-->', '<--Misc-->', '<--Configs-->' })
local U = gui.add_textbox('Text Solus', v)
local Y = gui.add_checkbox('Color Widgets', v)
local M = gui.add_colorpicker(v .. 'Color Widgets', false)
local F = gui.add_button('Ephoria Discord', v, function()
    utils.print_console('\n[Ephoria] ', M:get_color())
    utils.print_console('https://discord.gg/95UTu8Vp. Copied link to clipboard.', render.color('#ffffff'))
    k.set('https://discord.gg/95UTu8Vp')
end)

local AA = gui.add_slider("Roll AA", "lua>Tab B", -200, 199, 0)
local lean_cfg = safe_get_config_item("rage>Anti-Aim>Desync>Lean Amount")
function on_paint_traverse()
    local lean = AA:get_int()
    lean_cfg:set_int(lean)
end

function checkinghome()
    local k_idx = l:get_int()
    safe_set_visible(v .. 'Text Solus', k_idx == 0)
    safe_set_visible(v .. 'Color Widgets', k_idx == 0)
    safe_set_visible(v .. 'Ephoria Discord', k_idx == 0)
end
function checkingconfigs()
    local k_idx = l:get_int()
    safe_set_visible(v .. 'Import Config', k_idx == 5)
    safe_set_visible(v .. 'Export Config', k_idx == 5)
end

local T = gui.add_checkbox('Dormant Aimbot', v)
gui.add_keybind(v .. 'Dormant Aimbot')
local z = gui.add_checkbox('Custom Resolver', v)
gui.add_keybind(v .. 'Custom Resolver')
local R = safe_get_config_item('Rage>Anti-Aim>Desync>Leg Slide')
local h = gui.add_checkbox('Legbreaker', v)
local y = gui.add_checkbox('Hitlog console', v)
function dormantaimbot()
    local k_cfg = safe_get_config_item('rage>aimbot>aimbot>target dormant')
    if not engine.is_in_game() then return end
    if T:get_bool() then
        k_cfg:set_bool(true)
    else
        k_cfg:set_bool(false)
    end
end
function rollresolve()
    local k_cfg = safe_get_config_item('rage>aimbot>aimbot>resolver mode')
    if not engine.is_in_game() then return end
    if z:get_bool() then
        k_cfg:set_int(0)
    else
        k_cfg:set_int(1)
    end
end
local u = utils.new_timer(31, function() if h:get_bool() then R:set_int(1) end end)
u:start()
local E = utils.new_timer(50, function() if h:get_bool() then R:set_int(2) end end)
E:start()
function on_shot_registered(k_shot)
    if not y:get_bool() then return end
    if not k_shot or k_shot.manual then return end
    utils.print_console('\n[Ephoria] ', M:get_color())
    local target_ent = entities.get_entity(k_shot.target)
    if not target_ent then return end
    local pinfo = target_ent:get_player_info()
    if not pinfo then return end
    utils.print_console(string.format('Fired at: %s | HC: %i | ED: %i | AD: %i | Result: %s | BT: %i | SP: %s | Roll SP: %s | Mismatched: %s\n', 
        pinfo.name or "unknown", k_shot.hitchance or 0, k_shot.client_damage or 0, k_shot.server_damage or 0,
        tostring(k_shot.result or ""), k_shot.backtrack or 0, tostring(k_shot.secure or false), tostring(k_shot.very_secure or false), 
        tostring(k_shot.client_hitgroup ~= k_shot.server_hitgroup)), render.color('#ffffff'))
end
function checkingrage()
    local k_idx = l:get_int()
    safe_set_visible(v .. 'Dormant Aimbot', k_idx == 1)
    safe_set_visible(v .. 'Custom Resolver', k_idx == 1)
    safe_set_visible(v .. 'Hitlog console', k_idx == 1)
end

local n = gui.add_checkbox('Anti-Aim Inverter', v)
gui.add_keybind(v .. 'Anti-Aim Inverter')
local x = gui.add_checkbox('Fake Flick', v)
gui.add_keybind(v .. 'Fake Flick')
local C = gui.add_checkbox('Enabled AA', v)
local o = gui.add_combo('Choose AntiAim', v, { 'AntiAim Presets', 'AntiAim Builder' })
local a = gui.add_combo('Choose Presets', v, { 'Default', 'Public', 'Small Jitter', 'Meta Preset', 'Shaitan Preset' })
local w = gui.add_combo('Choose AntiAim Condition:', v, { 'None', 'Standing', 'Moving', 'Slow Walking', 'Crouching', 'In Air' })
local S = gui.add_checkbox('[S] Jitter', v)
local q = gui.add_slider('[S] Jitter Range', v, 0, 360, 0)
local I = gui.add_checkbox('[S] Yaw Toggle', v)
local L = gui.add_slider('[S] Yaw Range', v, -180, 180, 0)
local K = gui.add_checkbox('[S] Fake Toggle', v)
local X = gui.add_slider('[S] Fake Amount', v, -100, 100, 0)
local Z = gui.add_slider('[S] Compensate Angle', v, 0, 100, 0)
local Q = gui.add_checkbox('[S] Flip Fake With Jitter', v)
local W = gui.add_checkbox('[M] Jitter', v)
local f = gui.add_slider('[M] Jitter Range', v, 0, 360, 0)
local B = gui.add_checkbox('[M] Yaw Toggle', v)
local A = gui.add_slider('[M] Yaw Range', v, -180, 180, 0)
local P = gui.add_checkbox('[M] Fake Toggle', v)
local d = gui.add_slider('[M] Fake Amount', v, -100, 100, 0)
local t = gui.add_slider('[M] Compensate Angle', v, 0, 100, 0)
local V = gui.add_checkbox('[M] Flip Fake With Jitter', v)
local e = gui.add_checkbox('[SW] Jitter', v)
local p = gui.add_slider('[SW] Jitter Range', v, 0, 360, 0)
local J = gui.add_checkbox('[SW] Yaw Toggle', v)
local G = gui.add_slider('[SW] Yaw Range', v, -180, 180, 0)
local i = gui.add_checkbox('[SW] Fake Toggle', v)
local kU = gui.add_slider('[SW] Fake Amount', v, -100, 100, 0)
local jU = gui.add_slider('[SW] Compensate Angle', v, 0, 100, 0)
local sU = gui.add_checkbox('[SW] Flip Fake With Jitter', v)
local cU = gui.add_checkbox('[C] Jitter', v)
local NU = gui.add_slider('[C] Jitter Range', v, 0, 360, 0)
local mU = gui.add_checkbox('[C] Yaw Toggle', v)
local DU = gui.add_slider('[C] Yaw Range', v, -180, 180, 0)
local HU = gui.add_checkbox('[C] Fake Toggle', v)
local vU = gui.add_slider('[C] Fake Amount', v, -100, 100, 0)
local lU = gui.add_slider('[C] Compensate Angle', v, 0, 100, 0)
local UU = gui.add_checkbox('[C] Flip Fake With Jitter', v)
local YU = gui.add_checkbox('[A] Jitter', v)
local MU = gui.add_slider('[A] Jitter Range', v, 0, 360, 0)
local FU = gui.add_checkbox('[A] Yaw Toggle', v)
local OU = gui.add_slider('[A] Yaw Range', v, -180, 180, 0)
local TU = gui.add_checkbox('[A] Fake Toggle', v)
local zU = gui.add_slider('[A] Fake Amount', v, -100, 100, 0)
local RU = gui.add_slider('[A] Compensate Angle', v, 0, 100, 0)
local hU = gui.add_checkbox('[A] Flip Fake With Jitter', v)
local yU = false
local bU = safe_get_config_item('Rage>Anti-Aim>Desync>Fake Amount')
function Inverting()
    if n:get_bool() then
        yU = true
        if yU == true then
            bU:set_int(bU:get_int() * -1)
            n:set_bool(false)
            yU = false
        end
    end
    if not n:get_bool() then yU = false end
end
local uU = safe_get_config_item('Rage>Anti-Aim>Angles>Add')
local EU = safe_get_config_item('Rage>Anti-Aim>Desync>Fake Amount')
function fl()
    if x:get_bool() then
        if global_vars.tickcount % 19 == 13 and EU:get_int() >= 0 then
            uU:set_int(95)
        else
            if global_vars.tickcount % 19 == 13 and 0 >= EU:get_int() then uU:set_int(-95) end
        end
    end
end
local xU = safe_get_config_item('rage>anti-aim>angles>jitter')
local CU = safe_get_config_item('rage>anti-aim>angles>jitter range')
local gU = safe_get_config_item('rage>anti-aim>desync>fake')
local oU = safe_get_config_item('rage>anti-aim>desync>fake amount')
local aU = safe_get_config_item('rage>anti-aim>desync>compensate angle')
local wU = safe_get_config_item('rage>anti-aim>desync>freestand fake')
local SU = safe_get_config_item('rage>anti-aim>desync>flip fake with jitter')
local qU = safe_get_config_item('rage>anti-aim>angles>yaw add')
local IU = safe_get_config_item('rage>anti-aim>angles>add')
local rU = safe_get_config_item('misc>movement>slide')
function aa_presets()
    local enabled = C:get_bool()
    if enabled == true then
        if o:get_int() == 0 then
            local lp = entities.get_entity(engine.get_local_player())
            if not lp or not lp:is_valid() or not lp:is_alive() then return end
            local j_flags = lp:get_prop('m_fFlags') or 0
            local s_air = lp:get_prop('m_hGroundEntity') == -1
            local vx, vy, vz, m_speed = get_velocity(lp)
            local D_crouch = input.is_key_down(17)
            if a:get_int() == 1 then
                if m_speed > 2 and (not s_air and not D_crouch) then
                    xU:set_bool(true)
                    CU:set_int(13)
                    gU:set_bool(true)
                    oU:set_int(65)
                    aU:set_int(83)
                    wU:set_int(1)
                    qU:set_bool(true)
                    IU:set_int(-5)
                elseif m_speed <= 2 and j_flags == 257 then
                    xU:set_bool(true)
                    CU:set_int(6)
                    gU:set_bool(true)
                    oU:set_int(100)
                    aU:set_int(65)
                    wU:set_int(1)
                    qU:set_bool(true)
                    IU:set_int(0)
                elseif D_crouch then
                    xU:set_bool(true)
                    CU:set_int(8)
                    gU:set_bool(true)
                    oU:set_int(53)
                    aU:set_int(78)
                    wU:set_int(1)
                    qU:set_bool(true)
                    IU:set_int(3)
                elseif s_air and j_flags ~= 262 then
                    xU:set_bool(true)
                    CU:set_int(20)
                    gU:set_bool(true)
                    oU:set_int(85)
                    aU:set_int(34)
                    wU:set_int(1)
                    qU:set_bool(true)
                    IU:set_int(0)
                end
            else
                if a:get_int() == 2 then
                    if m_speed > 2 and (not s_air and not D_crouch) then
                        xU:set_bool(true)
                        CU:set_int(20)
                        gU:set_bool(true)
                        oU:set_int(77)
                        aU:set_int(54)
                        wU:set_int(1)
                        qU:set_bool(true)
                        IU:set_int(0)
                    elseif m_speed <= 2 and j_flags == 257 then
                        xU:set_bool(true)
                        CU:set_int(5)
                        gU:set_bool(true)
                        oU:set_int(50)
                        aU:set_int(31)
                        wU:set_int(1)
                        qU:set_bool(true)
                        IU:set_int(15)
                    elseif D_crouch then
                        xU:set_bool(true)
                        CU:set_int(3)
                        gU:set_bool(true)
                        oU:set_int(53)
                        aU:set_int(78)
                        wU:set_int(1)
                        qU:set_bool(true)
                        IU:set_int(3)
                    elseif s_air and j_flags ~= 262 then
                        xU:set_bool(true)
                        CU:set_int(23)
                        gU:set_bool(true)
                        oU:set_int(45)
                        aU:set_int(67)
                        wU:set_int(1)
                        qU:set_bool(true)
                        IU:set_int(2)
                    end
                elseif a:get_int() == 3 then
                    xU:set_bool(true)
                    CU:set_int(52)
                    gU:set_bool(true)
                    oU:set_int(83)
                    aU:set_int(74)
                    wU:set_int(1)
                    qU:set_bool(true)
                    IU:set_int(8)
                end
            end
        end
    end
end
function aa_presetstwo()
    local enabled = C:get_bool()
    if enabled == true then
        if o:get_int() == 0 then
            local lp = entities.get_entity(engine.get_local_player())
            if not lp or not lp:is_valid() or not lp:is_alive() then return end
            local j_flags = lp:get_prop('m_fFlags') or 0
            local s_air = lp:get_prop('m_hGroundEntity') == -1
            local vx, vy, vz, m_speed = get_velocity(lp)
            local D_crouch = input.is_key_down(17)
            if a:get_int() == 4 then
                if m_speed > 2 and (not s_air and not D_crouch) then
                    xU:set_bool(true)
                    CU:set_int(36)
                    gU:set_bool(true)
                    oU:set_int(80)
                    aU:set_int(100)
                    wU:set_int(1)
                    qU:set_bool(true)
                    IU:set_int(-23)
                elseif m_speed <= 2 and j_flags == 257 then
                    xU:set_bool(true)
                    CU:set_int(15)
                    gU:set_bool(true)
                    oU:set_int(75)
                    aU:set_int(100)
                    wU:set_int(1)
                    qU:set_bool(true)
                    IU:set_int(-5)
                elseif D_crouch then
                    xU:set_bool(true)
                    CU:set_int(24)
                    gU:set_bool(true)
                    oU:set_int(100)
                    aU:set_int(72)
                    wU:set_int(1)
                    qU:set_bool(true)
                    IU:set_int(-8)
                elseif s_air and j_flags ~= 262 then
                    xU:set_bool(true)
                    CU:set_int(15)
                    gU:set_bool(true)
                    oU:set_int(41)
                    aU:set_int(64)
                    wU:set_int(1)
                    qU:set_bool(true)
                    IU:set_int(16)
                end
            end
        end
    end
end
function get_cond()
    local lp = entities.get_entity(engine.get_local_player())
    if not lp or not lp:is_valid() then return 'STAND' end
    local j_flags = lp:get_prop('m_fFlags') or 0
    local s_air = lp:get_prop('m_hGroundEntity') == -1
    local vx, vy, vz, m_speed = get_velocity(lp)
    local D_crouch = input.is_key_down(17)
    if m_speed > 2 and not s_air then
        return 'MOVE'
    elseif m_speed <= 2 and j_flags == 257 then
        return 'STAND'
    elseif s_air and j_flags ~= 262 then
        return 'AIR'
    else
        return 'CROUCH'
    end
end
function antiaimbuilder()
    local enabled = C:get_bool()
    if enabled == true then
        if o:get_int() == 1 then
            local lp = entities.get_entity(engine.get_local_player())
            if not lp or not lp:is_valid() or not lp:is_alive() then return end
            local j_flags = lp:get_prop('m_fFlags') or 0
            local s_air = lp:get_prop('m_hGroundEntity') == -1
            local vx, vy, vz, m_speed = get_velocity(lp)
            local D_crouch = input.is_key_down(17)
            if m_speed > 2 and (not s_air and not D_crouch) then
                xU:set_bool(W:get_bool())
                CU:set_int(f:get_int())
                gU:set_bool(P:get_bool())
                oU:set_int(d:get_int())
                aU:set_int(t:get_int())
                qU:set_bool(B:get_bool())
                IU:set_int(A:get_int())
                SU:set_bool(V:get_bool())
            elseif m_speed <= 2 and j_flags == 257 then
                xU:set_bool(S:get_bool())
                CU:set_int(q:get_int())
                gU:set_bool(K:get_bool())
                oU:set_int(X:get_int())
                aU:set_int(Z:get_int())
                qU:set_bool(I:get_bool())
                IU:set_int(L:get_int())
                SU:set_bool(Q:get_bool())
            elseif D_crouch then
                xU:set_bool(cU:get_bool())
                CU:set_int(NU:get_int())
                gU:set_bool(HU:get_bool())
                oU:set_int(vU:get_int())
                aU:set_int(lU:get_int())
                qU:set_bool(mU:get_bool())
                IU:set_int(DU:get_int())
                SU:set_bool(UU:get_bool())
            elseif s_air then
                xU:set_bool(YU:get_bool())
                CU:set_int(MU:get_int())
                gU:set_bool(TU:get_bool())
                oU:set_int(zU:get_int())
                aU:set_int(RU:get_int())
                qU:set_bool(FU:get_bool())
                IU:set_int(OU:get_int())
                SU:set_bool(hU:get_bool())
            end
        end
    end
end
function checkingantiaim()
    local k_idx = l:get_int()
    local j_en = C:get_bool()
    local s_opt = o:get_int()
    local c_cond = w:get_int()
    safe_set_visible(v .. 'Anti-Aim Inverter', k_idx == 2)
    safe_set_visible(v .. 'Fake Flick', k_idx == 2)
    safe_set_visible(v .. 'Legbreaker', k_idx == 2)
    safe_set_visible(v .. 'Enabled AA', k_idx == 2)
    safe_set_visible(v .. 'Choose AntiAim', k_idx == 2 and j_en == true)
    safe_set_visible(v .. 'Choose Presets', k_idx == 2 and (j_en == true and s_opt == 0))
    safe_set_visible(v .. 'Choose AntiAim Condition:', k_idx == 2 and (j_en == true and s_opt == 1))
    safe_set_visible(v .. '[S] Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 1)))
    safe_set_visible(v .. '[S] Jitter Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 1)))
    safe_set_visible(v .. '[S] Yaw Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 1)))
    safe_set_visible(v .. '[S] Yaw Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 1)))
    safe_set_visible(v .. '[S] Fake Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 1)))
    safe_set_visible(v .. '[S] Fake Amount', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 1)))
    safe_set_visible(v .. '[S] Compensate Angle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 1)))
    safe_set_visible(v .. '[S] Flip Fake With Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 1)))
    safe_set_visible(v .. '[M] Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 2)))
    safe_set_visible(v .. '[M] Jitter Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 2)))
    safe_set_visible(v .. '[M] Yaw Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 2)))
    safe_set_visible(v .. '[M] Yaw Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 2)))
    safe_set_visible(v .. '[M] Fake Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 2)))
    safe_set_visible(v .. '[M] Fake Amount', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 2)))
    safe_set_visible(v .. '[M] Compensate Angle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 2)))
    safe_set_visible(v .. '[M] Flip Fake With Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 2)))
    safe_set_visible(v .. '[SW] Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 3)))
    safe_set_visible(v .. '[SW] Jitter Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 3)))
    safe_set_visible(v .. '[SW] Yaw Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 3)))
    safe_set_visible(v .. '[SW] Yaw Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 3)))
    safe_set_visible(v .. '[SW] Fake Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 3)))
    safe_set_visible(v .. '[SW] Fake Amount', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 3)))
    safe_set_visible(v .. '[SW] Compensate Angle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 3)))
    safe_set_visible(v .. '[SW] Flip Fake With Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 3)))
    safe_set_visible(v .. '[C] Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 4)))
    safe_set_visible(v .. '[C] Jitter Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 4)))
    safe_set_visible(v .. '[C] Yaw Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 4)))
    safe_set_visible(v .. '[C] Yaw Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 4)))
    safe_set_visible(v .. '[C] Fake Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 4)))
    safe_set_visible(v .. '[C] Fake Amount', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 4)))
    safe_set_visible(v .. '[C] Compensate Angle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 4)))
    safe_set_visible(v .. '[C] Flip Fake With Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 4)))
    safe_set_visible(v .. '[A] Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 5)))
    safe_set_visible(v .. '[A] Jitter Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 5)))
    safe_set_visible(v .. '[A] Yaw Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 5)))
    safe_set_visible(v .. '[A] Yaw Range', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 5)))
    safe_set_visible(v .. '[A] Fake Toggle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 5)))
    safe_set_visible(v .. '[A] Fake Amount', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 5)))
    safe_set_visible(v .. '[A] Compensate Angle', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 5)))
    safe_set_visible(v .. '[A] Flip Fake With Jitter', k_idx == 2 and (j_en == true and (s_opt == 1 and c_cond == 5)))
end

local LU, KU, XU = gui.add_multi_combo('Visual Items', v, { 'Watermark', 'Keybinds', 'Info Tab' })
local ZU = gui.add_combo('UI | Type', v, { 'Gamesense Style v1', 'Gamesense Style v2' })
local QU = gui.add_checkbox('Indicators Under Crosshair', v)
local WU = gui.add_combo('Indicators Style', v, { 'Ephoria (Pixel)', 'Ephoria (New)' })
local fU = gui.add_checkbox('Skeet Indicators', v)
local BU = gui.add_combo('Info Panel | Flag', v, { 'Russia', 'Germany', 'Estonia', 'Romania', 'Reichsflagge' })
local AU = render.font_esp

function render.window(k, j, s, c, N, m, D, H)
    if ZU:get_int() == 0 then
        render.rect_filled(k, j, s, c, render.color(39, 39, 39, 255 * H))
        render.rect_filled(k + 1, j + 1, s - 1, c - 1, render.color(25, 25, 25, 255 * H))
    end
    if ZU:get_int() == 1 then
        render.rect_filled_rounded(k, j, s, c, render.color(0, 0, 0, 105 * H), 2, render.all)
        render.rect_filled(k, j, s, j + 1, render.color(N, m, D, 255 * H))
        render.rect_filled_multicolor(k - 1, j + 1, k, c, render.color(N, m, D, 255 * H), render.color(N, m, D, 255 * H), render.color(0, 0, 0, 0), render.color(0, 0, 0, 0))
        render.rect_filled_multicolor(s, j + 1, s + 1, c, render.color(N, m, D, 255 * H), render.color(N, m, D, 255 * H), render.color(0, 0, 0, 0), render.color(0, 0, 0, 0))
    end
end

function accumulate_fps()
    local ft = global_vars.frametime
    if not ft or ft <= 0 then return 0 end
    return math.ceil(1 / ft)
end

function get_tick()
    if not engine.is_in_game() then return 64 end
    local ipt = global_vars.interval_per_tick
    if not ipt or ipt <= 0 then return 64 end
    return math.floor(1 / ipt)
end

function watermark()
    if LU:get_bool() then
        local PU, dU = render.get_screen_size()
        local k_w, j_h = render.get_text_size(AU, 'Ephoria')
        local s_w, c_h = render.get_text_size(AU, ' | ' .. (U:get_string() .. ' | debug build'))
        local N_w, m_h = render.get_text_size(AU, 'Ephoria | ' .. (U:get_string() .. ' | https://fakecri.me/@ephoriacodes'))
        local D_alpha = 255
        render.window((PU / 2 - N_w / 2) - 4, dU - 21, (PU / 2 + N_w / 2) + 4, dU - 1, (M:get_color()).r, (M:get_color()).g, (M:get_color()).b, 1)
        for s_idx = 1, 10, 1 do
            render.rect_filled_rounded((PU / 2 - N_w / 2) - s_idx, (dU - 14) - s_idx, ((PU / 2 - N_w / 2) + k_w) + s_idx, ((dU - 14) + j_h / 2) + s_idx,
                render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, (20 - 2 * s_idx) * .35), 10)
        end
        render.text(AU, PU / 2 - N_w / 2, dU - 14, 'Ephoria', render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, 255))
        render.text(AU, (PU / 2 - N_w / 2) + k_w, dU - 14, ' | ' .. (U:get_string() .. ' | https://fakecri.me/@ephoriacodes'), render.color(98, 98, 98, 255))
    end
end

local tU = { 
    { text = 'SPOOFER CORD AA', path = 'lua>tab b>skeet indicators' }, 
    { text = 'FD', path = 'misc>movement>fake duck' }, 
    { text = 'DT', path = 'rage>aimbot>aimbot>double tap' },
    { text = 'HS-DOGS', path = 'rage>aimbot>aimbot>hide shot' }, 
    { text = 'FS', path = 'rage>anti-aim>angles>freestand' }, 
    { text = 'HS', path = 'rage>aimbot>aimbot>headshot only' },
    { text = 'Roll', path = 'rage>anti-aim>desync>ensure lean' }, 
    { text = 'DA', path = 'rage>aimbot>aimbot>Target dormant' }, 
    { text = 'AX', path = 'rage>aimbot>aimbot>Anti-exploit' }, 
    { text = 'NIGHTLY', path = 'lua>tab b>enabled aa' } 
}

local VU = function()
    local lp = entities.get_entity(engine.get_local_player())
    local vx, vy, vz, m_speed = get_velocity(lp)
    return m_speed
end

local eU = function()
    local res = {}
    for j_idx, s_item in pairs(tU) do 
        if (safe_get_config_item(s_item.path)):get_bool() then 
            table.insert(res, s_item.text) 
        end 
    end
    return res
end

local JU = function(k, j, s) return math.floor(k + (j - k) * s) end
local GU = { 0, 0, 0, 0, 0 }

local iU = render.font_esp
if render.create_font then
    local ok, res = pcall(render.create_font, 'calibrib.ttf', 23, render.font_flag_shadow)
    if ok and res and res ~= -1 then iU = res end
end
if iU == render.font_esp and render.create_font_gdi then
    local ok, res = pcall(render.create_font_gdi, 'Calibri', 23, render.font_flag_shadow)
    if ok and res and res ~= -1 then iU = res end
end

function skeetind()
    if fU:get_bool() then
        local lp = entities.get_entity(engine.get_local_player())
        if not lp or not lp:is_valid() then return end
        local scr_w, scr_h = render.get_screen_size()
        add_y = 0
        if info.fatality.can_fastfire then
            GU[1] = JU(GU[1], 255, global_vars.frametime * 11)
            add_y = add_y + 7
        else
            if GU[1] > 0 then add_y = add_y + 7 end
            GU[1] = JU(GU[1], 0, global_vars.frametime * 11)
        end
        local s_anim = j.anim_new('m_bIsScoped add dbbx2', info.fatality.can_fastfire and 1 or .01)
        local c_lean = safe_get_config_item('rage>anti-aim>desync>lean amount')
        local N_lean = (c_lean:get_int() / 100) * 2
        local m_col = info.fatality.can_fastfire and render.color(255, 255, 255, GU[1]) or render.color(226, 54, 55, 255)
        for k_idx, c_text in pairs(eU()) do
            local D_pos = { x = 10, y = (scr_h / 2 + 98) + 35 * (k_idx - 1) }
            local H_rnd = utils.random_int(15, 100) / 100
            local v_anim = j.anim_new('aainverted1xq34', fU:get_bool() and utils.random_int(15, 100) / 100 or 0)
            local l_col = render.color(150, 200, 30)
            if c_text == 'SPOOFER CORD AA' then
                l_col = render.color(151, 193, 48)
                render.circle(D_pos.x + 200, D_pos.y + 10, 5, render.color(0, 0, 0, 255), 3, 22, 1, 1)
                render.circle(D_pos.x + 200, D_pos.y + 10, 5, render.color(151, 193, 48, 255), 3, 12, H_rnd, 1)
            end
            if c_text == 'DT' then
                l_col = m_col
                render.circle(D_pos.x + 44, D_pos.y + 10, 5, render.color(0, 0, 0, 255), 3, 22, 1, 1)
                render.circle(D_pos.x + 44, D_pos.y + 10, 5, m_col, 3, 12, s_anim, 1)
            end
            if c_text == 'HS-DOGS' then 
                local hs_cfg = safe_get_config_item('rage>aimbot>aimbot>hide shot')
                if not hs_cfg:get_bool() then l_col = render.color(125, 130, 209) end 
            end
            if c_text == 'Roll' then
                l_col = render.color(232, 113, 111)
                render.circle(D_pos.x + 68, D_pos.y + 10, 5, render.color(0, 0, 0, 255), 3, 22, 1, 1)
                render.circle(D_pos.x + 68, D_pos.y + 10, 5, render.color(232, 113, 111, 255), 3, 12, N_lean, 1)
            end
            local U_alpha = math.floor(math.abs(math.sin(global_vars.realtime) * 2) * 255)
            if c_text == 'NIGHTLY' then l_col = render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, U_alpha) end
            local Y_w, Y_h = render.get_text_size(iU, c_text)
            for k_iter = 1, 10, 1 do 
                render.rect_filled_rounded((D_pos.x + 4) - k_iter, D_pos.y - k_iter, ((D_pos.x + Y_w) + 8) + k_iter, ((D_pos.y + Y_h) - 3) + k_iter, render.color(l_col.r, l_col.g, l_col.b, (20 - 2 * k_iter) * .35), 10) 
            end
            render.text(iU, D_pos.x + 8, D_pos.y, c_text, l_col)
        end
    end
end

function gui_controller()
    local k_title = 'Ephoria'
    local j_font = render.font_esp
    local s_user = U:get_string()
    local c_w, N_h = render.get_text_size(j_font, k_title)
    local m_text = 'user: ' .. (s_user .. '')
    local D_w, H_h = render.get_text_size(j_font, m_text)
    local v_w, l_h = render.get_text_size(j_font, ' [Ephoria]')
    local Y_flag = BU:get_int()
    local F_alpha = math.floor(math.abs(math.sin(global_vars.realtime) * 2) * 255)
    local O_w, T_h = render.get_screen_size()
    if XU:get_bool() then
        render.window(7, (T_h / 2 + 35) + 2, (65 + D_w) + v_w, (T_h / 2 + 37) + 34, (M:get_color()).r, (M:get_color()).g, (M:get_color()).b, 1)
        render.text(j_font, 52, T_h / 2 + 43, 'Version: Nightly', render.color(255, 255, 255, 255))
        render.text(j_font, 52, T_h / 2 + 56, 'user: ' .. (s_user .. ''), render.color(255, 255, 255, 255))
        render.text(j_font, 52 + D_w, T_h / 2 + 56, ' [Ephoria]', render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, F_alpha))
        if Y_flag == 0 then
            render.rect_filled(12, T_h / 2 + 42, 45, T_h / 2 + 49, render.color(255, 255, 255, 255))
            render.rect_filled(12, T_h / 2 + 49, 45, T_h / 2 + 56, render.color(28, 53, 120, 255))
            render.rect_filled(12, T_h / 2 + 56, 45, T_h / 2 + 65, render.color(228, 24, 28, 255))
        end
        if Y_flag == 1 then
            render.rect_filled(12, T_h / 2 + 42, 45, T_h / 2 + 49, render.color(0, 0, 0, 255))
            render.rect_filled(12, T_h / 2 + 49, 45, T_h / 2 + 56, render.color(221, 0, 0, 255))
            render.rect_filled(12, T_h / 2 + 56, 45, T_h / 2 + 65, render.color(255, 204, 0, 255))
        end
        if Y_flag == 2 then
            render.rect_filled(12, T_h / 2 + 42, 45, T_h / 2 + 49, render.color(0, 114, 206, 255))
            render.rect_filled(12, T_h / 2 + 49, 45, T_h / 2 + 56, render.color(0, 0, 0, 255))
            render.rect_filled(12, T_h / 2 + 56, 45, T_h / 2 + 65, render.color(255, 255, 255, 255))
        end
        if Y_flag == 3 then
            render.rect_filled(12, T_h / 2 + 42, 45, T_h / 2 + 49, render.color(0, 43, 127, 255))
            render.rect_filled(12, T_h / 2 + 49, 45, T_h / 2 + 56, render.color(252, 209, 22, 255))
            render.rect_filled(12, T_h / 2 + 56, 45, T_h / 2 + 65, render.color(206, 17, 38, 255))
        end
        if Y_flag == 4 then
            render.rect_filled(12, T_h / 2 + 42, 45, T_h / 2 + 49, render.color(0, 0, 0, 255))
            render.rect_filled(12, T_h / 2 + 49, 45, T_h / 2 + 56, render.color(255, 255, 255, 255))
            render.rect_filled(12, T_h / 2 + 56, 45, T_h / 2 + 65, render.color(255, 17, 0, 255))
        end
    end
end

local sw_init, sh_init = render.get_screen_size()
sw_init = (sw_init and sw_init > 0) and sw_init or 1920
sh_init = (sh_init and sh_init > 0) and sh_init or 1080
local jC = gui.add_slider('keybinds_x', v, 0, sw_init, 1)
local sC = gui.add_slider('keybinds_y', v, 0, sh_init, 1)
safe_set_visible(v .. 'keybinds_x', false)
safe_set_visible(v .. 'keybinds_y', false)

function animate(k, j, s, c, N, m)
    c = (c * global_vars.frametime) * 20
    if N == false then
        if j then
            k = k + c
        else
            k = k - c
        end
    else
        if j then
            k = k + (s - k) * (c / 100)
        else
            k = k - (0 + k) * (c / 100)
        end
    end
    if m then
        if k > s then
            k = s
        elseif k < 0 then
            k = 0
        end
    end
    return k
end

function drag(k, j, s, c)
    local N, m = input.get_cursor_pos()
    local D = false
    if input.is_key_down(1) then
        if N > k:get_int() and (m > j:get_int() and (N < k:get_int() + s and m < j:get_int() + c)) then D = true end
    else
        D = false
    end
    if D then
        k:set_int(N - s / 2)
        j:set_int(m - c / 2)
    end
end

function on_keybinds()
    if not KU:get_bool() then return end
    local k_pos = { jC:get_int(), sC:get_int() }
    local j_offset = 0
    local s = { 
        (safe_get_config_item('rage>aimbot>aimbot>double tap')):get_bool(), 
        (safe_get_config_item('rage>aimbot>aimbot>hide shot')):get_bool(),
        (safe_get_config_item('rage>aimbot>ssg08>scout>override')):get_bool(), 
        (safe_get_config_item('rage>aimbot>aimbot>headshot only')):get_bool(),
        (safe_get_config_item('misc>movement>fake duck')):get_bool() 
    }
    local c_names = { 'Doubletap', 'On-shot ', 'Override Damage', 'Head', 'Duck-peek ', 'Head' }
    if not s[4] then
        if not s[5] then
            if not s[3] then
                if not s[1] then
                    if not s[6] then
                        if not s[2] then
                            j_offset = 0
                        else
                            j_offset = 38
                        end
                    else
                        j_offset = 40
                    end
                else
                    j_offset = 41
                end
            else
                j_offset = 54
            end
        else
            j_offset = 63
        end
    else
        j_offset = 70
    end
    animated_size_offset = animate(animated_size_offset or 0, true, j_offset, 60, true, false)
    local N_size = { 80 + animated_size_offset, 21 }
    local m_status = 'enabled'
    local D_status_w = render.get_text_size(AU, m_status) + 7
    local H_active = s[3] or s[4] or s[5] or s[6] or s[7] or s[8]
    local v_active = s[1] or s[2] or s[9] or s[10] or s[11]
    drag(jC, sC, N_size[1], N_size[2])
    local l_col = math.floor(math.abs(math.sin(global_vars.realtime) * 2) * 255)
    alpha = animate(alpha or 0, gui.is_menu_open() or H_active or v_active, 1, .5, false, true)
    local U_title_w, Y_title_h = render.get_text_size(AU, 'keybinds')
    render.window(k_pos[1], k_pos[2], k_pos[1] + N_size[1], k_pos[2] + N_size[2], (M:get_color()).r, (M:get_color()).g, (M:get_color()).b, alpha)
    for j_iter = 1, 10, 1 do
        render.rect_filled_rounded((((k_pos[1] + N_size[1] / 2) - U_title_w / 2) - 1) - j_iter, (k_pos[2] + 7) - j_iter, (((k_pos[1] + N_size[1] / 2) + U_title_w / 2) - 1) + j_iter,
            ((k_pos[2] + 4) + Y_title_h) + j_iter, render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, (20 - 2 * j_iter) * (alpha - .65)), 10)
    end
    render.text(AU, ((k_pos[1] + N_size[1] / 2) - U_title_w / 2) - 1, k_pos[2] + 7, 'keybinds', render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, 255 * alpha))
    local F_line = 0
    dt_alpha = animate(dt_alpha or 0, s[1], 1, .5, false, true)
    render.text(AU, k_pos[1] + 6, (k_pos[2] + N_size[2]) + 2, c_names[1], render.color(255, 255, 255, 255 * dt_alpha))
    render.text(AU, (k_pos[1] + N_size[1]) - D_status_w, (k_pos[2] + N_size[2]) + 2, m_status, render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, (M:get_color()).a * dt_alpha))
    if s[1] then F_line = F_line + 11 end
    hs_alpha = animate(hs_alpha or 0, s[2], 1, .5, false, true)
    render.text(AU, k_pos[1] + 6, ((k_pos[2] + N_size[2]) + 2) + F_line, c_names[2], render.color(255, 255, 255, 255 * hs_alpha))
    render.text(AU, (k_pos[1] + N_size[1]) - D_status_w, ((k_pos[2] + N_size[2]) + 2) + F_line, m_status, render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, (M:get_color()).a * hs_alpha))
    if s[2] then F_line = F_line + 11 end
    dmg_alpha = animate(dmg_alpha or 0, s[3], 1, .5, false, true)
    render.text(AU, k_pos[1] + 6, ((k_pos[2] + N_size[2]) + 2) + F_line, c_names[3], render.color(255, 255, 255, 255 * dmg_alpha))
    render.text(AU, (k_pos[1] + N_size[1]) - D_status_w, ((k_pos[2] + N_size[2]) + 2) + F_line, m_status, render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, (M:get_color()).a * dmg_alpha))
    if s[3] then F_line = F_line + 11 end
    fs_alpha = animate(fs_alpha or 0, s[4], 1, .5, false, true)
    render.text(AU, k_pos[1] + 6, ((k_pos[2] + N_size[2]) + 2) + F_line, c_names[4], render.color(255, 255, 255, 255 * fs_alpha))
    render.text(AU, (k_pos[1] + N_size[1]) - D_status_w, ((k_pos[2] + N_size[2]) + 2) + F_line, m_status, render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, (M:get_color()).a * fs_alpha))
    if s[4] then F_line = F_line + 11 end
    ho_alpha = animate(ho_alpha or 0, s[5], 1, .5, false, true)
    render.text(AU, k_pos[1] + 6, ((k_pos[2] + N_size[2]) + 2) + F_line, c_names[5], render.color(255, 255, 255, 255 * ho_alpha))
    render.text(AU, (k_pos[1] + N_size[1]) - D_status_w, ((k_pos[2] + N_size[2]) + 2) + F_line, m_status, render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, (M:get_color()).a * ho_alpha))
    if s[5] then F_line = F_line + 11 end
    fd_alpha = animate(fd_alpha or 0, s[6], 1, .5, false, true)
    render.text(AU, k_pos[1] + 6, ((k_pos[2] + N_size[2]) + 2) + F_line, c_names[6], render.color(255, 255, 255, 255 * fd_alpha))
    render.text(AU, (k_pos[1] + N_size[1]) - D_status_w, ((k_pos[2] + N_size[2]) + 2) + F_line, m_status, render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, (M:get_color()).a * fd_alpha))
end

function checkingwidgets()
    local k_idx = l:get_int()
    local j_tab = XU:get_bool()
    safe_set_visible(v .. 'Visual Items', k_idx == 3)
    safe_set_visible(v .. 'Indicators Under Crosshair', k_idx == 3)
    safe_set_visible(v .. 'Skeet Indicators', k_idx == 3)
    safe_set_visible(v .. 'Indicators Style', k_idx == 3 and QU:get_bool())
    safe_set_visible(v .. 'UI | Type', k_idx == 3 and (LU:get_bool() or KU:get_bool() or XU:get_bool()))
    safe_set_visible(v .. 'Info Panel | Flag', k_idx == 3 and j_tab)
end

local cC = gui.add_checkbox('Shadow off', v)
local NC = gui.add_checkbox('Trash Talk', v)
local mC = gui.add_checkbox('Clantag', v)
local DC = gui.add_combo('Clantag Type', v, { 'Ephoria', 'botlucky.com', 'primordial.dev', 'rawetrip', 'onetap.cc', 'gamesense.pub', 'EZfrags.co', 'neverlose.cc', 'ev0lve.xyz', 'pandora.gg' })
local HC = gui.add_checkbox('Aspect Ratio', v)
local vC = gui.add_slider('Aspect Value', v, 1, 200, 1)

local function lC(k, j, s, c)
    if k then
        return j + (((s - j) * global_vars.frametime) * c) / 1.5
    else
        return j - (((s + j) * global_vars.frametime) * c) / 1.5
    end
end
local UC = 0
local YC = 0
local MC = 0
local FC = 0
local OC = { player_states = { 'Standing', 'Moving', 'Slow motion', 'Air', 'Air Duck', 'Crouch' } }
local TC = function(k, j, s) return math.floor(k + (j - k) * s) end
local zC = { 0, 0, 0, 0, 0 }

local RC = render.font_esp
if render.create_font then
    local ok, res = pcall(render.create_font, 'Verdana.ttf', 16, render.font_flag_outline)
    if ok and res and res ~= -1 then RC = res end
end
if RC == render.font_esp and render.create_font_gdi then
    local ok, res = pcall(render.create_font_gdi, 'Verdana', 16, render.font_flag_outline)
    if ok and res and res ~= -1 then RC = res end
end

function indicatorsfunc()
    local lp = entities.get_entity(engine.get_local_player())
    if not lp or not lp:is_valid() or not lp:is_alive() then return end
    if WU:get_int() == 1 then return end
    local is_scoped = lp:get_prop('m_bIsScoped')
    UC = lC(is_scoped, UC, 15, 10)
    add_y = 17
    local c_sin = math.floor(math.abs(math.sin(global_vars.realtime) * 2) * 255)
    local scr_w, scr_h = render.get_screen_size()
    local H_cx = scr_w / 2
    local v_cy = scr_h / 2
    local l_val = 0
    local U_slow = info.fatality.in_slowwalk
    local F_air = lp:get_prop('m_hGroundEntity') == -1
    local vx, vy, vz, m_speed = get_velocity(lp)
    local O_vx = math.floor(vx)
    local T_vy = math.floor(vy)
    local z_slow = m_speed < 5
    local lp_flags = lp:get_prop('m_fFlags') or 0
    local R_duck = bit.band(lp_flags, bit.lshift(2, 0)) ~= 0
    local h_flags = lp_flags

    if QU:get_bool() then
        local font_esp = render.font_esp
        local N_col = info.fatality.can_fastfire and render.color(126, 214, 136, zC[1]) or render.color(226, 54, 55, zC[1])
        local c1 = j.anim_new('aainverted1', info.fatality.can_fastfire and (M:get_color()).r or 255)
        local c2 = j.anim_new('aainverted2', info.fatality.can_fastfire and (M:get_color()).g or 255)
        local c3 = j.anim_new('aainverted3', info.fatality.can_fastfire and (M:get_color()).b or 255)
        local c11 = j.anim_new('aainverted11', info.fatality.can_fastfire and 255 or (M:get_color()).r)
        local c22 = j.anim_new('aainverted22', info.fatality.can_fastfire and 255 or (M:get_color()).g)
        local c33 = j.anim_new('aainverted33', info.fatality.can_fastfire and 255 or (M:get_color()).b)
        local l_scoped1 = j.anim_new('m_bIsScoped add 1', lp:get_prop('m_bIsScoped') and 15 or 0)
        local U_scoped12 = j.anim_new('m_bIsScoped add 12', lp:get_prop('m_bIsScoped') and 24 or 0)
        local z_widget_col = render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, 255)
        local R_widget_dim = render.color((M:get_color()).r - 70, (M:get_color()).g - 90, (M:get_color()).b - 70, 185)
        local h_text = 'EP'
        local y_tw, b_th = render.get_text_size(RC, h_text)
        render.text(RC, ((H_cx - (y_tw - 4)) + l_scoped1) - 4, v_cy + 21, h_text, render.color(c1, c2, c3, 255))
        render.text(RC, ((H_cx + (y_tw - 7)) + l_scoped1) - 6, v_cy + 21, 'H', render.color(c11, c22, c33, 255))
        if info.fatality.can_fastfire then
            zC[1] = TC(zC[1], 255, global_vars.frametime * 11)
            add_y = add_y + 7
        else
            if zC[1] > 0 then add_y = add_y + 7 end
            zC[1] = TC(zC[1], 0, global_vars.frametime * 11)
        end
        local C_dt = j.anim_new('m_bIsScoped add doulbetap', lp:get_prop('m_bIsScoped') and 26 or 0)
        render.text(font_esp, (H_cx - 19) + C_dt, (v_cy + 12) + add_y, 'doubletap', N_col)
        if info.fatality.in_fakeduck then
            zC[2] = TC(zC[2], 255, global_vars.frametime * 11)
            add_y = add_y + 6
        else
            if zC[2] > 0 then add_y = add_y + 6 end
            zC[2] = TC(zC[2], 0, global_vars.frametime * 11)
        end
        local g_fd = j.anim_new('m_bIsScoped add fd', lp:get_prop('m_bIsScoped') and 27 or 0)
        render.text(font_esp, (H_cx - 20) + g_fd, (v_cy + 12) + add_y, 'fake-duck', render.color(137, 174, 255, zC[2]))
        local o_hs = safe_get_config_item('rage>aimbot>aimbot>hide shot')
        if info.fatality.in_slowwalk then
            zC[3] = TC(zC[3], 255, global_vars.frametime * 11)
            add_y = add_y + 6
        else
            if zC[3] > 0 then add_y = add_y + 6 end
            zC[3] = TC(zC[3], 0, global_vars.frametime * 11)
        end
        local a_sw = j.anim_new('m_bIsScoped add sw', lp:get_prop('m_bIsScoped') and 27 or 0)
        render.text(font_esp, (H_cx - 20) + a_sw, (v_cy + 12) + add_y, 'slow-walk', render.color(154, 156, 151, zC[3]))
        if o_hs:get_bool() then
            zC[4] = TC(zC[4], 255, global_vars.frametime * 11)
            add_y = add_y + 6
        else
            if zC[4] > 0 then add_y = add_y + 6 end
            zC[4] = TC(zC[4], 0, global_vars.frametime * 11)
        end
        local w_osaa = j.anim_new('m_bIsScoped add swxxxx', lp:get_prop('m_bIsScoped') and 19 or 0)
        render.text(font_esp, (H_cx - 12) + w_osaa, (v_cy + 12) + add_y, 'os-aa', render.color(176, 114, 196, zC[4]))
    end
end

local hC = { 0, 0, 0, 0, 0 }
local yC = function(k, j, s) return math.floor(k + (j - k) * s) end
function indicators2func()
    local lp = entities.get_entity(engine.get_local_player())
    if not lp or not lp:is_valid() or not lp:is_alive() then return end
    add_y = 0
    if WU:get_int() == 0 then return end
    if QU:get_bool() then
        local s_font = render.font_esp
        local scr_w, scr_h = render.get_screen_size()
        local m_cx = scr_w / 2
        local D_cy = scr_h / 2
        local H_dt_col = info.fatality.can_fastfire and render.color(255, 255, 255, hC[1]) or render.color(226, 54, 55, hC[1])
        local v_scoped = j.anim_new('m_bIsScoped add 12', lp:get_prop('m_bIsScoped') and 30 or 0)
        local l_dbb = j.anim_new('m_bIsScoped add dbb', info.fatality.can_fastfire and 1 or .01)
        local U_title_w, Y_title_h = render.get_text_size(s_font, 'Ephoria')
        for k_iter = 1, 10, 1 do
            render.rect_filled_rounded(((m_cx - U_title_w / 2) + v_scoped) - k_iter, (D_cy + 15) - k_iter, ((m_cx + U_title_w / 2) + v_scoped) + k_iter, ((D_cy + 15) + Y_title_h) + k_iter,
                render.color((M:get_color()).r, (M:get_color()).g, (M:get_color()).b, (20 - 2 * k_iter) * 1), 10)
        end
        local F_fl_w, O_fl_h = render.get_text_size(s_font, 'FAKELAG')
        local cond_str = get_cond()
        local T_cond_w, z_cond_h = render.get_text_size(s_font, cond_str)
        local R_dt_w, h_dt_h = render.get_text_size(s_font, 'DT')
        render.text(s_font, (m_cx - U_title_w / 2) + v_scoped, D_cy + 15, 'Ephoria', render.color(255, 255, 255, 255))
        if info.fatality.can_fastfire then
            hC[1] = yC(hC[1], 255, global_vars.frametime * 11)
            add_y = add_y + 7
            render.text(s_font, (m_cx - T_cond_w / 2) + v_scoped, (D_cy + z_cond_h) + 12, cond_str, M:get_color())
            render.circle_filled(((m_cx - T_cond_w / 2) - 4) + v_scoped, (D_cy + z_cond_h) + 16, 2, render.color(0, 0, 0, 255))
            render.circle_filled(((m_cx - T_cond_w / 2) - 4) + v_scoped, (D_cy + z_cond_h) + 16, 1, M:get_color())
            render.circle_filled(((m_cx + T_cond_w / 2) + 4) + v_scoped, (D_cy + z_cond_h) + 16, 2, render.color(0, 0, 0, 255))
            render.circle_filled(((m_cx + T_cond_w / 2) + 4) + v_scoped, (D_cy + z_cond_h) + 16, 1, M:get_color())
        else
            render.text(s_font, (m_cx - F_fl_w / 2) + v_scoped, (D_cy + O_fl_h) + 12, 'FAKELAG', M:get_color())
            render.circle_filled(((m_cx - F_fl_w / 2) - 4) + v_scoped, (D_cy + O_fl_h) + 16, 2, render.color(0, 0, 0, 255))
            render.circle_filled(((m_cx - F_fl_w / 2) - 4) + v_scoped, (D_cy + O_fl_h) + 16, 1, M:get_color())
            render.circle_filled(((m_cx + F_fl_w / 2) + 4) + v_scoped, (D_cy + O_fl_h) + 16, 2, render.color(0, 0, 0, 255))
            render.circle_filled(((m_cx + F_fl_w / 2) + 4) + v_scoped, (D_cy + O_fl_h) + 16, 1, M:get_color())
            if hC[1] > 0 then add_y = add_y + 7 end
            hC[1] = yC(hC[1], 0, global_vars.frametime * 11)
        end
        render.text(s_font, (m_cx - R_dt_w / 2) + v_scoped, (D_cy + h_dt_h) + 22, 'DT', H_dt_col)
        render.circle((((m_cx - R_dt_w / 2) + v_scoped) + R_dt_w) + 5, (D_cy + h_dt_h) + 26, 3, H_dt_col, 2, 50, l_dbb)
    end
end

local trashtalk_phrases = { 
    'ты понимаешь что я на чердаке твою бабулю повесил своим хуем', 
    'Stfu dog', 
    'Get Ephoria.Lua get good', 
    'я на пизде твоей матери устраивал скачки на конях', 
    'Ephoria fatality best script', 
    '1', 
    'Ephoria.lua Better than luck', 
    'Bye Bye',
    'Sleep ', 
    'Ephoria and never lose again', 
    'пизда твоей матери сняла номер на моем хуе', 
    'bot_kick',  
    'The only thing lower than your k/d ratio is your I.Q', 
    'Ezzz',
}

function on_player_death(k_event)
    if NC:get_bool() then
        local lp_idx = engine.get_local_player()
        local attacker_idx = engine.get_player_for_user_id(k_event:get_int('attacker'))
        local victim_idx = engine.get_player_for_user_id(k_event:get_int('userid'))
        if attacker_idx == lp_idx and victim_idx ~= lp_idx then 
            engine.exec('say ' .. trashtalk_phrases[utils.random_int(1, #trashtalk_phrases)]) 
        end
    end
end

function on_game_event(event)
    if not event then return end
    if event:get_name() == 'player_death' then
        on_player_death(event)
    end
end

local uC = 0
local EC = { '☪E ', '☪Ep ', '☪Eph ', '☪Epho ', '☪Ephori ', '☪Ephoria☪', '☪Ephoria☪', '☪Ephori', '☪Ephor', '☪Epho', '☪Eph', '☪Ep', 
'☪E', '☪Ep', '☪Eph', '☪Epho', '☪Ephor', '☪Ephori ', '☪Ephoria☪', '☪Ephori', '☪Ephor ', '☪Epho ', '☪Eph ', '☪Ep ', 'E☪ ', }
local nC = { '☘', '☘ L', '☘ Lu', '☘ Luc', '☘ Luck', '☘ Lucky', '☘ LuckyC', '☘ LuckyCh', '☘ LuckyChar', '☘ LuckyCharm', '☘ LuckyCharms', '☘ LuckyCharm', '☘ LuckyChar', '☘ LuckyCha', '☘ LuckyCh ', '☘ LuckyC',
'☘ Lucky', '☘ Luck', '☘ Luc', '☘ Lu ', '☘ L ', '☘' }
local iC = { '⌛ p', '⌛ pr', '⌛ pri', '⌛ prim', '⌛ primo', '⌛ primor', '⌛ primord', '⌛ primordi', '⌛ primordia', '⌛ primordia', '⌛ primordial', '⌛ primordial.', '⌛ primordial.', '⌛ rimordial.d', '⌛ imordial.de',
'⌛ mordial.dev', '⌛ ordial.dev', '⌛ rdial.dev', '⌛ dial.dev', '⌛ ial.dev', '⌛ al.dev', '⌛ l.dev', '⌛ .dev', '⌛ dev', '⌛ ev', '⌛ v',  '⌛'}
local zC_clan = { '〄', 'R>|〄', 'RA>|〄', 'R4W>|〄', 'RAWЭ>|〄', 'R4W3T>|〄', 'RAWΣTR>|〄', 'Я4WETRI>|〄', 'RAWETRIP>|〄', 'RAWETRIP<|〄', 'R4WETRI<|〄', 'RAWΣTR<|〄', 'R4W3T<|〄', 'RAWЭ<|〄', 'R4W<|〄', 'RA<|〄', 'R<|〄', '〄'}
local tC = { 'onetap' }
local oC_clan = { 'g', 'ga', 'gam', 'game', 'games', 'games', 'gamese', ' gamesen', 'gamesens', 'gamesense', 'amesense', 'mesense', 'esense', 'sense', 'ense', 'nse', 'se', 'e', ''}
local clantag_ezfrags = { 'E', 'EZ', 'EZf', 'EZfr', 'EZfra', 'EZfrag', 'EZfrags', 'EZfrag', 'EZfra', 'EZfr', 'EZf', 'EZ', 'E', '' }
local kC_clan = { ' ', ' | ', ' |\\ ', ' |\\| ', ' N ', ' N3 ', ' Ne ', ' Ne\\ ', ' Ne\\/ ', ' Nev ', ' Nev3 ', ' Neve ', ' Neve| ', ' Neve|2 ', ' Never|_ ', ' Neverl ', ' Neverl0 ', ' Neverlo ', ' Neverlo5 ',
 ' Neverlos ', ' Neverlos3 ', ' Neverlose ', ' Neverlose. ', ' Neverlose.< ', ' Neverlose.c< ', ' Neverlose.cc ', ' Neverlose.cc ', ' Neverlose.cc ', ' Neverlose.c< ', ' Neverlose.< ', ' Neverlose. ', ' Neverlose '
 , ' Neverlos3 ', ' Neverlos ', ' Neverlo5 ', ' Neverlo ', ' Neverl0 ', ' Neverl ', ' Never|_ ', ' Never|2 ', ' Neve|2 ', ' Neve| ', ' Neve ', ' Nev3 ', ' Ne\\/ ', ' Ne\\ ', ' Ne ', ' N3 ', ' |\\| ', ' |\\ ', ' | ', ' ', '' }
local rC = { 'e', 'ev', 'ev', 'ev0', 'ev0l', 'ev0lv', 'ev0lve', 'ev0lve.', 'ev0lve.x', 'ev0lve.xy', 'ev0lve.xyz', 'v0lve.xyz', '0lve.xyz', 'lve.xyz', 've.xyz', 'e.xyz', '.xyz', 'xyz', 'yz', 'z', '' }
local lC = { 'pandora',}

function clantagfc()
    local k_type = DC:get_int()
    if mC:get_bool() then
        local j_ct_item = safe_get_config_item('misc>various>clan tag')
        local s_time = math.floor(global_vars.realtime * 1.8)
        if uC ~= s_time then
            if k_type == 0 then utils.set_clan_tag(EC[s_time % #EC + 1]) end
            if k_type == 1 then utils.set_clan_tag(nC[s_time % #nC + 1]) end
            if k_type == 2 then utils.set_clan_tag(iC[s_time % #iC + 1]) end
            if k_type == 3 then utils.set_clan_tag(zC_clan[s_time % #zC_clan + 1]) end
            if k_type == 4 then utils.set_clan_tag(tC[s_time % #tC + 1]) end
            if k_type == 5 then utils.set_clan_tag(oC_clan[s_time % #oC_clan + 1]) end
            if k_type == 6 then utils.set_clan_tag(clantag_ezfrags[s_time % #clantag_ezfrags + 1]) end
            if k_type == 7 then utils.set_clan_tag(kC_clan[s_time % #kC_clan + 1]) end
            if k_type == 8 then utils.set_clan_tag(rC[s_time % #rC + 1]) end
            if k_type == 9 then utils.set_clan_tag(lC[s_time % #lC + 1]) end
            uC = s_time
            j_ct_item:set_bool(false)
        end
    end
end

local xC = cvar.r_aspectratio
local CC = xC and xC:get_float() or 0
local function gC(k)
    if not xC then return end
    local j_w, s_h = render.get_screen_size()
    if not s_h or s_h == 0 then return end
    local c_ratio = (j_w * k) / s_h
    if k == 1 then c_ratio = 0 end
    xC:set_float(c_ratio)
end
function aspect_ratio2()
    if HC:get_bool() then
        local k_val = vC:get_int() * .01
        k_val = 2 - k_val
        gC(k_val)
    end
end

function checkingmisc()
    local k_idx = l:get_int()
    safe_set_visible(v .. 'Shadow off', k_idx == 4)
    safe_set_visible(v .. 'Trash Talk', k_idx == 4)
    safe_set_visible(v .. 'Clantag', k_idx == 4)
    safe_set_visible(v .. 'Clantag Type', k_idx == 4 and mC:get_bool() == true)
    safe_set_visible(v .. 'Aspect Ratio', k_idx == 4)
    safe_set_visible(v .. 'Aspect Value', k_idx == 4 and HC:get_bool() == true)
end

function fps_boost()
    if cC:get_bool() then
        local function set_cvar(cv, val)
            if cv then cv:set_float(val) end
        end
        set_cvar(cvar.cl_disablefreezecam, 1)
        set_cvar(cvar.cl_disablehtmlmotd, 1)
        set_cvar(cvar.r_dynamic, 0)
        set_cvar(cvar.r_3dsky, 0)
        set_cvar(cvar.r_shadows, 0)
        set_cvar(cvar.cl_csm_static_prop_shadows, 0)
        set_cvar(cvar.cl_csm_world_shadows, 0)
        set_cvar(cvar.cl_foot_contact_shadows, 0)
        set_cvar(cvar.cl_csm_viewmodel_shadows, 0)
        set_cvar(cvar.cl_csm_rope_shadows, 0)
        set_cvar(cvar.cl_csm_sprite_shadows, 0)
        set_cvar(cvar.cl_freezecampanel_position_dynamic, 0)
        set_cvar(cvar.cl_freezecameffects_showholiday, 0)
        set_cvar(cvar.cl_showhelp, 0)
        set_cvar(cvar.cl_autohelp, 0)
        set_cvar(cvar.mat_postprocess_enable, 0)
        set_cvar(cvar.fog_enable_water_fog, 0)
        set_cvar(cvar.gameinstructor_enable, 0)
        set_cvar(cvar.cl_csm_world_shadows_in_viewmodelcascade, 0)
        set_cvar(cvar.cl_disable_ragdolls, 0)
    end
end

local oC = {}
oC.import = function(j_data)
    local s_load = function()
        local s_raw = j_data == nil and decode_base64(k.get()) or j_data
        local c_parts = m(s_raw, '|')
        HC:set_bool(D(c_parts[1]))
        QU:set_bool(D(c_parts[2]))
        S:set_bool(D(c_parts[3]))
        q:set_int(tonumber(c_parts[4]))
        L:set_int(tonumber(c_parts[5]))
        I:set_bool(D(c_parts[6]))
        K:set_bool(D(c_parts[7]))
        X:set_int(tonumber(c_parts[8]))
        Z:set_int(tonumber(c_parts[9]))
        Q:set_bool(D(c_parts[10]))
        W:set_bool(D(c_parts[11]))
        f:set_int(tonumber(c_parts[12]))
        A:set_int(tonumber(c_parts[13]))
        B:set_bool(D(c_parts[14]))
        P:set_bool(D(c_parts[15]))
        d:set_int(tonumber(c_parts[16]))
        t:set_int(tonumber(c_parts[17]))
        V:set_bool(D(c_parts[18]))
        e:set_bool(D(c_parts[19]))
        p:set_int(tonumber(c_parts[20]))
        G:set_int(tonumber(c_parts[21]))
        J:set_bool(D(c_parts[22]))
        i:set_bool(D(c_parts[23]))
        kU:set_int(tonumber(c_parts[24]))
        jU:set_int(tonumber(c_parts[25]))
        sU:set_bool(D(c_parts[26]))
        cU:set_bool(D(c_parts[27]))
        NU:set_int(tonumber(c_parts[28]))
        DU:set_int(tonumber(c_parts[29]))
        mU:set_bool(D(c_parts[30]))
        HU:set_bool(D(c_parts[31]))
        vU:set_int(tonumber(c_parts[32]))
        lU:set_int(tonumber(c_parts[33]))
        UU:set_bool(D(c_parts[34]))
        YU:set_bool(D(c_parts[35]))
        MU:set_int(tonumber(c_parts[36]))
        OU:set_int(tonumber(c_parts[37]))
        FU:set_bool(D(c_parts[38]))
        TU:set_bool(D(c_parts[39]))
        zU:set_int(tonumber(c_parts[40]))
        RU:set_int(tonumber(c_parts[41]))
        hU:set_bool(D(c_parts[42]))
        C:set_bool(D(c_parts[43]))
        o:set_int(tonumber(c_parts[44]))
        a:set_int(tonumber(c_parts[45]))
        w:set_int(tonumber(c_parts[46]))
        n:set_bool(D(c_parts[47]))
        x:set_bool(D(c_parts[48]))
        h:set_bool(D(c_parts[49]))
        z:set_bool(D(c_parts[51]))
        y:set_bool(D(c_parts[52]))
        T:set_bool(D(c_parts[54]))
        print('-- loaded config')
    end
    local c_ok, H_err = pcall(s_load)
    if not c_ok then
        print('-- config expired or not working')
        return
    end
end
oC.export = function()
    local j_out = { tostring(HC:get_bool()) .. '|', tostring(QU:get_bool()) .. '|', tostring(S:get_bool()) .. '|', tostring(q:get_int()) .. '|', tostring(L:get_int()) .. '|',
    tostring(I:get_bool()) .. '|', tostring(K:get_bool()) .. '|', tostring(X:get_int()) .. '|', tostring(Z:get_int()) .. '|', tostring(Q:get_bool()) .. '|', tostring(W:get_bool()) .. '|',
    tostring(f:get_int()) .. '|', tostring(A:get_int()) .. '|', tostring(B:get_bool()) .. '|', tostring(P:get_bool()) .. '|', tostring(d:get_int()) .. '|', tostring(t:get_int()) .. '|',
    tostring(V:get_bool()) .. '|', tostring(e:get_bool()) .. '|', tostring(p:get_int()) .. '|', tostring(G:get_int()) .. '|', tostring(J:get_bool()) .. '|', tostring(i:get_bool()) .. '|',
    tostring(kU:get_int()) .. '|', tostring(jU:get_int()) .. '|', tostring(sU:get_bool()) .. '|', tostring(cU:get_bool()) .. '|', tostring(NU:get_int()) .. '|', tostring(DU:get_int()) .. '|',
    tostring(mU:get_bool()) .. '|', tostring(HU:get_bool()) .. '|', tostring(vU:get_int()) .. '|', tostring(lU:get_int()) .. '|', tostring(UU:get_bool()) .. '|', tostring(YU:get_bool()) .. '|',
    tostring(MU:get_int()) .. '|', tostring(OU:get_int()) .. '|', tostring(FU:get_bool()) .. '|', tostring(TU:get_bool()) .. '|', tostring(zU:get_int()) .. '|', tostring(RU:get_int()) .. '|',
    tostring(hU:get_bool()) .. '|', tostring(C:get_bool()) .. '|', tostring(o:get_int()) .. '|', tostring(a:get_int()) .. '|', tostring(w:get_int()) .. '|', tostring(n:get_bool()) .. '|',
    tostring(x:get_bool()) .. '|', tostring(h:get_bool()) .. '|', tostring(z:get_bool()) .. '|', tostring(y:get_bool()) .. '|', tostring(T:get_bool()) .. '|' }
    k.set(encode_base64(table.concat(j_out)))
    print('-- copied in the clipboard')
end

local aC = gui.add_button('Import Config', v, function() oC.import() end)
local wC = gui.add_button('Export Config', v, function() oC.export() end)

function on_paint()
    checkinghome()
    checkingconfigs()
    checkingrage()
    checkingantiaim()
    checkingwidgets()
    checkingmisc()
    dormantaimbot()
    rollresolve()
    if not engine.is_in_game() then return end
    watermark()
    skeetind()
    gui_controller()
    on_keybinds()
    clantagfc()
    aspect_ratio2()
    fps_boost()
    indicatorsfunc()
    indicators2func()
    aa_presetstwo()
end

function on_shutdown()
    if xC and CC and CC > 0 then
        xC:set_float(CC)
    end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ModelChanger & Gamesense animation (FFI safe guard)
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local model_paths = {
    "models/player/custom_player/legacy/ctm_gsg9.mdl",
    "models/player/custom_player/legacy/ctm_gign.mdl",
    "models/player/custom_player/eminem/gta_sa/wuzimu.mdl",
    "models/player/custom_player/z-piks.ru/gta_crip.mdl",
    "models/player/custom_player/frnchise9812/ballas1.mdl",
    "models/player/custom_player/kirby/kumlafbi/kumlafbi.mdl",
    "models/player/custom_player/tate_skeet/andrewtate.mdl",
    "models/player/custom_player/kuristaja/putin/putin.mdl",
    "models/player/custom_player/kuristaja/kim_jong_un/kim.mdl",
    "models/player/custom_player/frnchise9812/ballas2.mdl",
    "models/player/custom_player/eminem/gta_sa/swmotr5.mdl",
    "models/player/custom_player/eminem/gta_sa/wuzimu.mdl",
    "models/player/custom_player/eminem/gta_sa/bmybar.mdl",
    "models/player/custom_player/eminem/gta_sa/fam1.mdl",
    "models/player/custom_player/eminem/gta_sa/somyst.mdl",
    "models/player/custom_player/eminem/css/t_arctic.mdl",
    "models/player/custom_player/kuristaja/cso2/goth_schoolgirl/goth.mdl",
    "models/player/custom_player/eminem/gta_sa/vwfypro.mdl",
}

local menu = {}
menu.add = {
    en = gui.add_checkbox("Enabled", "lua>tab a"),
    path = gui.add_combo("Visual functions Ephoria", "lua>tab a", model_paths),
}

local gs_opt_air_static, gs_opt_air_break, gs_opt_legs_jitter, gs_opt_legs_static, gs_opt_lby, gs_opt_fakeduck = gui.add_multi_combo("Gamesense animation", "lua>tab a", {
    "air static", "air break", "legs jitter", "legs static", "lower body yaw", "fake duck breaker"
})

local mc_initialized = false
local mc_raw_client_ent_list, mc_get_client_ent, mc_raw_model_info, mc_get_model_idx, mc_find_load_model, mc_raw_str_tbl, mc_find_tbl

local function init_model_changer()
    if mc_initialized then return true end
    if not info.fatality.allow_insecure then return false end
    if not ffi then return false end

    local ok = pcall(function()
        ffi.cdef [[
            typedef struct{
                void*   handle;
                char    name[260];
                int     load_flags;
                int     server_count;
                int     type;
                int     flags;
                float   mins[3];
                float   maxs[3];
                float   radius;
                char    pad[0x1C];
            } model_t_mc;
            typedef struct {void** this;} aclass_mc;
            typedef void*(__thiscall* get_client_entity_fn)(void*, int);
            typedef void(__thiscall* find_or_load_model_fn)(void*, const char*);
            typedef const int(__thiscall* get_model_index_fn)(void*, const char*);
            typedef const int(__thiscall* add_string_fn)(void*, bool, const char*, int, const void*);
            typedef void*(__thiscall* find_table_fn)(void*, const char*);
            typedef void(__thiscall* set_model_index_fn)(void*, int);
        ]]

        local iface_ent = utils.find_interface("client.dll", "VClientEntityList003")
        if not iface_ent then return end
        mc_raw_client_ent_list = ffi.cast(ffi.typeof("void***"), iface_ent)
        mc_get_client_ent = ffi.cast("get_client_entity_fn", mc_raw_client_ent_list[0][3])

        local iface_mdl = utils.find_interface("engine.dll", "VModelInfoClient004")
        if not iface_mdl then return end
        mc_raw_model_info = ffi.cast(ffi.typeof("void***"), iface_mdl)
        mc_get_model_idx = ffi.cast("get_model_index_fn", mc_raw_model_info[0][2])
        mc_find_load_model = ffi.cast("find_or_load_model_fn", mc_raw_model_info[0][43])

        local iface_str = utils.find_interface("engine.dll", "VEngineClientStringTable001")
        if not iface_str then return end
        mc_raw_str_tbl = ffi.cast(ffi.typeof("void***"), iface_str)
        mc_find_tbl = ffi.cast("find_table_fn", mc_raw_str_tbl[0][3])

        mc_initialized = true
    end)
    return ok and mc_initialized
end

local function p_model(pa)
    if not mc_initialized then
        if not init_model_changer() then return false end
    end
    local a_p = ffi.cast(ffi.typeof("void***"), mc_find_tbl(mc_raw_str_tbl, "modelprecache"))
    if a_p ~= nil and ffi.cast("unsigned int", a_p) ~= 0 then
        mc_find_load_model(mc_raw_model_info, pa)
        local ac = ffi.cast("add_string_fn", a_p[0][8])
        if ac == nil then return false end
        local acs = ac(a_p, false, pa, -1, nil)
        if acs == -1 then return false end
    end
    return true
end

local function smi_model(en, i_idx)
    if not mc_initialized then return end
    local rw = mc_get_client_ent(mc_raw_client_ent_list, en)
    if rw and ffi.cast("unsigned int", rw) ~= 0 then
        local gc = ffi.cast(ffi.typeof("void***"), rw)
        local se = ffi.cast("set_model_index_fn", gc[0][75])
        if se ~= nil then
            se(gc, i_idx)
        end
    end
end

local function cm_model(ent, md)
    if md and md:len() > 5 then
        if p_model(md) == false then return end
        local i_idx = mc_get_model_idx(mc_raw_model_info, md)
        if i_idx == -1 then return end
        smi_model(ent, i_idx)
    end
end

function on_frame_stage_notify(stage, pre_original)
    if stage == csgo.frame_render_start then
        if not engine.is_in_game() then return end
        local player = entities.get_entity(engine.get_local_player())
        if player == nil or not player:is_valid() or not player:is_alive() then return end
        if menu.add.en:get_bool() then
            local sel_idx = menu.add.path:get_int() + 1
            if model_paths[sel_idx] then
                cm_model(player:get_index(), model_paths[sel_idx])
            end
        end
    end
end

-------------------------------------Gamesense Animation------------------------------------------
local gs_initialized = false
local gs_ent_list_ptr, gs_get_ent_fn, gs_get_pose_params_fn
local gs_cache = { collected_cache = {} }
local gs_d = 10576
local gs_e = 39264
local gs_f = 265
local gs_leg_slide_cfg = safe_get_config_item("Rage>Anti-Aim>Desync>Leg Slide")
local gs_fake_duck_cfg = safe_get_config_item("misc>movement>fake duck")

local function init_gamesense_anim()
    if gs_initialized then return true end
    if not info.fatality.allow_insecure then return false end
    if not ffi then return false end

    local ok = pcall(function()
        ffi.cdef[[
            struct pose_parameters_t_gs
            {
                char pad[8];
                float m_flStart;
                float m_flEnd;
                float m_flState;
            };
        ]]

        local iface = utils.find_interface("client.dll", "VClientEntityList003")
        if not iface or iface == 0 then return end
        gs_ent_list_ptr = ffi.cast("void***", iface)

        local function make_vfunc(sig, idx)
            local t_type = ffi.typeof(sig)
            return function(ptr, ...)
                local c_ptr = ffi.cast("void***", ptr)
                return ffi.cast(t_type, c_ptr[0][idx])(c_ptr, ...)
            end
        end

        gs_get_ent_fn = make_vfunc("void*(__thiscall*)(void*, int)", 3)

        local pat = "55 8B EC 8B 45 08 57 8B F9 8B 4F 04 85 C9 75 15"
        local pat_addr = utils.find_pattern("client.dll", pat)
        if not pat_addr or pat_addr == 0 then return end
        gs_get_pose_params_fn = ffi.cast("struct pose_parameters_t_gs*(__thiscall*)(void*, int)", pat_addr)

        gs_initialized = true
    end)
    return ok and gs_initialized
end

local function SetPose(ent_handle, param_idx, start_val, end_val)
    if not gs_initialized then
        if not init_gamesense_anim() then return false end
    end
    if not ent_handle then return false end
    local a_uint = ffi.cast("uintptr_t", ent_handle)
    if a_uint == 0 then return false end
    local a_ptr = ffi.cast("void**", a_uint + gs_d)[0]
    if not a_ptr or ffi.cast("uintptr_t", a_ptr) == 0 then return false end
    local pose = gs_get_pose_params_fn(a_ptr, param_idx)
    if not pose or ffi.cast("uintptr_t", pose) == 0 then return false end

    if gs_cache.collected_cache[param_idx] == nil then
        gs_cache.collected_cache[param_idx] = {
            m_flStart = pose.m_flStart,
            m_flEnd = pose.m_flEnd,
            m_flState = pose.m_flState,
            is_applied = false
        }
        return true
    end

    if start_val ~= nil and not gs_cache.collected_cache[param_idx].is_applied then
        pose.m_flStart = start_val
        pose.m_flEnd = end_val
        pose.m_flState = (pose.m_flStart + pose.m_flEnd) / 2
        gs_cache.collected_cache[param_idx].is_applied = true
        return true
    end

    if gs_cache.collected_cache[param_idx].is_applied then
        pose.m_flStart = gs_cache.collected_cache[param_idx].m_flStart
        pose.m_flEnd = gs_cache.collected_cache[param_idx].m_flEnd
        pose.m_flState = gs_cache.collected_cache[param_idx].m_flState
        gs_cache.collected_cache[param_idx].is_applied = false
        return true
    end

    return false
end

local function gamesense_animation_create_move(cmd)
    if not gs_initialized then
        if not init_gamesense_anim() then return end
    end
    pcall(function()
        local lp_idx = engine.get_local_player()
        if not lp_idx or lp_idx == 0 then return end
        local ent_handle = gs_get_ent_fn(gs_ent_list_ptr, lp_idx)
        if not ent_handle or ffi.cast("uintptr_t", ent_handle) == 0 then return end
        local ent_uint = ffi.cast("uintptr_t", ent_handle)
        local anim_ptr = ffi.cast("void**", ent_uint + gs_e)[0]
        if not anim_ptr or ffi.cast("uintptr_t", anim_ptr) == 0 then return end

        local lp = entities.get_entity(lp_idx)
        local is_ducking = false
        if lp and lp:is_valid() then
            local flags = lp:get_prop("m_fFlags") or 0
            is_ducking = bit.band(flags, 2) ~= 0
        end

        if gs_opt_air_break:get_bool() then
            if utils.random_int(0, 1) == 0 then 
                SetPose(ent_handle, 6, 0, 1) 
            else 
                SetPose(ent_handle, 6, 0.1, 0) 
            end
        elseif gs_opt_air_static:get_bool() then
            SetPose(ent_handle, 6, 0.7, 1)
        else
            SetPose(ent_handle, 6, 0.1, 0)
        end

        if gs_opt_legs_jitter:get_bool() then
            gs_leg_slide_cfg:set_int(2)
            if utils.random_int(0, 1) > 0 then 
                SetPose(ent_handle, 0, 0, 20) 
            else 
                SetPose(ent_handle, 0, 14, 10) 
            end
        elseif gs_opt_legs_static:get_bool() then
            SetPose(ent_handle, 0, 0, 20)
        end

        if gs_opt_lby:get_bool() then
            SetPose(ent_handle, 10, 0, 0)
        end

        if gs_opt_fakeduck:get_bool() then
            if gs_fake_duck_cfg:get_bool() then
                if utils.random_int(0, 5) == 0 then 
                    SetPose(ent_handle, 16, 0, 0) 
                else 
                    SetPose(ent_handle, 16, 10, 0) 
                end
            end
        end
    end)
end

function on_setup_move(cmd)
    if not gs_initialized then return end
    pcall(function()
        local lp_idx = engine.get_local_player()
        if not lp_idx or lp_idx == 0 then return end
        local ent_handle = gs_get_ent_fn(gs_ent_list_ptr, lp_idx)
        if not ent_handle or ffi.cast("uintptr_t", ent_handle) == 0 then return end
        for param_idx, _ in pairs(gs_cache.collected_cache) do
            SetPose(ent_handle, param_idx)
        end
    end)
end

function on_create_move(cmd)
    if not engine.is_in_game() then return end
    Inverting()
    fl()
    aa_presets()
    antiaimbuilder()
    gamesense_animation_create_move(cmd)
end
