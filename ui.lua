local UI = {}
UI.__index = UI

function UI.new(player, experience)
    local self = setmetatable({}, UI)
    self.player = player
    self.experience = experience
    self.upgradeOptionsVisible = false
    self.upgradeOptions = {}
    self.onUpgradeSelected = nil

    -- Load gothic fonts with error handling
    self.fonts = {}
    local success, err = pcall(function()
        self.fonts.title = love.graphics.newFont("fonts/gothic.ttf", 36) -- Ensure the path is correct
        self.fonts.subtitle = love.graphics.newFont("fonts/gothic.ttf", 18)
    end)
    if not success then
       
        -- Fallback to default font
        self.fonts.title = love.graphics.getFont()
        self.fonts.subtitle = love.graphics.getFont()
    end
    
    -- Load ornate frame image (optional)
    -- Uncomment the following lines if you have an ornate frame image
    -- self.ornateFrame = love.graphics.newImage("assets/ornate_frame.png")
    
    return self
end

function UI:update(dt)
    -- Update UI elements if necessary
end

function UI:draw()
    -- Get current window size
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Define smaller sizes for the bars
    local barWidth = 150  -- Reduced width for the health bars
    local barHeight = 15  -- Reduced height
    local x = 10  -- Top-left corner for health bars
    local y = 10  -- Start Y position

    -- Ensure no blurriness by setting the filter to nearest
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- === Draw Health Bars for Each Hero at the Top Left ===
    for _, char in pairs(self.player.characters) do
        -- Draw Background Health Bar
        love.graphics.setColor(0.2, 0.2, 0.2) -- Darker gray for background
        love.graphics.rectangle("fill", x, y, barWidth, barHeight)

        -- Set health bar color based on character type
        if char.type == "ranger" then
            love.graphics.setColor(0, 1, 0) -- Green for Ranger
        elseif char.type == "mage" then
            love.graphics.setColor(1, 0, 0) -- Red for Mage
        elseif char.type == "spearwarden" then
            love.graphics.setColor(1, 1, 0) -- Yellow for Spearwarden
        end

        -- Draw Health Bar Fill
        local healthRatio = math.max(char.health / char.maxHealth, 0)
        love.graphics.rectangle("fill", x, y, barWidth * healthRatio, barHeight)
        
         -- Draw Character Type (Ranger, Mage, Spearwarden) inside the Health Bar
        love.graphics.setColor(0, 0, 0) -- Black color for text
        love.graphics.setFont(self.fonts.subtitle)
        local className = string.format("%s", char.type)  -- Only class name, no health numbers
        local textY = y + (barHeight - self.fonts.subtitle:getHeight()) / 2
        love.graphics.printf(className, x + 5, textY, barWidth - 10, "left")

        -- Move Y position for the next hero
        y = y + barHeight + 5  -- 5 pixels of padding between bars
    end

    -- === Draw Experience Bar with Level on Top Center ===
    local topBarY = screenHeight - barHeight - 10  -- Align experience bar at the bottom

    -- Background Experience Bar
    love.graphics.setColor(0.2, 0.2, 0.2) -- Darker gray for background
    local expBarX = (screenWidth - barWidth) / 2  -- Center the experience bar
    love.graphics.rectangle("fill", expBarX, topBarY, barWidth, barHeight)

    -- Experience Fill
    local expRatio = math.max(self.experience.currentExp / self.experience.expToLevel, 0)
    love.graphics.setColor(0, 0, 1) -- Blue for experience
    love.graphics.rectangle("fill", expBarX, topBarY, barWidth * expRatio, barHeight)

    -- Draw Level and Experience Text in Green
    love.graphics.setColor(0, 1, 0) -- Green color for text
    love.graphics.setFont(self.fonts.subtitle)
    local levelText = string.format("Level: %d (%d/%d)", self.experience.level, math.floor(self.experience.currentExp), math.floor(self.experience.expToLevel))
    local expTextY = topBarY + (barHeight - self.fonts.subtitle:getHeight()) / 2
    love.graphics.printf(levelText, expBarX, expTextY, barWidth, "center")

    -- Draw "Press Any Key to Continue" Prompt on Title Screen
    if gameState == "title" then
        self:drawTitlePrompt()
    end

    -- Draw Upgrade Options if Visible
    if self.upgradeOptionsVisible then
        self:drawUpgradeOptions()
        end
         -- Draw red flash effect when the player takes damage
if player.damageFlashTimer and player.damageFlashTimer > 0 then
        love.graphics.setColor(1, 0, 0, 0.5)  -- Semi-transparent red
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)  -- Reset color
    end
end

