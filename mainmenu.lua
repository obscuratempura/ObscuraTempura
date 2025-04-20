-- mainmenu.lua

local MainMenu = {}
local gameState
local menuState = "main"
local Settings = require("settings")
local mainMenuOptions = { "Start Game", "Options", "Credits", "Quit" }
local mainMenuIndex = 1
local backgroundEnemies = require("background_enemies")
local BackgroundMap = require("background_map")
local Tutorial = require("tutorial") -- << ADD require for Tutorial

local arrowImage = love.graphics.newImage("assets/arrow.png")
local wishlistButtonImage = love.graphics.newImage("assets/wishlistbutton.png")

local mouseHoverIndex = nil
local useMouse = false

local titleFont = love.graphics.newFont("fonts/gothic.ttf", 80)
local promptFont = love.graphics.newFont("fonts/gothic.ttf", 24)

-- **Updated Color Palette (Ensure Consistency)**
local colorPalette = {
    {86/255, 33/255, 42/255, 1}, 
    {67/255, 33/255, 66/255, 1},  
    {95/255, 87/255, 94/255, 1},       
    {77/255, 102/255, 96/255, 1},       -- Retained for UI elements
    {173/255, 64/255, 48/255, 1},        -- Retained for specific accents
    {144/255, 75/255, 65/255, 1},        -- Retained for popup borders
    {155/255, 76/255, 99/255, 1},        -- Used for talent names
    {149/255, 182/255, 102/255, 1},      -- Retained for balance
   {231/255, 155/255, 124/255, 1},       -- Retained for subtle accents
    {166/255, 153/255, 152/255, 1},       -- Used for common item quality
   {246/255, 242/255, 195/255, 1},       -- Used for text readability
    {54/255, 69/255, 79/255, 1},          -- Changed to charcoalGray for UI backgrounds
   {239/255, 158/255, 78/255, 1},        -- Used for active tabs and borders
    {142/255, 184/255, 158/255, 1},       -- Retained for potential use
   {70/255, 85/255, 95/255, 1},          -- Used for rare item quality
    {233/255, 116/255, 81/255, 1},        -- Used for Combat tab
    {148/255, 163/255, 126/255, 1},       -- Retained for balance
   {174/255, 160/255, 189/255, 1},       -- Used for Abilities tab
  {218/255, 165/255, 32/255, 1},        -- Used for talent points and legendary quality
   {226/255, 114/255, 91/255, 1},         -- Retained for potential use
   {54/255, 69/255, 79/255, 1},          -- Used for tooltips and popups
 {222/255, 173/255, 190/255, 1},        -- Retained for potential use
    {34/255, 85/255, 34/255, 1},          -- Retained for balance
    {25/255, 25/255, 112/255, 1},         -- Retained for specific elements
}

