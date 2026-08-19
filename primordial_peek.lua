local function vtable_bind(class, _type, index)
    local this = ffi.cast("void***", class)
    local ffitype = ffi.typeof(_type)
    return function (...)
        return ffi.cast(ffitype, this[0][index])(this, ...)
    end
end

local function vtable_thunk(_type, index)
    local ffitype = ffi.typeof(_type)
    return function (class, ...)
        local this = ffi.cast("void***", class)
        return ffi.cast(ffitype, this[0][index])(this, ...)
    end
end

ffi.cdef[[ struct vec3_t{ float x, y, z; }; ]]
local vec3_t        = ffi.typeof("struct vec3_t")
local nullchar      = ffi.cast("const char*", 0)

local IEffects          = utils.find_interface("client.dll", "IEffects001")
local EnergySplash      = vtable_bind(IEffects, "void(__thiscall*)(void*, const struct vec3_t&, const struct vec3_t&, bool)", 7)

local IMaterialSystem   = utils.find_interface("materialsystem.dll",	"VMaterialSystem080")
local FindMaterial      = vtable_bind(IMaterialSystem, "void*(__thiscall*)(void*, const char*, const char*, bool, const char*)", 84)
local AlphaModulate     = vtable_thunk("void(__thiscall*)(void*, float)", 27)
local ColorModulate     = vtable_thunk("void(__thiscall*)(void*, float, float, float)", 28)




local AutoPeek  = gui.get_config_item("misc>movement>peek assist")
local Master    = gui.add_checkbox("Custom peek assist", "misc>movement")
local Color     = gui.add_colorpicker("misc>movement>Custom peek assist", true, render.color(0, 150, 255, 255))

local AutoPeekPos = nil
local SparkMaterial = nil

local OldTickCount = -1
function on_paint()
    if not Master:get_bool() then
        AutoPeekPos = nil
        return
    end

    -- This fixes the issue of cmd callbacks not being called while recharging dt
    if OldTickCount == global_vars.tickcount then
        return
    else
        OldTickCount = global_vars.tickcount
    end

    local LocalPlayer = entities.get_entity(engine.get_local_player())
    if not AutoPeek:get_bool() or not LocalPlayer then
        AutoPeekPos = nil
        return
    end

    if not AutoPeekPos then
        if bit.band(LocalPlayer:get_prop("m_fFlags"), 1) == 1 then
            AutoPeekPos = math.vec3(LocalPlayer:get_prop("m_vecOrigin"))
        else
            return
        end
    end

    if not SparkMaterial then
        SparkMaterial = FindMaterial("effects/spark", nullchar, true, nullchar)
    else
        local ColorTable = Color:get_color()

        AlphaModulate(SparkMaterial, ColorTable.a / 255)
        ColorModulate(SparkMaterial, ColorTable.r / 255, ColorTable.g / 255, ColorTable.b / 255)
    end

    local Angle = (global_vars.realtime * 6) % 360
    EnergySplash(vec3_t((AutoPeekPos + math.vec3(math.cos(Angle), math.sin(Angle), 0) * 30):unpack()), vec3_t(), false)
end