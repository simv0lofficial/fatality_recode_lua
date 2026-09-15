--.name Kill Voice
--.description Plays voice_input.wav over voice chat on kill
--.author Gemini 3.8 Flash High

-- Sound length in seconds (default F12 sound length is ~0.6s)
local snd_time = 0.6

-- Menu setup
local active = gui.add_checkbox("Kill voice", "lua>tab a")

-- ConVars
local loopback = cvar.voice_loopback
local fileinput = cvar.voice_inputfromfile

if not loopback or not fileinput then
    print("[kill_voice] Error: voice cvars could not be found.")
    return
end

-- Playback state
local is_playing = false
local stop_time = 0
local warned_missing = false

-- Check if sound file exists next to csgo.exe
local function sound_exists(name)
    if fs and fs.exists then
        return fs.exists(name)
    end
    return true
end

-- Force reset voice cvars and stop voice recording
local function force_reset()
    loopback:set_int(0)
    fileinput:set_int(0)
    engine.exec("-voicerecord")
    is_playing = false
end

-- Start voice playback
local function play_voice()
    loopback:set_int(1)
    fileinput:set_int(1)
    engine.exec("+voicerecord")

    stop_time = global_vars.realtime + snd_time
    is_playing = true
end

-- Stop voice playback
local function stop_voice()
    if not is_playing then
        return
    end
    force_reset()
end

-- Game event forward
function on_game_event(event)
    if not active:get_bool() then
        return
    end

    if event:get_name() ~= "player_death" then
        return
    end

    if not sound_exists("voice_input.wav") then
        if not warned_missing then
            print("[kill_voice] voice_input.wav not found next to csgo.exe!")
            warned_missing = true
        end
        return
    end
    warned_missing = false

    local attacker_userid = event:get_int("attacker")
    local victim_userid = event:get_int("userid")

    if attacker_userid == 0 or victim_userid == 0 then
        return
    end

    local local_player = engine.get_local_player()
    local attacker = engine.get_player_for_user_id(attacker_userid)
    local victim = engine.get_player_for_user_id(victim_userid)

    if attacker == 0 or victim == 0 then
        return
    end

    -- Trigger only when local player kills someone else (not on suicide)
    if attacker == local_player and victim ~= local_player then
        play_voice()
    end
end

-- Frame render forward (used for timing playback)
function on_paint()
    if is_playing and global_vars.realtime >= stop_time then
        stop_voice()
    end
end

-- Unload forward
function on_shutdown()
    force_reset()
end

-- Initial state reset on script load
force_reset()

if not sound_exists("voice_input.wav") then
    print("[kill_voice] Note: Put voice_input.wav in your CS:GO folder to use kill voice.")
end

print("[kill_voice] Script loaded successfully.")