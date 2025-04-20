local Debug = {}
Debug.messages = {}
Debug.font = love.graphics.newFont(12)
Debug.visible = true -- Start with debug visible

-- Toggle debug visibility
function Debug.toggle()
    Debug.visible = not Debug.visible
    table.insert(Debug.messages, "Debug visibility toggled: " .. tostring(Debug.visible))
end

-- Add a message to the debug screen
function Debug.print(msg)
    table.insert(Debug.messages, msg)
    -- Limit the number of messages to prevent memory issues
    if #Debug.messages > 100 then
        table.remove(Debug.messages, 1)
    end
end

-- Render the debug messages on the screen
function Debug.draw()
    if not Debug.visible then return end

    love.graphics.setFont(Debug.font)
    love.graphics.setColor(0, 0, 0, 0.5) -- Semi-transparent background
    love.graphics.rectangle("fill", 5, 5, 300, #Debug.messages * 15 + 10)

    love.graphics.setColor(1, 1, 1, 1) -- White color for text
    local y = 10
    for i = #Debug.messages, 1, -1 do
        love.graphics.print(Debug.messages[i], 10, y)
        y = y + 15
    end
end

return Debug
