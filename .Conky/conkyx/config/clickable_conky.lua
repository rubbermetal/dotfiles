local clicked_last_check = false

function conky_main()
    if conky_window == nil then
        return
    end

    -- Assuming the CPU usage area starts at (10, 10) and has a size of (100, 50)
    local x, y = 10, 10
    local w, h = 100, 50

    if is_mouse_click_in_area(x, y, w, h) then
        os.execute("terminator &")
    end
end

function is_mouse_click_in_area(x, y, w, h)
    -- Get the mouse state using xdotool
    local mouse_state = os.capture("xdotool getmouselocation --shell")
    local mouseX = tonumber(string.match(mouse_state, "X=(%d+)"))
    local mouseY = tonumber(string.match(mouse_state, "Y=(%d+)"))
    local mouse_button = os.capture("xinput --query-state $(xdotool getmouselocation --shell | awk -F= '/id:/ {print $2}') | grep 'button\\[1]='")

    local is_clicked = mouse_button:find("down")

    -- Check if click is inside the area
    local is_inside = mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h

    -- Ensure only one action per click
    if is_clicked and not clicked_last_check and is_inside then
        clicked_last_check = true
        return true
    elseif not is_clicked then
        clicked_last_check = false
    end

    return false
end

function os.capture(cmd, raw)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
end
