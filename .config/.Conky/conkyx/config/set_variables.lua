-------------------------------------------------------------------------------
-- set_variables.lua — Conky helper script dispatcher
--
-- Auto-detects the conkyx base directory from this file's location,
-- then picks the best available backend for each helper script:
--   1. C compiled binary  (fastest, needs compilation)
--   2. Shell script       (portable, always works on Linux)
--   3. Python script      (optional, needs python3 + psutil)
--
-- Override the backend by setting CONKY_BACKEND env var to "c", "sh", or "py"
-------------------------------------------------------------------------------

-- Resolve base directory from this file's path
-- This file lives in <conkyx>/config/set_variables.lua
local function get_base_dir()
    local src = debug.getinfo(1, "S").source
    if src:sub(1, 1) == "@" then
        src = src:sub(2)
    end
    -- Strip /config/set_variables.lua to get conkyx root
    return src:match("(.+)/config/set_variables%.lua$") or
           os.getenv("HOME") .. "/.config/.Conky/conkyx"
end

local BASE = get_base_dir()
local SCRIPTS = BASE .. "/scripts"

-- Backend preference: env override or auto-detect per script
local ENV_BACKEND = os.getenv("CONKY_BACKEND")  -- "c" or "sh"

local function is_executable(path)
    local f = io.popen("test -x '" .. path .. "' && echo yes 2>/dev/null")
    local result = f:read("*a")
    f:close()
    return result:match("yes") ~= nil
end

-- Find the best available script for a given name
-- Returns the full command string (tries C binary first, falls back to shell)
local function resolve_script(name, args)
    args = args or ""

    local candidates
    if ENV_BACKEND == "c" then
        candidates = { SCRIPTS .. "/C/" .. name }
    elseif ENV_BACKEND == "sh" then
        candidates = { SCRIPTS .. "/sh/" .. name }
    else
        candidates = {
            SCRIPTS .. "/C/" .. name,
            SCRIPTS .. "/sh/" .. name,
        }
    end

    for _, cmd in ipairs(candidates) do
        if is_executable(cmd) then
            if args ~= "" then return cmd .. " " .. args end
            return cmd
        end
    end

    -- Fallback to shell (will produce "N/A" if missing)
    return SCRIPTS .. "/sh/" .. name .. (args ~= "" and (" " .. args) or "")
end

-- Run a script and return its output (trimmed)
local function run(name, args)
    local cmd = resolve_script(name, args)
    local f = io.popen(cmd)
    local output = f:read("*a") or ""
    f:close()
    return output:gsub("%s+$", "")
end

-------------------------------------------------------------------------------
-- Conky functions (called from conkyrc via: ${lua conky_function_name})
-------------------------------------------------------------------------------

function conky_get_essid()
    return run("wireless-essid")
end

function conky_get_journal()
    local f = io.popen("journalctl -n 5 --no-pager -o short 2>/dev/null | awk '{ $1=$2=$3=\"\"; print substr($0,4) }'")
    local l = f:read("*a") or ""
    f:close()
    return l
end

function conky_get_wan_ip()
    return run("wan")
end

function conky_get_lan_ip()
    return run("lan")
end

function conky_get_downspeed()
    return run("interfacedownspeed")
end

function conky_get_upspeed()
    return run("interfaceupspeed")
end

function conky_battery_status()
    return run("battery_status")
end

function conky_battery_condition()
    return run("battery_condition")
end

function conky_get_totalmem()
    return run("totalmem")
end

function conky_get_usedmem()
    return run("usedmem")
end

function conky_get_totalswap()
    return run("totalswap")
end

function conky_get_freeswap()
    return run("freeswap")
end

function conky_get_usedswap()
    return run("usedswap")
end

function conky_get_freemem()
    return run("freemem")
end

function conky_get_moonphase()
    return run("moon_phase")
end

-- Weather: location code can be overridden via CONKY_WEATHER_LOCATION env var
function conky_get_weather()
    local location = os.getenv("CONKY_WEATHER_LOCATION") or "48178"
    return run("weather", location)
end

-- Core temps: one function per core slot (1-4)
function conky_get_core_temp_1()
    return run("core_temps", "1")
end

function conky_get_core_temp_2()
    return run("core_temps", "2")
end

function conky_get_core_temp_3()
    return run("core_temps", "3")
end

function conky_get_core_temp_4()
    return run("core_temps", "4")
end
