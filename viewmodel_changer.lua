local function vtable_bind( class, _type, index )
    local this = ffi.cast( "void***", class )
    local ffitype = ffi.typeof( _type )
    return function ( ... )
        return ffi.cast( ffitype, this[ 0 ][ index ] )( this, ... )
    end
end

local IConsole = utils.find_interface( "vstdlib.dll", "VEngineCvar007" )
local GetConvarFN = vtable_bind( IConsole, "unsigned int(__thiscall*)(void*, char*)", 15 )

local BackupCallbackSize = { }

local function SetCallbacks( cvar, n )
    if not cvar then return end
    BackupCallbackSize[ cvar ] = ffi.cast( "unsigned int*", cvar + 0x60 )[ 0 ]
    ffi.cast( "unsigned int*", cvar + 0x60 )[ 0 ] = n or 0
end

SetCallbacks( GetConvarFN( ffi.cast( "char*", "viewmodel_offset_x" ) ) )
SetCallbacks( GetConvarFN( ffi.cast( "char*", "viewmodel_offset_y" ) ) )
SetCallbacks( GetConvarFN( ffi.cast( "char*", "viewmodel_offset_z" ) ) )

-- the funny cvars
local viewmodel_x = cvar.viewmodel_offset_x
local viewmodel_y = cvar.viewmodel_offset_y
local viewmodel_z = cvar.viewmodel_offset_z

-- menu additions
local viewmodel_master_boolean = gui.add_checkbox( "Enable viewmodel changer", "visuals>view>viewmodel" )
local viewmodel_x_slider = gui.add_slider( "Viewmodel X", "visuals>view>viewmodel", -40, 40, 1 )
local viewmodel_y_slider = gui.add_slider( "Viewmodel Y", "visuals>view>viewmodel", -40, 40, 1 )
local viewmodel_z_slider = gui.add_slider( "Viewmodel Z", "visuals>view>viewmodel", -40, 40, 1 )

-- for restoring our original viewmodel
local cached_viewmodel_data = {
    cached_default_viewmodel_x = cvar.viewmodel_offset_x,
    cached_default_viewmodel_y = cvar.viewmodel_offset_y,
    cached_default_viewmodel_z = cvar.viewmodel_offset_z,
    cached_viewmodel = true
}

-- main func
local function change_viewmodel( )
    if viewmodel_master_boolean:get_bool( ) then
        if cached_viewmodel_data.cached_viewmodel then
            cached_viewmodel_data.cached_default_viewmodel_x = viewmodel_x:get_float( )
            cached_viewmodel_data.cached_default_viewmodel_y = viewmodel_y:get_float( )
            cached_viewmodel_data.cached_default_viewmodel_z = viewmodel_z:get_float( )
            cached_viewmodel_data.cached_viewmodel = false
        end
        -- change our viewmodel!
        viewmodel_x:set_float( viewmodel_x_slider:get_float( ) )
        viewmodel_y:set_float( viewmodel_y_slider:get_float( ) )
        viewmodel_z:set_float( viewmodel_z_slider:get_float( ) )
     
    else
        if not cached_viewmodel_data.cached_viewmodel then
            viewmodel_x:set_float( cached_viewmodel_data.cached_default_viewmodel_x )
            viewmodel_y:set_float( cached_viewmodel_data.cached_default_viewmodel_y )
            viewmodel_z:set_float( cached_viewmodel_data.cached_default_viewmodel_z )
            cached_viewmodel_data.cached_viewmodel = true
        end
    end
end

function on_paint( )
    change_viewmodel( )
end

-- restore original viewmodel if we unload the lua
function on_shutdown( )
    viewmodel_x:set_float( cached_viewmodel_data.cached_default_viewmodel_x )
    viewmodel_y:set_float( cached_viewmodel_data.cached_default_viewmodel_y )
    viewmodel_z:set_float( cached_viewmodel_data.cached_default_viewmodel_z )
    cached_viewmodel_data.cached_viewmodel = true
    for i, v in pairs( BackupCallbackSize ) do
        SetCallbacks( i, v )
    end
end