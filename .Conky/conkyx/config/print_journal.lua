function conky_get_journal()
    local f = io.popen("journalctl -n 5 --no-pager -o short | awk '{ gsub(\"archlinux\", \"\"); print substr($0, index($0, $4)) }'")
    local l = f:read("*a")
    f:close()
    return l
end
