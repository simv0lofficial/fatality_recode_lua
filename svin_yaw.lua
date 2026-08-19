local Find = gui.get_config_item
local Checkbox = gui.add_checkbox
local Slider = gui.add_slider
local Combo = gui.add_combo
local MultiCombo = gui.add_multi_combo
local AddKeybind = gui.add_keybind
local CPicker = gui.add_colorpicker
local AddButton = gui.add_button
local playerstate = 0;
local ConditionalStates = { }
local configs = {}

local pixel = render.font_esp
local calibri11 = render.create_font("calibri.ttf", 11, render.font_flag_outline)
local calibri13 = render.create_font("calibri.ttf", 13, render.font_flag_shadow)
local verdana = render.create_font("verdana.ttf", 13, render.font_flag_outline)
local tahoma = render.create_font("tahoma.ttf", 13, render.font_flag_shadow)

local refs = {
    yawadd = Find("Rage>Anti-Aim>Angles>Yaw add");
    yawaddamount = Find("Rage>Anti-Aim>Angles>Add");
    spin = Find("Rage>Anti-Aim>Angles>Spin");
    jitter = Find("Rage>Anti-Aim>Angles>Jitter");
    spinrange = Find("Rage>Anti-Aim>Angles>Spin range");
    spinspeed = Find("Rage>Anti-Aim>Angles>Spin speed");
    jitterrandom = Find("Rage>Anti-Aim>Angles>Random");
    jitterrange = Find("Rage>Anti-Aim>Angles>Jitter Range");
    desync = Find("Rage>Anti-Aim>Desync>Fake amount");
    compAngle = Find("Rage>Anti-Aim>Desync>Compensate angle");
    freestandFake = Find("Rage>Anti-Aim>Desync>Freestand fake");
    flipJittFake = Find("Rage>Anti-Aim>Desync>Flip fake with jitter");
};

local var = {
    player_states = {"Standing", "Moving", "Slow motion", "Air", "Air Duck", "Crouch"};
};

---speed function
function get_local_speed()
    local local_player = entities.get_entity(engine.get_local_player())
    if local_player == nil then
      return
    end
 
    local velocity_x = local_player:get_prop("m_vecVelocity[0]")
    local velocity_y = local_player:get_prop("m_vecVelocity[1]")
    local velocity_z = local_player:get_prop("m_vecVelocity[2]")
 
    local velocity = math.vec3(velocity_x, velocity_y, velocity_z)
    local speed = math.ceil(velocity:length2d())
    if speed < 10 then
        return 0
    else
        return speed
    end
end

--fps stuff
function accumulate_fps()
    return math.ceil(1 / global_vars.frametime)
end
--tickrate function
function get_tickrate()
    if not engine.is_in_game() then return end

    return math.floor( 1.0 / global_vars.interval_per_tick )
end
---ping function
function get_ping()
    if not engine.is_in_game() then return end

    return math.ceil(utils.get_rtt() * 1000);
end

-- character table string
local b='ABCDKCCzwKyY9rmBJGu48FrkNMro4AWtCkc1flmnopqrstuvwxyz0123456789+/'

