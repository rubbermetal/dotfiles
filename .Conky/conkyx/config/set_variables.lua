function conky_get_variable(var_name)
    local variables = {
    wireless = "python3 /home/madhatter/.Conky/conkyx/scripts/wireless-essid.py"
    }
    return variables[var_name]
end
function conky_get_essid()
    local file = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/wireless-essid")
    local output = file:read("*a")
    file:close()
     output = string.gsub(output, "\n", "")
    return output
end
function conky_get_journal()
    local f = io.popen("journalctl -n 5 --no-pager -o short | awk '{ gsub(\"archlinux\", \"\"); print substr($0, index($0, $4)) }'")
    local l = f:read("*a")
    f:close()
    return l
end
function conky_get_wan_ip()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/wan")
    local ip = f:read("*a")
    f:close()
    ip = string.gsub(ip, "\n", "")
    return ip
end
function conky_get_lan_ip()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/lan")
    local ip = f:read("*a")
    f:close()
    ip = string.gsub(ip, "\n", "")
    return ip
end
function conky_get_downspeed()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/interfacedownspeed")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
function conky_get_upspeed()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/interfaceupspeed")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
function conky_battery_status()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/battery_status")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
function conky_battery_condition()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/battery_condition")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
function conky_get_totalmem()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/totalmem")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
function conky_get_usedmem()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/usedmem")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
function conky_get_totalswap()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/totalswap")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
function conky_get_freeswap()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/freeswap")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
function conky_get_usedswap()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/usedswap")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
function conky_get_moonphase()
    local f = io.popen("/home/madhatter/.Conky/conkyx/scripts/C/moon_phase")
    local output = f:read("*a")
    f:close()
    output = string.gsub(output, "\n", "")
    return output
end