function UI:drawUpgradeOptions()
    -- Get the current window size
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Define pop-up window size and position (centered)
    local popupWidth = 600
    local popupHeight = 400
    local popupX = (screenWidth - popupWidth) / 2
    local popupY = (screenHeight - popupHeight) / 2

    -- Draw semi-transparent dark background (centered)
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 15, 15)

    -- Set scissor to confine mist to the pop-up area
    love.graphics.setScissor(popupX, popupY, popupWidth, popupHeight)

    -- Set mist particle system position and draw it inside the pop-up
    mistParticleSystem:setPosition(popupX + popupWidth / 2, popupY + popupHeight / 2)
    love.graphics.setColor(1, 1, 1, 0.5) -- Semi-transparent white mist
    love.graphics.draw(mistParticleSystem, 0, 0)

    -- Reset scissor
    love.graphics.setScissor()

    -- Draw title for upgrade options
    love.graphics.setColor(0.8, 0.2, 0.2) -- Reddish color
    love.graphics.setFont(self.fonts.title)
    love.graphics.printf("Choose an Upgrade:", 0, popupY + 20, screenWidth, "center")

    -- Get mouse position for hover detection
    local mouseX, mouseY = love.mouse.getPosition()

    -- Draw each upgrade option
    love.graphics.setFont(self.fonts.subtitle)
    local optionStartY = popupY + 80
    local optionSpacing = 100  -- Increased box size for each talent
    local boxWidth = 500
    local boxHeight = 80

    for i, option in ipairs(self.upgradeOptions) do
        -- Set color based on tier
        if option.tier == 1 then
            love.graphics.setColor(0, 1, 0) -- Green for Tier 1
        elseif option.tier == 2 then
            love.graphics.setColor(0, 0, 1) -- Blue for Tier 2
        elseif option.tier == 3 then
            love.graphics.setColor(0.5, 0, 0.5) -- Purple for Tier 3
        end

        -- Calculate the position of each option (centered in the pop-up)
        local boxX = popupX + (popupWidth - boxWidth) / 2
        local boxY = optionStartY + (i - 1) * optionSpacing

        -- Check if the mouse is hovering over the current option
if mouseX >= boxX and mouseX <= boxX + boxWidth and mouseY >= boxY and mouseY <= boxY + boxHeight then
    -- Draw hover effect with only a border change (no background color change)
    love.graphics.setColor(1, 0, 0) -- red border when hovering
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10, 10)
else
    -- Draw normal border when not hovered
    love.graphics.setColor(1, 1, 1) -- White border for non-hovered state
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10, 10)
end


         -- Set ability name and description text
    local optionName = option.name or "Unknown Option"
    local optionDescription = option.description or "No description available."
    local className = option.class or "All"  -- Show "All" if the class is nil


     -- Draw the ability name in the tier color (not class color)
love.graphics.print(option.name, boxX + 10, boxY + 10)

-- Draw the class name separately in its unique color beside the ability name
if option.class == "Mage" then
    love.graphics.setColor(0.5, 0, 1) -- Purple for Mage
elseif option.class == "Spearwarden" then
    love.graphics.setColor(1, 1, 0) -- Yellow for Spearwarden
elseif option.class == "Ranger" then
    love.graphics.setColor(0, 1, 0) -- Green for Ranger
else
    love.graphics.setColor(1, 1, 1) -- Default color
end

-- Print the class name in its color right after the ability name
love.graphics.print("(" .. tostring(option.class) .. ")", boxX + 10 + self.fonts.subtitle:getWidth(option.name) + 5, boxY + 10)


        -- Draw the description text in white
        love.graphics.setColor(1, 1, 1) -- White color for description text
        love.graphics.print(optionDescription, boxX + 10, boxY + 40)
    end
end


function UI:mousepressed(x, y, button)
    if self.upgradeOptionsVisible then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local popupWidth = 600
        local popupHeight = 400
        local popupX = (screenWidth - popupWidth) / 2
        local popupY = (screenHeight - popupHeight) / 2
        local optionStartY = popupY + 80
        local optionSpacing = 100  -- Increased box size for each talent
        local boxWidth = 500
        local boxHeight = 80

        for i, option in ipairs(self.upgradeOptions) do
            local boxX = popupX + (popupWidth - boxWidth) / 2
            local boxY = optionStartY + (i - 1) * optionSpacing

            -- If mouse is hovering over the current option, select it
            if x >= boxX and x <= boxX + boxWidth and y >= boxY and y <= boxY + boxHeight then
                self.upgradeOptionsVisible = false
                if self.onUpgradeSelected then
                    self.onUpgradeSelected(option)
                end
                break
            end
        end
    end
end

function UI:drawTitlePrompt()
    local time = love.timer.getTime()
    local alpha = (math.sin(time * 2) + 1) / 2 -- Oscillates between 0 and 1
    love.graphics.setColor(1, 1, 1, alpha) -- White color with varying alpha
    love.graphics.setFont(self.fonts.subtitle)
    love.graphics.printf("Press Any Key to Continue", 0, 550, 800, "center")
end

function UI:showUpgradeOptions(options, callback)
    self.upgradeOptionsVisible = true
    self.upgradeOptions = options
    self.onUpgradeSelected = function(option)
        if option.apply then
            -- Apply the upgrade (whether it's a general or ability upgrade)
            option.apply()
          

            -- Debugging unpause
           

            -- Set leveling up to false and unpause the game
            self.experience.isLevelingUp = false
            gamePaused = false  -- Unpause the game once an upgrade is applied

            -- Debug after unpausing
           
        else
            -- If there's an issue with the upgrade option
           
        end

        -- Hide the options after the upgrade is applied
        self.upgradeOptionsVisible = false
    end
end

return UI