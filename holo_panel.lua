ffi.cdef[[
    typedef struct {
        float x;
        float y;
        float z;
    } Vector;
    typedef void*(__thiscall* c_entity_list_get_client_entity_t)(void*, int);
    typedef void*(__thiscall* c_entity_list_get_client_entity_from_handle_t)(void*, uintptr_t);
    typedef int(__thiscall* c_weapon_get_muzzle_attachment_index_first_person_t)(void*, void*);
    typedef bool(__thiscall* c_entity_get_attachment_t)(void*, int, Vector*);
]]
bind_argument = function(fn, arg) return function(...) return fn(arg, ...) end end
interface_type = ffi.typeof("uintptr_t**")
client_entity_list = ffi.cast(interface_type, utils.find_interface("client.dll", "VClientEntityList003"))
get_client_entity = bind_argument(ffi.cast("c_entity_list_get_client_entity_t", client_entity_list[0][3]), client_entity_list)
local function find_function(module, pattern, cast)
    local x = utils.find_pattern(module, pattern)
    if x <= 0 then
        return nil
    end

    return ffi.cast(cast, x)
end
local font = render.create_font("arial.ttf", 28, render.font_flag_outline)
local function get_muzzle_pos()
    local lp = entities.get_entity(engine.get_local_player())
    if not lp or not lp:is_alive() then return end
    local lp_address = get_client_entity(engine.get_local_player())
    local weapon = lp:get_weapon()
    if not weapon then return end
    local weapon_address = get_client_entity(weapon:get_index())
    local viewmodel_handle = lp:get_prop("m_hViewModel[0]")
    local viewmodel = entities.get_entity_from_handle(viewmodel_handle)
    local viewmodel_address = get_client_entity(viewmodel:get_index())
    local viewmodel_vtbl = ffi.cast(interface_type, viewmodel_address)[0]
    local weapon_vtbl = ffi.cast(interface_type, weapon_address)[0]
    local get_viewmodel_attachment_fn = ffi.cast("c_entity_get_attachment_t", viewmodel_vtbl[84])
    local get_muzzle_attachment_index_fn = ffi.cast("c_weapon_get_muzzle_attachment_index_first_person_t", weapon_vtbl[468])
    local vec3 = ffi.new("Vector")
    local muzzle_attachment_index = get_muzzle_attachment_index_fn(weapon_address, viewmodel_address)
    local state = get_viewmodel_attachment_fn(viewmodel_address, muzzle_attachment_index, vec3)
    local vec3_pos = math.vec3(vec3.x, vec3.y, vec3.z)
    return vec3_pos
end
local exploit = ""
function get_exploit()
    if gui.get_config_item("Rage>Aimbot>Aimbot>Double tap"):get_bool() then
        exploit = "DT"
    elseif gui.get_config_item("Rage>Aimbot>Aimbot>Hide shot"):get_bool() then
        exploit =  "HS"
    else
        exploit = "FL"
    end
end
function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
  end
local weapon_names = {
    [0] = "WEAPON_INVALID",
	[1] = "Desert Eagle",
	[2] = "Dual Berettas",
	[3] = "Five-Seven",
	[4] = "Glock-18",
	[7] = "AK-47",
	[8] = "AUG",
	[9] = "AWP",
	[10] = "Famas",
	[11] = "G3SG1",
	[13] = "Galil AR",
	[14] = "M249",
	[16] = "M4A4",
	[17] = "MAC-10",
	[19] = "P90",
	[23] = "MP5-SD",
	[24] = "UMP-45",
	[25] = "XM1014",
	[26] = "PP-Bizon",
	[27] = "Mag-7",
	[28] = "Negev",
	[29] = "Sawed-Off",
	[30] = "Tec-9",
	[31] = "Zeus x27",
	[32] = "P2000",
	[33] = "MP7",
	[34] = "MP9",
	[35] = "Nova",
	[36] = "P250",
	[37] = "Riot Shield",
	[38] = "SCAR-20",
	[39] = "SG 553",
	[40] = "SSG 08",
	[41] = "Knife-CT",
	[42] = "Knife-CT",
	[43] = "Flashbang",
	[44] = "HE Grenade",
	[45] = "Smoke Grenade",
	[46] = "Molotov",
	[47] = "Decoy Grenade",
	[48] = "Incendiary Grenade",
	[49] = "C4 Explosive",
	[57] = "Medi-Shot",
	[59] = "Knife-T",
	[60] = "M4A1-S",
	[61] = "USP-S",
	[63] = "CZ75-Auto",
	[64] = "R8 Revolver",
	[68] = "Tactical Awareness Grenade",
	[69] = "Bare Hands",
	[70] = "Breach Charge",
	[72] = "Tablet",
	[75] = "Axe",
	[76] = "Hammer",
	[78] = "Wrench",
	[81] = "Fire Bomb",
	[82] = "Diversion Device",
	[83] = "Frag Grenade",
	[84] = "Snowball",
	[85] = "Bump Mine",
	[500] = "Bayonet",
    [503] = "Classic Knife",
	[505] = "Flip Knife",
	[506] = "Gut Knife",
	[507] = "Karambit",
	[508] = "M9 Bayonet",
	[509] = "Huntsman Knife",
	[512] = "Falcion Knife",
	[514] = "Bowie Knife",
	[515] = "Butterfly Knife",
    [516] = "Shadow Daggers",
    [517] = "Paracord Knife",
    [518] = "Survival Knife",
	[519] = "Ursus Knife",
    [520] = "Navaja Knife",
    [521] = "Nomad Knife",
	[522] = "Stiletto Knife",
    [523] = "Talon Knife",
    [525] = "Skeleton Knife",
}

