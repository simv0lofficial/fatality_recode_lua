--.name African Skin (r_skin)
--.description Forces player model skin variation (r_skin) in CS:GO
--.author simv0l

local TAB_PATH = "lua>tab a"

-- Menu controls
local opt_enable = gui.add_checkbox("African skin", TAB_PATH)
local opt_skin   = gui.add_slider("Skin index", TAB_PATH, 0, 5, 1)

-- Set default skin index to 1 on first launch
if opt_skin:get_int() == 0 then
    opt_skin:set_int(1)
end

-- Store original value to restore on disable or shutdown
local rskin = cvar["r_skin"]
local original_skin = 0
if rskin then
    local ok, val = pcall(function() return rskin:get_int() end)
    if ok and val then
        original_skin = val
    end
end

local was_enabled = false

local function apply_skin_value(val)
    if rskin then
        pcall(function() rskin:set_int(val) end)
    end
    if engine.exec then
        pcall(function() engine.exec("r_skin " .. tostring(val)) end)
    end
end

--------------------------------------------------------------------------------
-- Frame Callback
--------------------------------------------------------------------------------
function on_paint()
    if not engine.is_in_game() then return end

    local is_enabled = opt_enable:get_bool()
    if is_enabled then
        was_enabled = true
        local target_val = opt_skin:get_int()
        local cur_val = rskin and rskin:get_int() or nil
        if cur_val ~= target_val then
            apply_skin_value(target_val)
        end
    elseif was_enabled then
        was_enabled = false
        apply_skin_value(original_skin)
    end
end

--------------------------------------------------------------------------------
-- Shutdown Callback
--------------------------------------------------------------------------------
function on_shutdown()
    apply_skin_value(original_skin)
end