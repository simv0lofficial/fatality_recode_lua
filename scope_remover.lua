local debugfov = cvar.fov_cs_debug
local fov = gui.get_config_item("visuals>view>camera>fov")
function on_paint()
    if fov:get_int() ~= debugfov:get_int() then
        debugfov:set_int(fov:get_int())
    end
end