local ssize = {render.get_screen_size()}
local smol = render.create_font("Arial.ttf", 15)
local smoll = render.create_font("Arial.ttf", 17)

local holo_box = gui.add_checkbox("Enable holo panel", "lua>tab a")
local holo_box1 = gui.add_colorpicker("lua>tab a>Enable holo panel", true, render.color(30, 30, 30, 120))
gui.add_checkbox("Text color", "lua>tab a")
local textcolor = gui.add_colorpicker("lua>tab a>Text color", true, render.color(28, 8, 158, 255))

local holo_x = gui.add_slider("Holo panel x 1st", "lua>tab a", -1100, 500, 1)
local holo_y = gui.add_slider("Holo panel y 1st", "lua>tab a", -400, 500, 1)
local holo_x_3rd = gui.add_slider("Holo panel x 3rd", "lua>tab a", -1100, 500, 1)
local holo_y_3rd = gui.add_slider("Holo panel y 3rd", "lua>tab a", -400, 500, 1)
local holo_line = gui.add_combo("Holo panel line", "lua>tab a", {"None", "Left top", "Right top", "Left bottom",  "Right bottom"})
local holo_line_color = gui.add_colorpicker("lua>tab a>Holo panel line", true)
local holo_box_line =  gui.add_checkbox("Line inside Box", "lua>tab a")
local holo_box_line1 = gui.add_colorpicker("lua>tab a>Line inside box", true, render.color(28, 8, 158, 255))
local holo_box_line2 = gui.add_colorpicker("lua>tab a>Line inside box", true, render.color(240, 5, 36, 255))

gui.add_checkbox("DT,HS,FL", "lua>tab a")
local flcolor = gui.add_colorpicker("lua>tab a>DT,HS,FL", true, render.color(28, 8, 158, 255))
local hscolor = gui.add_colorpicker("lua>tab a>DT,HS,FL", true, render.color(28, 8, 158, 255))
local dtcolor = gui.add_colorpicker("lua>tab a>DT,HS,FL", true, render.color(28, 8, 158, 255))


local extra_length = 180

gui.add_checkbox("Ammo color", "lua>tab a")
local ammocolor2 = gui.add_colorpicker("lua>tab a>Ammo Color", true, render.color(28, 8, 158, 255))

local insert = gui.add_textbox("Fifth text line", "lua>tab a")
local insert1 = gui.add_textbox("Sixth text line", "lua>tab a")