-- encoding
local function enc(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
local function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

--import and export system
local function str_to_sub(text, sep)
    local t = {}
    for str in string.gmatch(text, "([^"..sep.."]+)") do
        t[#t + 1] = string.gsub(str, "\n", " ")
    end
    return t
end

local function to_boolean(str)
    if str == "true" or str == "false" then
        return (str == "true")
    else
        return str
    end
end

local function animation(check, name, value, speed)
    if check then
        return name + (value - name) * global_vars.frametime * speed / 1.5
    else
        return name - (value + name) * global_vars.frametime * speed / 1.5
        
    end
end

function animate(value, cond, max, speed, dynamic, clamp)

    -- animation speed
    speed = speed * global_vars.frametime * 20

    -- static animation
    if dynamic == false then
        if cond then
            value = value + speed
        else
            value = value - speed
        end
    
    -- dynamic animation
    else
        if cond then
            value = value + (max - value) * (speed / 100)
        else
            value = value - (0 + value) * (speed / 100)
        end
    end

    -- clamp value
    if clamp then
        if value > max then
            value = max
        elseif value < 0 then
            value = 0
        end
    end

    return value
end

function drag(var_x, var_y, size_x, size_y)
    local mouse_x, mouse_y = input.get_cursor_pos()

    local drag = false

    if input.is_key_down(0x01) then
        if mouse_x > var_x:get_int() and mouse_y > var_y:get_int() and mouse_x < var_x:get_int() + size_x and mouse_y < var_y:get_int() + size_y then
            drag = true
        end
    else
        drag = false
    end

    if (drag) then
        var_x:set_int(mouse_x - (size_x / 2))
        var_y:set_int(mouse_y - (size_y / 2))
    end

end
print(" _______________________ ")
print("| SwinYaw Loaded        |")
print("| Dev: t.me/s1legendirl |")
print("|_______________________|")

local MenuSelection = Combo("[SwinYaw]", "lua>tab b", {"Anti-Aim", "Anti-Aim Helpers", "Visuals"})

--start of AA
ConditionalStates[0] = {
    player_state = Combo("[Conditions]", "lua>tab b", var.player_states);
}
for i=1, 6 do
    ConditionalStates[i] = {
        ---Anti-Aim
        yawadd = Checkbox("Yaw add " .. var.player_states[i], "lua>tab b");
        yawaddamount = Slider("Add " .. var.player_states[i], "lua>tab b", -180, 180, 1);
        spin = Checkbox("Spin " .. var.player_states[i], "lua>tab b");
        spinrange = Slider("Spin range " .. var.player_states[i], "lua>tab b", 0, 360, 1);
        spinspeed = Slider("Spin speed " .. var.player_states[i], "lua>tab b", 0, 360, 1);
        jitter = Checkbox("Jitter " .. var.player_states[i], "lua>tab b");
        jittertype = Combo("Jitter Type " .. var.player_states[i], "lua>tab b", {"Center", "Offset", "Random"});
        jitterrange = Slider("Jitter range " .. var.player_states[i], "lua>tab b", 0, 360, 1);
        ---Desync
        desynctype = Combo("Desync Type " .. var.player_states[i], "lua>tab b", {"Static", "Jitter", "Random"});
        desync = Slider("Desync " .. var.player_states[i], "lua>tab b", -60, 60, 1);
        compAngle = Slider("Comp " .. var.player_states[i], "lua>tab b", 0, 100, 1);
        flipJittFake = Checkbox("Flip fake " .. var.player_states[i], "lua>tab b");
    };
end
local cImport = AddButton("Import settings", "LUA>TAB b", function() configs.import() end);
local cExport = AddButton("Export settings", "LUA>TAB b", function() configs.export() end);
local cDefault = AddButton("Load default settings", "LUA>TAB b", function() configs.importDefault() end);
local StaticFS = Checkbox("Static Freestand", "lua>tab b")
local FF = Checkbox("Fake Flick", "lua>tab b")
local FFK = AddKeybind("lua>tab b>Fake Flick")
local IV = Checkbox("Inverter", "lua>tab b")
local IVK = AddKeybind("lua>tab b>Inverter")
--end of AA
--misc
local clantagmain = Checkbox("Clantag", "lua>tab b")
--end of misc

--updates menu elements and refs
function MenuElements()
    for i=1, 6 do
        local tab = MenuSelection:get_int()
        local state = ConditionalStates[0].player_state:get_int() + 1
        local yawAddCheck = ConditionalStates[i].yawadd:get_bool()
        local spinCheck = ConditionalStates[i].spin:get_bool()
        local jitterCheck = ConditionalStates[i].jitter:get_bool()

        --antiaim
        gui.set_visible("lua>tab b>[Conditions]", tab == 0);
        gui.set_visible("lua>tab b>Yaw add " .. var.player_states[i], tab == 0 and state == i);
        gui.set_visible("lua>tab b>Add " .. var.player_states[i], tab == 0 and state == i and yawAddCheck);
        gui.set_visible("lua>tab b>Spin " .. var.player_states[i], tab == 0 and state == i);
        gui.set_visible("lua>tab b>Spin range " .. var.player_states[i], tab == 0 and state == i and spinCheck);
        gui.set_visible("lua>tab b>Spin speed " .. var.player_states[i], tab == 0 and state == i and spinCheck);
        gui.set_visible("lua>tab b>Jitter " .. var.player_states[i], tab == 0 and state == i);
        gui.set_visible("lua>tab b>Jitter Type " .. var.player_states[i], tab == 0 and state == i and jitterCheck);
        gui.set_visible("lua>tab b>Jitter range " .. var.player_states[i], tab == 0 and state == i and jitterCheck);

        --desync
        gui.set_visible("lua>tab b>Desync Type " .. var.player_states[i], tab == 0 and state == i);
        gui.set_visible("lua>tab b>Desync " .. var.player_states[i], tab == 0 and state == i);
        gui.set_visible("lua>tab b>Comp " .. var.player_states[i], tab == 0 and state == i);
        gui.set_visible("lua>tab b>Flip fake " .. var.player_states[i], tab == 0 and state == i);
        --config system
        gui.set_visible("lua>tab b>Import settings", tab == 0);
        gui.set_visible("lua>tab b>Export settings", tab == 0);
        gui.set_visible("lua>tab b>Load default settings", tab == 0);
        --aa helpers
        gui.set_visible("lua>tab b>Static Freestand", tab == 1);
        gui.set_visible("lua>tab b>Fake Flick", tab == 1);
        gui.set_visible("lua>tab b>Inverter", tab == 1);
        --misc tab
        gui.set_visible("lua>tab b>Clantag", tab == 2);
    end
end
--end of menu elements and refs

--start of getting AA states and setting valeus
function UpdateStateandAA()

    local isSW = info.fatality.in_slowwalk
    local local_player = entities.get_entity(engine.get_local_player())
    local inAir = local_player:get_prop("m_hGroundEntity") == -1
    local vel_x = math.floor(local_player:get_prop("m_vecVelocity[0]"))
    local vel_y = math.floor(local_player:get_prop("m_vecVelocity[1]"))
    local still = math.sqrt(vel_x ^ 2 + vel_y ^ 2) < 5
    local cupic = bit.band(local_player:get_prop("m_fFlags"),bit.lshift(2, 0)) ~= 0
    local flag = local_player:get_prop("m_fFlags")

    playerstate = 0

    if inAir and cupic then
        playerstate = 5
    else
        if inAir then
            playerstate = 4
        else
            if isSW then
                playerstate = 3
            else
                if cupic then
                    playerstate = 6
                else
                    if still and not cupic then
                        playerstate = 1
                    elseif not still then
                        playerstate = 2
                    end
                end
            end
        end
    end

    refs.yawadd:set_bool(ConditionalStates[playerstate].yawadd:get_bool());
    if ConditionalStates[playerstate].jittertype:get_int() == 1 then
        refs.yawaddamount:set_int((ConditionalStates[playerstate].yawaddamount:get_int()) + (global_vars.tickcount % 4 >= 2 and 0 or ConditionalStates[playerstate].jitterrange:get_int()))
    else
        refs.yawaddamount:set_int(ConditionalStates[playerstate].yawaddamount:get_int());
    end
    refs.spin:set_bool(ConditionalStates[playerstate].spin:get_bool());
    refs.jitter:set_bool(ConditionalStates[playerstate].jitter:get_bool());
    refs.spinrange:set_int(ConditionalStates[playerstate].spinrange:get_int());
    refs.spinspeed:set_int(ConditionalStates[playerstate].spinspeed:get_int());
    refs.jitterrandom:set_bool(ConditionalStates[playerstate].jittertype:get_int() == 2);
    --jitter types
    if ConditionalStates[playerstate].jittertype:get_int() == 0 or ConditionalStates[playerstate].jittertype:get_int() == 2 then
            refs.jitterrange:set_int(ConditionalStates[playerstate].jitterrange:get_int());
        else
            refs.jitterrange:set_int(0);
        end
    --desync
    if ConditionalStates[playerstate].desync:get_int() == 60 and ConditionalStates[playerstate].desynctype:get_int() == 0 then
        refs.desync:set_int((ConditionalStates[playerstate].desync:get_int() * 1.666666667) - 2);
        else if ConditionalStates[playerstate].desync:get_int() == -60 and ConditionalStates[playerstate].desynctype:get_int() == 0 then
            refs.desync:set_int((ConditionalStates[playerstate].desync:get_int() * 1.666666667) + 2);
              else if ConditionalStates[playerstate].desynctype:get_int() == 0 then
                refs.desync:set_int(ConditionalStates[playerstate].desync:get_int() * 1.666666667);
                    else if ConditionalStates[playerstate].desynctype:get_int() == 1 and 0 >= ConditionalStates[playerstate].desync:get_int() then
                        refs.desync:set_int(global_vars.tickcount % 4 >= 2 and -18 * 1.666666667 or ConditionalStates[playerstate].desync:get_int() * 1.666666667 + 2);
                            else if ConditionalStates[playerstate].desynctype:get_int() == 1 and ConditionalStates[playerstate].desync:get_int() >= 0 then
                                refs.desync:set_int(global_vars.tickcount % 4 >= 2 and 18 * 1.666666667 or ConditionalStates[playerstate].desync:get_int() * 1.666666667 - 2);
                                    else if ConditionalStates[playerstate].desynctype:get_int() == 2 and ConditionalStates[playerstate].desync:get_int() >= 0 then
                                        refs.desync:set_int(utils.random_int(0, ConditionalStates[playerstate].desync:get_int() * 1.666666667));
                                            else if ConditionalStates[playerstate].desynctype:get_int() == 2 and ConditionalStates[playerstate].desync:get_int() <= 0 then
                                                refs.desync:set_int(utils.random_int(ConditionalStates[playerstate].desync:get_int() * 1.666666667, 0));
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
    refs.compAngle:set_int(ConditionalStates[playerstate].compAngle:get_int());
    refs.flipJittFake:set_bool(ConditionalStates[playerstate].flipJittFake:get_bool());
end
--end of getting AA states and setting valeus

--start of static freestand
local AAfreestand = Find("Rage>Anti-Aim>Angles>Freestand")
local add = Find("Rage>Anti-Aim>Angles>Add")
local jitter = Find("Rage>Anti-Aim>Angles>Jitter Range")
local attargets = Find("Rage>Anti-Aim>Angles>At fov target")
local flipfake = Find("Rage>Anti-Aim>Desync>Flip fake with jitter")
local compfreestand = Find("Rage>Anti-Aim>Desync>Compensate Angle")
local fakefreestand = Find("Rage>Anti-Aim>Desync>Fake Amount")
local freestandfake  = Find("Rage>Anti-Aim>Desync>Freestand Fake")
local add_backup = add:get_int()
local jitter_backup = jitter:get_int()
local attargets_backup = attargets:get_bool()
local flipfake_backup = flipfake:get_bool()
local compfreestand_backup = compfreestand:get_int()
local fakefreestand_backup = fakefreestand:get_int()
local freestandfake_backup = freestandfake:get_int()
local restore_aa = false

local function StaticFreestand()
    if AAfreestand:get_bool() and StaticFS:get_bool() then
        add:set_int(0)
        jitter:set_int(0)
        flipfake:set_bool(false)
        compfreestand:set_int(0)
        freestandfake:set_int(0)
        restore_aa = true
    else
        if (restore_aa == true) then
            add:set_int(add_backup)
            jitter:set_int(jitter_backup)
            attargets:set_bool(attargets_backup)
            flipfake:set_bool(flipfake_backup)
            compfreestand:set_int(compfreestand_backup)
            freestandfake:set_int(freestandfake_backup)
            restore_aa = false
        else
            add_backup = add:get_int()
            jitter_backup = jitter:get_int()
            attargets_backup = attargets:get_bool()
            flipfake_backup = flipfake:get_bool()
            compfreestand_backup = compfreestand:get_int()
            freestandfake_backup = freestandfake:get_int()
        end
    end
end
--end of static freestand
local add = Find("Rage>Anti-Aim>Angles>Add")
local fakeangle = Find("Rage>Anti-Aim>Desync>Fake Amount")
local fakeamount = fakeangle:get_int() >= 0

local function fakeflick()
    if FF:get_bool() then
        if global_vars.tickcount % 19 == 13 and fakeangle:get_int() >= 0 then
            add:set_int(92)
        else
            if global_vars.tickcount % 19 == 13 and 0 >= fakeangle:get_int() then
                add:set_int(-92)
            end
        end
    end
end
--end of fakeflick
local fakeangle = Find("Rage>Anti-Aim>Desync>Fake Amount")
local function InvertDesync()
    if IV:get_bool() then
        fakeangle:set_int(fakeangle:get_int() * -1)
    end
end
--end of inverter
--aa end

--syncing clantag
local old_time = 0;
local animation = {

    "豕 SwinYaw 豕",
    "豕 SwinYaw 豕",
    "豕 SwinYaw 豕",
    "豕 SwinYaw 豕",
    "豕 SwinYa  豕",
    "豕 SwinY   豕",
    "豕 Swin    豕",
    "豕 Sw     豕",
    "豕 Sw      豕",
    "豕        豕",
    "豕 Sw      豕",
    "豕 Swi     豕",
    "豕 Swin    豕",
    "豕 SwinY   豕",
    "豕 SwinYa  豕",
    "豕 SwinYaw 豕",
    "豕 SwinYaw 豕",
    "豕 SwinYaw 豕",
    "豕 SwinYaw 豕",
    
}

--clantag menu element
local function CT()
    if clantagmain:get_bool() then
        local defaultct = Find("misc>various>clan tag")
        local realtime = math.floor((global_vars.realtime) * 1.725)
        if old_time ~= realtime then
            utils.set_clan_tag(animation[realtime % #animation+1]);
        old_time = realtime;
        defaultct:set_bool(false);
        end
    end
end
--clantag end

--import and export system
configs.import = function(input)
    local protected = function()
        local clipboardP = input == nil and dec(clipboard.get()) or input
        local tbl = str_to_sub(clipboardP, "|")
        ConditionalStates[1].yawadd:set_bool(to_boolean(tbl[1]))
        ConditionalStates[1].yawaddamount:set_int(tonumber(tbl[2]))
        ConditionalStates[1].spin:set_bool(to_boolean(tbl[3]))
        ConditionalStates[1].spinrange:set_int(tonumber(tbl[4]))
        ConditionalStates[1].spinspeed:set_int(tonumber(tbl[5]))
        ConditionalStates[1].jitter:set_bool(to_boolean(tbl[6]))
        ConditionalStates[1].jittertype:set_int(tonumber(tbl[7]))
        ConditionalStates[1].jitterrange:set_int(tonumber(tbl[8]))
        ConditionalStates[1].desynctype:set_int(tonumber(tbl[9]))
        ConditionalStates[1].desync:set_int(tonumber(tbl[10]))
        ConditionalStates[1].compAngle:set_int(tonumber(tbl[11]))
        ConditionalStates[1].flipJittFake:set_bool(to_boolean(tbl[12]))
        ConditionalStates[2].yawadd:set_bool(to_boolean(tbl[15]))
        ConditionalStates[2].yawaddamount:set_int(tonumber(tbl[16]))
        ConditionalStates[2].spin:set_bool(to_boolean(tbl[17]))
        ConditionalStates[2].spinrange:set_int(tonumber(tbl[18]))
        ConditionalStates[2].spinspeed:set_int(tonumber(tbl[19]))
        ConditionalStates[2].jitter:set_bool(to_boolean(tbl[20]))
        ConditionalStates[2].jittertype:set_int(tonumber(tbl[21]))
        ConditionalStates[2].jitterrange:set_int(tonumber(tbl[22]))
        ConditionalStates[2].desynctype:set_int(tonumber(tbl[23]))
        ConditionalStates[2].desync:set_int(tonumber(tbl[24]))
        ConditionalStates[2].compAngle:set_int(tonumber(tbl[25]))
        ConditionalStates[2].flipJittFake:set_bool(to_boolean(tbl[26]))
        ConditionalStates[3].yawadd:set_bool(to_boolean(tbl[29]))
        ConditionalStates[3].yawaddamount:set_int(tonumber(tbl[30]))
        ConditionalStates[3].spin:set_bool(to_boolean(tbl[31]))
        ConditionalStates[3].spinrange:set_int(tonumber(tbl[32]))
        ConditionalStates[3].spinspeed:set_int(tonumber(tbl[33]))
        ConditionalStates[3].jitter:set_bool(to_boolean(tbl[34]))
        ConditionalStates[3].jittertype:set_int(tonumber(tbl[35]))
        ConditionalStates[3].jitterrange:set_int(tonumber(tbl[36]))
        ConditionalStates[3].desynctype:set_int(tonumber(tbl[37]))
        ConditionalStates[3].desync:set_int(tonumber(tbl[38]))
        ConditionalStates[3].compAngle:set_int(tonumber(tbl[39]))
        ConditionalStates[3].flipJittFake:set_bool(to_boolean(tbl[40]))
        ConditionalStates[4].yawadd:set_bool(to_boolean(tbl[43]))
        ConditionalStates[4].yawaddamount:set_int(tonumber(tbl[44]))
        ConditionalStates[4].spin:set_bool(to_boolean(tbl[45]))
        ConditionalStates[4].spinrange:set_int(tonumber(tbl[46]))
        ConditionalStates[4].spinspeed:set_int(tonumber(tbl[47]))
        ConditionalStates[4].jitter:set_bool(to_boolean(tbl[48]))
        ConditionalStates[4].jittertype:set_int(tonumber(tbl[49]))
        ConditionalStates[4].jitterrange:set_int(tonumber(tbl[50]))
        ConditionalStates[4].desync:set_int(tonumber(tbl[51]))
        ConditionalStates[4].desynctype:set_int(tonumber(tbl[52]))
        ConditionalStates[4].compAngle:set_int(tonumber(tb4l[53]))
        ConditionalStates[4].flipJittFake:set_bool(to_boolean(tbl[54]))
        ConditionalStates[5].yawadd:set_bool(to_boolean(tbl[57]))
        ConditionalStates[5].yawaddamount:set_int(tonumber(tbl[58]))
        ConditionalStates[5].spin:set_bool(to_boolean(tbl[59]))
        ConditionalStates[5].spinrange:set_int(tonumber(tbl[60]))
        ConditionalStates[5].spinspeed:set_int(tonumber(tbl[61]))
        ConditionalStates[5].jitter:set_bool(to_boolean(tbl[62]))
        ConditionalStates[5].jittertype:set_int(tonumber(tbl[63]))
        ConditionalStates[5].jitterrange:set_int(tonumber(tbl[64]))
        ConditionalStates[5].desynctype:set_int(tonumber(tbl[65]))
        ConditionalStates[5].desync:set_int(tonumber(tbl[66]))
        ConditionalStates[5].compAngle:set_int(tonumber(tbl[67]))
        ConditionalStates[5].flipJittFake:set_bool(to_boolean(tbl[68]))
        ConditionalStates[6].yawadd:set_bool(to_boolean(tbl[71]))
        ConditionalStates[6].yawaddamount:set_int(tonumber(tbl[72]))
        ConditionalStates[6].spin:set_bool(to_boolean(tbl[73]))
        ConditionalStates[6].spinrange:set_int(tonumber(tbl[74]))
        ConditionalStates[6].spinspeed:set_int(tonumber(tbl[75]))
        ConditionalStates[6].jitter:set_bool(to_boolean(tbl[76]))
        ConditionalStates[6].jittertype:set_int(tonumber(tbl[77]))
        ConditionalStates[6].jitterrange:set_int(tonumber(tbl[78]))
        ConditionalStates[6].desynctype:set_int(tonumber(tbl[79]))
        ConditionalStates[6].desync:set_int(tonumber(tbl[80]))
        ConditionalStates[6].compAngle:set_int(tonumber(tbl[81]))
        ConditionalStates[6].flipJittFake:set_bool(to_boolean(tbl[82]))


        print("Config loaded")
        
    end
    local status, message = pcall(protected)
    if not status then
        print("Failed to load config")
        return
    end
end


configs.export = function()
    local str = {
        tostring(ConditionalStates[1].yawadd:get_bool()) .. "|",
        tostring(ConditionalStates[1].yawaddamount:get_int()) .. "|",
        tostring(ConditionalStates[1].spin:get_bool()) .. "|",
        tostring(ConditionalStates[1].spinrange:get_int()) .. "|",
        tostring(ConditionalStates[1].spinspeed:get_int()) .. "|",
        tostring(ConditionalStates[1].jitter:get_bool()) .. "|",
        tostring(ConditionalStates[1].jittertype:get_int()) .. "|",
        tostring(ConditionalStates[1].jitterrange:get_int()) .. "|",
        tostring(ConditionalStates[1].desynctype:get_int()) .. "|",
        tostring(ConditionalStates[1].desync:get_int()) .. "|",
        tostring(ConditionalStates[1].compAngle:get_int()) .. "|",
        tostring(ConditionalStates[1].flipJittFake:get_bool()) .. "|",
        tostring(ConditionalStates[2].yawadd:get_bool()) .. "|",
        tostring(ConditionalStates[2].yawaddamount:get_int()) .. "|",
        tostring(ConditionalStates[2].spin:get_bool()) .. "|",
        tostring(ConditionalStates[2].spinrange:get_int()) .. "|",
        tostring(ConditionalStates[2].spinspeed:get_int()) .. "|",
        tostring(ConditionalStates[2].jitter:get_bool()) .. "|",
        tostring(ConditionalStates[2].jittertype:get_int()) .. "|",
        tostring(ConditionalStates[2].jitterrange:get_int()) .. "|",
        tostring(ConditionalStates[2].desynctype:get_int()) .. "|",
        tostring(ConditionalStates[2].desync:get_int()) .. "|",
        tostring(ConditionalStates[2].compAngle:get_int()) .. "|",
        tostring(ConditionalStates[2].flipJittFake:get_bool()) .. "|",
        tostring(ConditionalStates[3].yawadd:get_bool()) .. "|",
        tostring(ConditionalStates[3].yawaddamount:get_int()) .. "|",
        tostring(ConditionalStates[3].spin:get_bool()) .. "|",
        tostring(ConditionalStates[3].spinrange:get_int()) .. "|",
        tostring(ConditionalStates[3].spinspeed:get_int()) .. "|",
        tostring(ConditionalStates[3].jitter:get_bool()) .. "|",
        tostring(ConditionalStates[3].jittertype:get_int()) .. "|",
        tostring(ConditionalStates[3].jitterrange:get_int()) .. "|",
        tostring(ConditionalStates[3].desynctype:get_int()) .. "|",
        tostring(ConditionalStates[3].desync:get_int()) .. "|",
        tostring(ConditionalStates[3].compAngle:get_int()) .. "|",
        tostring(ConditionalStates[3].flipJittFake:get_bool()) .. "|",
        tostring(ConditionalStates[4].yawadd:get_bool()) .. "|",
        tostring(ConditionalStates[4].yawaddamount:get_int()) .. "|",
        tostring(ConditionalStates[4].spin:get_bool()) .. "|",
        tostring(ConditionalStates[4].spinrange:get_int()) .. "|",
        tostring(ConditionalStates[4].spinspeed:get_int()) .. "|",
        tostring(ConditionalStates[4].jitter:get_bool()) .. "|",
        tostring(ConditionalStates[4].jittertype:get_int()) .. "|",
        tostring(ConditionalStates[4].jitterrange:get_int()) .. "|",
        tostring(ConditionalStates[4].desynctype:get_int()) .. "|",
        tostring(ConditionalStates[4].desync:get_int()) .. "|",
        tostring(ConditionalStates[4].compAngle:get_int()) .. "|",
        tostring(ConditionalStates[4].flipJittFake:get_bool()) .. "|",
        tostring(ConditionalStates[5].yawadd:get_bool()) .. "|",
        tostring(ConditionalStates[5].yawaddamount:get_int()) .. "|",
        tostring(ConditionalStates[5].spin:get_bool()) .. "|",
        tostring(ConditionalStates[5].spinrange:get_int()) .. "|",
        tostring(ConditionalStates[5].spinspeed:get_int()) .. "|",
        tostring(ConditionalStates[5].jitter:get_bool()) .. "|",
        tostring(ConditionalStates[5].jittertype:get_int()) .. "|",
        tostring(ConditionalStates[5].jitterrange:get_int()) .. "|",
        tostring(ConditionalStates[5].desynctype:get_int()) .. "|",
        tostring(ConditionalStates[5].desync:get_int()) .. "|",
        tostring(ConditionalStates[5].compAngle:get_int()) .. "|",
        tostring(ConditionalStates[5].flipJittFake:get_bool()) .. "|",
        tostring(ConditionalStates[6].yawadd:get_bool()) .. "|",
        tostring(ConditionalStates[6].yawaddamount:get_int()) .. "|",
        tostring(ConditionalStates[6].spin:get_bool()) .. "|",
        tostring(ConditionalStates[6].spinrange:get_int()) .. "|",
        tostring(ConditionalStates[6].spinspeed:get_int()) .. "|",
        tostring(ConditionalStates[6].jitter:get_bool()) .. "|",
        tostring(ConditionalStates[6].jittertype:get_int()) .. "|",
        tostring(ConditionalStates[6].jitterrange:get_int()) .. "|",
        tostring(ConditionalStates[6].desynctype:get_int()) .. "|",
        tostring(ConditionalStates[6].desync:get_int()) .. "|",
        tostring(ConditionalStates[6].compAngle:get_int()) .. "|",
        tostring(ConditionalStates[6].flipJittFake:get_bool()) .. "|",
    }
    
        clipboard.set(enc(table.concat(str)))
        print("config was copied")

end

configs.importDefault = function(input)
    input = "dHJ1LPWKtcPjpxQzc26CxTtPFuQMNfm2RfEHfKwyfC02LPWKtcPjpxQzc26CxTtPFuQMNfm2RfEHfKCkc1flfDB8MHx0cnVlfDKCCzwKyY9rmBJGu48FrkNLPWKtcPjpxQzc26CxTtPFuQMNfm2RfEHfKHx0cnVlfDKCCzwKyY9rmBJGu48FrkNMro4AWtCkc1f0cnVlfDN8ZmFsc2V8MHwwfHRydWV8MHw1MnwxfC02LPWKtcPjpxQzc26CxTtPFuQMNfm2RfEHfKCkc1f8MHx0cnVlfDKCCzwKyY9rmBJGu48FrkNMro4AWtCkc1f1ZXwzfGZhbHNlfDB8MHx0cnVlfDB8MjR8Mnw2MHwxMDB8dHJ1ZXwwfDB8"
    local clipboardp = dec(input)
    local tbl = str_to_sub(clipboardp, "|")
    ConditionalStates[1].yawadd:set_bool(to_boolean(tbl[1]))
    ConditionalStates[1].yawaddamount:set_int(tonumber(tbl[2]))
    ConditionalStates[1].spin:set_bool(to_boolean(tbl[3]))
    ConditionalStates[1].spinrange:set_int(tonumber(tbl[4]))
    ConditionalStates[1].spinspeed:set_int(tonumber(tbl[5]))
    ConditionalStates[1].jitter:set_bool(to_boolean(tbl[6]))
    ConditionalStates[1].jittertype:set_int(tonumber(tbl[7]))
    ConditionalStates[1].jitterrange:set_int(tonumber(tbl[8]))
    ConditionalStates[1].desynctype:set_int(tonumber(tbl[9]))
    ConditionalStates[1].desync:set_int(tonumber(tbl[10]))
    ConditionalStates[1].compAngle:set_int(tonumber(tbl[11]))
    ConditionalStates[1].flipJittFake:set_bool(to_boolean(tbl[12]))
    ConditionalStates[2].yawadd:set_bool(to_boolean(tbl[15]))
    ConditionalStates[2].yawaddamount:set_int(tonumber(tbl[16]))
    ConditionalStates[2].spin:set_bool(to_boolean(tbl[17]))
    ConditionalStates[2].spinrange:set_int(tonumber(tbl[18]))
    ConditionalStates[2].spinspeed:set_int(tonumber(tbl[19]))
    ConditionalStates[2].jitter:set_bool(to_boolean(tbl[20]))
    ConditionalStates[2].jittertype:set_int(tonumber(tbl[21]))
    ConditionalStates[2].jitterrange:set_int(tonumber(tbl[22]))
    ConditionalStates[2].desynctype:set_int(tonumber(tbl[23]))
    ConditionalStates[2].desync:set_int(tonumber(tbl[24]))
    ConditionalStates[2].compAngle:set_int(tonumber(tbl[25]))
    ConditionalStates[2].flipJittFake:set_bool(to_boolean(tbl[26]))
    ConditionalStates[3].yawadd:set_bool(to_boolean(tbl[29]))
    ConditionalStates[3].yawaddamount:set_int(tonumber(tbl[30]))
    ConditionalStates[3].spin:set_bool(to_boolean(tbl[31]))
    ConditionalStates[3].spinrange:set_int(tonumber(tbl[32]))
    ConditionalStates[3].spinspeed:set_int(tonumber(tbl[33]))
    ConditionalStates[3].jitter:set_bool(to_boolean(tbl[34]))
    ConditionalStates[3].jittertype:set_int(tonumber(tbl[35]))
    ConditionalStates[3].jitterrange:set_int(tonumber(tbl[36]))
    ConditionalStates[3].desynctype:set_int(tonumber(tbl[37]))
    ConditionalStates[3].desync:set_int(tonumber(tbl[38]))
    ConditionalStates[3].compAngle:set_int(tonumber(tbl[39]))
    ConditionalStates[3].flipJittFake:set_bool(to_boolean(tbl[40]))
    ConditionalStates[4].yawadd:set_bool(to_boolean(tbl[43]))
    ConditionalStates[4].yawaddamount:set_int(tonumber(tbl[44]))
    ConditionalStates[4].spin:set_bool(to_boolean(tbl[45]))
    ConditionalStates[4].spinrange:set_int(tonumber(tbl[46]))
    ConditionalStates[4].spinspeed:set_int(tonumber(tbl[47]))
    ConditionalStates[4].jitter:set_bool(to_boolean(tbl[48]))
    ConditionalStates[4].jittertype:set_int(tonumber(tbl[49]))
    ConditionalStates[4].jitterrange:set_int(tonumber(tbl[50]))
    ConditionalStates[4].desync:set_int(tonumber(tbl[51]))
    ConditionalStates[4].desynctype:set_int(tonumber(tbl[52]))
    ConditionalStates[4].compAngle:set_int(tonumber(tbl[53]))
    ConditionalStates[4].flipJittFake:set_bool(to_boolean(tbl[54]))
    ConditionalStates[5].yawadd:set_bool(to_boolean(tbl[57]))
    ConditionalStates[5].yawaddamount:set_int(tonumber(tbl[58]))
    ConditionalStates[5].spin:set_bool(to_boolean(tbl[59]))
    ConditionalStates[5].spinrange:set_int(tonumber(tbl[60]))
    ConditionalStates[5].spinspeed:set_int(tonumber(tbl[61]))
    ConditionalStates[5].jitter:set_bool(to_boolean(tbl[62]))
    ConditionalStates[5].jittertype:set_int(tonumber(tbl[63]))
    ConditionalStates[5].jitterrange:set_int(tonumber(tbl[64]))
    ConditionalStates[5].desynctype:set_int(tonumber(tbl[65]))
    ConditionalStates[5].desync:set_int(tonumber(tbl[66]))
    ConditionalStates[5].compAngle:set_int(tonumber(tbl[67]))
    ConditionalStates[5].flipJittFake:set_bool(to_boolean(tbl[68]))
    ConditionalStates[6].yawadd:set_bool(to_boolean(tbl[71]))
    ConditionalStates[6].yawaddamount:set_int(tonumber(tbl[72]))
    ConditionalStates[6].spin:set_bool(to_boolean(tbl[73]))
    ConditionalStates[6].spinrange:set_int(tonumber(tbl[74]))
    ConditionalStates[6].spinspeed:set_int(tonumber(tbl[75]))
    ConditionalStates[6].jitter:set_bool(to_boolean(tbl[76]))
    ConditionalStates[6].jittertype:set_int(tonumber(tbl[77]))
    ConditionalStates[6].jitterrange:set_int(tonumber(tbl[78]))
    ConditionalStates[6].desynctype:set_int(tonumber(tbl[79]))
    ConditionalStates[6].desync:set_int(tonumber(tbl[80]))
    ConditionalStates[6].compAngle:set_int(tonumber(tbl[81]))
    ConditionalStates[6].flipJittFake:set_bool(to_boolean(tbl[82]))

    print("Config loaded")
end

--callbacks
function on_shutdown()
    utils.set_clan_tag("");
end

function on_create_move()
    UpdateStateandAA()
    StaticFreestand()
    fakeflick()
    InvertDesync()
end

function on_paint()
    MenuElements()
    CT()
end