local titleText = "Revenants & Realms"
local titleLetters = {}
for i = 1, #titleText do
    local letter = titleText:sub(i, i)
    table.insert(titleLetters, {char = letter, color = colorPalette[math.random(1, #colorPalette)]})
end

local colorChangeTimer = 0
local colorChangeInterval = 2

local Options = require("options")

-- Fade timer for start game transition
local fadeTimer = 0
local fadeAlpha = 1

-- Define cursor and selection sounds here and use them in both main menu and options
local function playCursorSound()
    if sounds and sounds.cursor then
        sounds.cursor:setVolume(Settings.effectsVolume)
        if sounds.cursor:isPlaying() then
            sounds.cursor:stop()
        end
        sounds.cursor:play()
    end
end

local function playSelectionSound()
    if sounds and sounds.menuselection then
        sounds.menuselection:setVolume(Settings.effectsVolume)
        if sounds.menuselection:isPlaying() then
            sounds.menuselection:stop()
        end
        sounds.menuselection:play()
    end
end

_G.GLOBAL_playCursorSound = playCursorSound
_G.GLOBAL_playSelectionSound = playSelectionSound

function MainMenu.load()
    sounds.startGameSound = love.audio.newSource("assets/sounds/effects/startcontinuestab.mp3", "static")

    menuState = "main"
    mainMenuIndex = 1
    mouseHoverIndex = nil
    
    if sounds.mainMenuMusic then
        sounds.mainMenuMusic:setLooping(true)
        sounds.mainMenuMusic:setVolume(Settings.musicVolume) 
        sounds.mainMenuMusic:play()
    else
        print("Warning: Main menu music not found!")
    end
    
    fadeTimer = 0
    fadeAlpha = 1
end

function MainMenu.update(dt)
    -- Update color change timer for title letters
    colorChangeTimer = colorChangeTimer + dt
    if colorChangeTimer >= colorChangeInterval then
        colorChangeTimer = colorChangeTimer - colorChangeInterval
        for i, letter in ipairs(titleLetters) do
            letter.color = colorPalette[math.random(1, #colorPalette)]
        end
    end
    
    if menuState == "options" and Options.visible then
        Options.update(dt)
    end

    -- Handle fade out if starting game or going to overworld
    if fadeTimer > 0 then
        fadeTimer = fadeTimer - dt
        fadeAlpha = math.max(0, fadeTimer / 0.5) -- Use the fade duration (0.5s)
        if fadeTimer <= 0 then
            -- >> MODIFIED: Transition based on tutorial flag
            if _G.tutorialCompleted then
                 gameState:setState("overworld")
            else
                 -- Start the game with the pre-created tutorial level
                 if _G.levelToStartAfterFade then
                     startGame(_G.levelToStartAfterFade) -- startGame sets state to "playing"
                 else
                     print("Error: No level instance found to start after fade.")
                     -- Fallback or error handling
                     gameState:setState("overworld") -- Go to overworld as fallback
                 end
            end
            _G.levelToStartAfterFade = nil -- Clean up global
            -- << END MODIFIED
            MainMenu.unload()
        end
    end
    
    backgroundEnemies.update(dt)

end

function MainMenu.draw()
    love.graphics.setColor(1, 1, 1, 1)
  
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    BackgroundMap.draw()
    backgroundEnemies.draw()

    local popupWidth = 600
    local popupHeight = 400
    local popupX = (screenWidth - popupWidth) / 2
    local popupY = (screenHeight - popupHeight) / 2 + 50

    love.graphics.setColor(0, 0, 0, 0.5 * fadeAlpha)
    love.graphics.rectangle("fill", popupX, popupY, popupWidth, popupHeight, 20, 20)

    love.graphics.setFont(titleFont)
    local titleY = popupY - titleFont:getHeight() - 20
    local totalWidth = 0
    for i, letter in ipairs(titleLetters) do
        totalWidth = totalWidth + titleFont:getWidth(letter.char)
    end
    local startX = (screenWidth - totalWidth) / 2
    local x = startX
    for i, letter in ipairs(titleLetters) do
        love.graphics.setColor(letter.color[1], letter.color[2], letter.color[3], fadeAlpha)
        love.graphics.print(letter.char, x, titleY)
        x = x + titleFont:getWidth(letter.char)
    end

    if menuState == "main" or (menuState == "options" and not Options.visible) then
        love.graphics.setFont(promptFont)
        local optionsToDraw = mainMenuOptions
        local currentIndex = mainMenuIndex

        local startY = popupY + 100
        local optionSpacing = 80

        for i, option in ipairs(optionsToDraw) do
            local yPos = startY + (i - 1) * optionSpacing
            if i == currentIndex then
                -- Select a new random color from the palette each draw
                local highlightColor = colorPalette[math.random(1, #colorPalette)]
                love.graphics.setColor(highlightColor[1], highlightColor[2], highlightColor[3], fadeAlpha)
                love.graphics.printf(option, popupX, yPos, popupWidth, "center")
                
                local textWidth = promptFont:getWidth(option)
                local arrowScale = 2.0
                local arrowX = popupX + (popupWidth / 2) - (textWidth / 2) - (arrowImage:getWidth() * arrowScale) - 30
                local arrowY = yPos + (promptFont:getHeight() / 2) - ((arrowImage:getHeight() * arrowScale) / 2)
                
                -- Draw the arrowImage with the same highlight color
                love.graphics.draw(arrowImage, arrowX, arrowY, 0, arrowScale, arrowScale)
            else
                love.graphics.setColor(1, 1, 1, fadeAlpha)
                love.graphics.printf(option, popupX, yPos, popupWidth, "center")
            end
        end

        -- Draw Wishlist Button
        love.graphics.setColor(1, 1, 1, fadeAlpha)
        local margin = 20
        local buttonX = margin
        local buttonY = screenHeight - (wishlistButtonImage:getHeight() * 0.5) - margin
        love.graphics.draw(wishlistButtonImage, buttonX, buttonY, 0, 0.5, 0.5)
    end

    -- **Options Menu Drawing**
    if Options.visible then
        local popupWidth = 600
        local popupHeight = 400
        local popupX = (love.graphics.getWidth() - popupWidth) / 2
        local popupY = (love.graphics.getHeight() - popupHeight) / 2

        -- Call Options.draw() with specific parameters
        Options.draw(
            popupX,
            popupY,
            popupWidth,
            popupHeight,
            promptFont,
            colorPalette,
            arrowImage
        )
    end

    -- Fade effect overlay
    love.graphics.setColor(1, 1, 1, 1)
end

function MainMenu.keypressed(key)
    if menuState == "options" and Options.visible then
        Options.keypressed(key)
        if not Options.visible then
            menuState = "main"
        end
        return
    end

    if menuState == "credits" then
        if key == "escape" or key == "backspace" then
            menuState = "main"
            playCursorSound()
        end
        return
    end

    if fadeTimer > 0 then return end

    local optionsToDraw = mainMenuOptions
    local currentIndex = mainMenuIndex

    if key == "w" or key == "up" then
        currentIndex = currentIndex - 1
        if currentIndex < 1 then currentIndex = #optionsToDraw end
        playCursorSound()
    elseif key == "s" or key == "down" then
        currentIndex = currentIndex + 1
        if currentIndex > #optionsToDraw then currentIndex = 1 end
        playCursorSound()
    elseif key == "return" then
        MainMenu.selectOption(optionsToDraw[currentIndex])
        if optionsToDraw[currentIndex] ~= "Start Game" then
            playSelectionSound()
        end
        return
    end

    mainMenuIndex = currentIndex

    if key == "escape" and menuState == "main" then
        love.event.quit()
    end
end

function MainMenu.mousemoved(x, y, dx, dy)
    if menuState == "options" and Options.visible then
        Options.mousemoved(x,y)
        return
    end

    local popupWidth = 600
    local popupHeight = 400
    local popupX = (love.graphics.getWidth() - popupWidth) / 2
    local popupY = (love.graphics.getHeight() - popupHeight) / 2 + 50

    local startY = popupY + 100
    local optionSpacing = 80
    local optionsToDraw = mainMenuOptions

    local previousHover = mouseHoverIndex
    mouseHoverIndex = nil
    for i, option in ipairs(optionsToDraw) do
        local yPos = startY + (i - 1) * optionSpacing
        local textHeight = promptFont:getHeight(option)
        if x >= popupX and x <= popupX + popupWidth and y >= yPos and y <= yPos + textHeight then
            mouseHoverIndex = i
            break
        end
    end

    if mouseHoverIndex and mouseHoverIndex ~= mainMenuIndex then
        mainMenuIndex = mouseHoverIndex
        playCursorSound()
    end
end

function MainMenu.mousepressed(x, y, button)
    if button == 1 then
        if menuState == "options" and Options.visible then
            Options.mousepressed(x, y, button)
            return
        end

        local margin = 20
        local buttonX = margin
        local screenHeight = love.graphics.getHeight()
        local buttonY = screenHeight - (wishlistButtonImage:getHeight() * 0.5) - margin
        local buttonWidth = wishlistButtonImage:getWidth() * 0.5
        local buttonHeight = wishlistButtonImage:getHeight() * 0.5

        if x >= buttonX and x <= buttonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
            print("Wishlist Button Clicked.")
            local url = "https://store.steampowered.com/app/YOUR_GAME_ID"
            if love.system.getOS() == "Windows" then
                os.execute('start "" "' .. url .. '"')
            elseif love.system.getOS() == "OS X" then
                os.execute('open "' .. url .. '"')
            elseif love.system.getOS() == "Linux" then
                os.execute('xdg-open "' .. url .. '"')
            end
            return
        end

        if mouseHoverIndex then
            local optionsToDraw = mainMenuOptions
            MainMenu.selectOption(optionsToDraw[mouseHoverIndex])
            if optionsToDraw[mouseHoverIndex] ~= "Start Game" then
                playSelectionSound()
            end
        end
    end
end

function MainMenu.setGameState(gs)
    gameState = gs
end

function MainMenu.selectOption(option)
    if menuState == "main" then
        if option == "Start Game" then
            -- Stop main menu music
            if sounds.mainMenuMusic then
                sounds.mainMenuMusic:stop()
            end

            if sounds.startGameSound then
                sounds.startGameSound:setVolume(Settings.effectsVolume)
                sounds.startGameSound:stop()
                sounds.startGameSound:play()
            else
                print("Warning: startcontinuestab.mp3 not loaded!")
            end

            -- >> MODIFIED: Check tutorial completion flag
            if _G.tutorialCompleted then
                print("[MainMenu] Tutorial completed, going to Overworld.")
                -- Directly transition to Overworld state (fade handled separately if needed)
                 fadeTimer = 0.5 -- Keep fade if desired
                 -- The actual state change will happen in update when fadeTimer runs out
            else
                print("[MainMenu] Tutorial not completed, starting Tutorial level.")
                -- Start the tutorial level (fade handled separately if needed)
                fadeTimer = 0.5 -- Keep fade if desired
                -- We need to tell the update loop WHICH state to go to after fade
                _G.nextStateAfterFade = "playing" -- Use a global or pass info
                _G.levelToStartAfterFade = Tutorial.new() -- Create tutorial instance
            end
            -- << END MODIFIED

        elseif option == "Options" then
            menuState = "options"
            Options.load()
        elseif option == "Credits" then
            menuState = "credits"
            playCursorSound()
        elseif option == "Quit" then
            love.event.quit()
        end
    end
end

function MainMenu.unload()
    if sounds.mainMenuMusic then
        sounds.mainMenuMusic:stop()
    end
end

return MainMenu