local lerp = function(a, b, percentage) return a + (b - a) * percentage end
local x, y, x_1, y_1, width, height = 0, 0, 0, 0, 0, 0
local score = false
function on_paint()
    local lp = entities.get_entity(engine.get_local_player())
    if not lp then return end
    if not lp:is_alive() then return end
    if (lp:get_prop("m_bIsScoped") == true) then return end
    if score == true then return end
    if holo_box:get_bool() == false then return end
    get_exploit()
    local x_1, y_1 = utils.world_to_screen(get_muzzle_pos().x,get_muzzle_pos().y,get_muzzle_pos().z)

    if x_1 == nil or y_1 == nil then return end

        local text1 = {render.get_text_size(smol, insert:get_string())}
        local text2 = {render.get_text_size(smol, insert1:get_string())}
    if (text1[1] > 90) then
        extra_length = 85 + text1[1] + 5
    end
    if (text2[1] > 90) then
        extra_length = 85 + text2[1] + 5
    end

    if (gui.get_config_item("Visuals>View>Camera>Thirdperson"):get_bool() == false) then
        x = lerp(x, x_1 + 100 + holo_x:get_int(), global_vars.frametime * 12)
        y = lerp(y, y_1 - 100 - holo_y:get_int(), global_vars.frametime * 12)
    else
        x = lerp(x, x_1 + 100 + holo_x_3rd:get_int(), global_vars.frametime * 12)
        y = lerp(y, y_1 - 100 - holo_y_3rd:get_int(), global_vars.frametime * 12)
    end
    height = lerp(height, 110, global_vars.frametime * 12)
    width = lerp(width, extra_length, global_vars.frametime * 12)

    if holo_line:get_int() == 0 then 
    elseif holo_line:get_int() == 1 then
        render.line(x_1, y_1, x, y + 2, holo_line_color:get_color())
    elseif holo_line:get_int() == 2 then
        render.line(x_1, y_1, x + width, y + 2, holo_line_color:get_color())
    elseif holo_line:get_int() == 3 then
        render.line(x_1, y_1, x, y + height -2, holo_line_color:get_color())
    elseif holo_line:get_int() == 4 then
        render.line(x_1, y_1, x + width, y + height -2, holo_line_color:get_color())
    end
    

    render.rect_filled_rounded(x, y, x + width, y + height, holo_box1:get_color(), 5.5, render.all)
    if holo_box_line:get_bool() then render.line_multicolor(x + 7, y, x + width - 7, y, holo_box_line1:get_color(), holo_box_line2:get_color()) end

    for k,v in pairs(weapon_names) do
        if lp:get_weapon():get_prop("m_iItemDefinitionIndex") == k then
            weaponname = v
        end
    end
    render.text(smol, x + 2, y + 3, weaponname, textcolor:get_color())

    if exploit == "FL" then
        render.text(smoll, x + 2, y + 23, exploit, flcolor:get_color())
        render.circle(x + 35, y + 31, 7, flcolor:get_color(), 2, 12, gui.get_config_item("Rage>Anti-Aim>Fakelag>Limit"):get_int() / 14, 270)
    elseif exploit == "HS" then
        render.text(smoll, x + 2, y + 23, exploit, hscolor:get_color())
    elseif exploit == "DT" then
        render.text(smoll, x + 2, y + 23, exploit, dtcolor:get_color())
    end
    render.circle(x + 130, y + 22, 20, ammocolor2:get_color(), 2, 14, lp:get_weapon():get_prop("m_iClip1") / utils.get_weapon_info(lp:get_weapon():get_prop("m_iItemDefinitionIndex")).max_clip1, 270)
    render.text(smol, x + 130, y + 16, lp:get_weapon():get_prop("m_iClip1"), textcolor:get_color(), render.align_center, render.align_center)
    render.text(smol, x + 130, y + 29, lp:get_weapon():get_prop("m_iPrimaryReserveAmmoCount"), textcolor:get_color(), render.align_center, render.align_center)
    
    render.text(smol, x + 2, y + 60, "Kills: ", textcolor:get_color(), render.align_left, render.align_center)
    render.text(smol, x + 2, y + 80, "Assists: ", textcolor:get_color(), render.align_left, render.align_center)
    render.text(smol, x + 2, y + 100, "Deaths: ", textcolor:get_color(), render.align_left, render.align_center)
    render.text(smol, x + 70, y + 60, tostring(lp:get_prop("m_iMatchStats_Kills")), textcolor:get_color(), render.align_right, render.align_center)
    render.text(smol, x + 70, y + 80, tostring(lp:get_prop("m_iMatchStats_Assists")), textcolor:get_color(), render.align_right, render.align_center)
    render.text(smol, x + 70, y + 100, tostring(lp:get_prop("m_iMatchStats_Deaths")), textcolor:get_color(), render.align_right, render.align_center)

    render.text(smol, x + 85, y + 60, "K/D: ", textcolor:get_color(), render.align_left, render.align_center)
    if lp:get_prop("m_iMatchStats_Deaths") > 0 then
        render.text(smol, x + 140, y + 60, round(lp:get_prop("m_iMatchStats_Kills") / lp:get_prop("m_iMatchStats_Deaths"), 2), textcolor:get_color(), render.align_right, render.align_center)
    else
        if lp:get_prop("m_iMatchStats_Kills") >= 0 then render.text(smol, x + 130, y + 60, math.floor(lp:get_prop("m_iMatchStats_Kills")), textcolor:get_color(), render.align_right, render.align_center)
        else render.text(smol, x + 130, y + 60, "0", render.align_right, render.align_center) end

    end
    render.text(smol, x + 85, y + 80, insert:get_string(), textcolor:get_color(), render.align_left, render.align_center)
    render.text(smol, x + 85, y + 100, insert1:get_string(), textcolor:get_color(), render.align_left, render.align_center)
end
function on_create_move(cmd)
    local buttons = cmd:get_buttons()
    if buttons == csgo.in_score then
        score = true
    else
        score = false
    end
end