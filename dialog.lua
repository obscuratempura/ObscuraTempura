local Dialog = {}
Dialog.__index = Dialog

local typingSpeed = 0.03  -- 30 ms per character

-- Helper: load a portrait sprite sheet and create two quads.
local function loadPortrait(path)
    local img = love.graphics.newImage(path)
    img:setFilter("nearest", "nearest")  -- set nearest filter for pixel clarity
    local imgW, imgH = img:getWidth(), img:getHeight()  -- expected: 128x64
    local quad1 = love.graphics.newQuad(0, 0, 64, 64, imgW, imgH)
    local quad2 = love.graphics.newQuad(64, 0, 64, 64, imgW, imgH)
    return { image = img, quads = {quad1, quad2} }
end

function Dialog.new(gameState)
    local self = setmetatable({}, Dialog)
    self.gameState = gameState
    self.active = false
    self.lines = {}
    self.currentLine = 1
    self.displayedText = ""
    self.timer = 0
    self.finished = false   -- whether the line is fully typed out

    -- Animation timers for portrait and arrow blink.
    self.portraitTimer = 0
    self.arrowTimer = 0

    -- Load arrow image.
    self.arrowImage = love.graphics.newImage("assets/arrow.png")

    -- Load portraits for known speakers.
    self.portraits = {
        Emberfiend = loadPortrait("assets/emberfiendtalk.png"),
        Grimreaper = loadPortrait("assets/grimreapertalk.png"),
        Stormlich  = loadPortrait("assets/stormlichtalk.png"),
    }

    -- >> ADDED: Load speaker sound effects
    self.speakerSounds = {
        Emberfiend = love.audio.newSource("assets/sounds/effects/emberfienddialog.wav", "static"),
        Grimreaper = love.audio.newSource("assets/sounds/effects/grimreaperdialog.wav", "static"),
        Stormlich  = love.audio.newSource("assets/sounds/effects/stormlichdialog.wav", "static"),
    }
    self.currentSoundInstance = nil -- To store the currently playing sound instance
    -- << END ADDED

    return self
end

-- >> ADDED: Helper function to play speaker sound
function Dialog:_playSpeakerSound(speaker)
    self:_stopSpeakerSound() -- Stop any previous sound first
    local soundSource = self.speakerSounds[speaker]
    if soundSource then
        soundSource:setLooping(true) -- Loop the sound while typing
        self.currentSoundInstance = soundSource
        love.audio.play(self.currentSoundInstance)
    end
end
-- << END ADDED

-- >> ADDED: Helper function to stop speaker sound
function Dialog:_stopSpeakerSound()
    if self.currentSoundInstance then
        love.audio.stop(self.currentSoundInstance)
        self.currentSoundInstance:setLooping(false) -- Ensure looping is off
        self.currentSoundInstance = nil
    end
end
-- << END ADDED

function Dialog:start(lines)
    self.lines = lines
    self.currentLine = 1
    self.displayedText = ""
    self.timer = 0
    self.active = true
    self.finished = false
    self.arrowTimer = 0
    self.portraitTimer = 0
    if self.gameState and self.gameState.setPause then
        self.gameState:setPause(true)
    end
    -- >> ADDED: Play sound for the first line
    if #self.lines > 0 then
        self:_playSpeakerSound(self.lines[1].speaker)
    end
    -- << END ADDED
end

function Dialog:update(dt)
    if not self.active then return end

    -- Update portrait timer always.
    self.portraitTimer = self.portraitTimer + dt
    if self.finished then
        self.arrowTimer = self.arrowTimer + dt
    else
        self.arrowTimer = 0
    end

    if not self.finished then
        local current = self.lines[self.currentLine]
        if current then
            local fullText = current.text
            self.timer = self.timer + dt
            local charCount = math.floor(self.timer / typingSpeed)
            if charCount >= #fullText then
                self.displayedText = fullText
                self.finished = true
                -- >> ADDED: Stop sound when typing finishes
                self:_stopSpeakerSound()
                -- << END ADDED
            else
                self.displayedText = string.sub(fullText, 1, charCount)
            end
        end
    end
end

function Dialog:draw()
    if not self.active then return end

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    -- Define dialog box dimensions
    local boxWidth = screenWidth * 0.6
    local boxHeight = 150

    -- --- MODIFICATION START ---
    -- Calculate new position: Horizontally centered, vertically centered between top and middle, then nudged down.
    local x = (screenWidth - boxWidth) / 2
    local verticalMidpoint = screenHeight / 4 -- Midpoint between top (0) and screen center (screenHeight / 2)
    local y = verticalMidpoint - (boxHeight / 2)
    y = y + 30 -- <<< Add a small downward offset (adjust 30 as needed)
    -- Ensure y is not negative if boxHeight is large or screenHeight is small
    y = math.max(10, y) -- Add a small top margin (e.g., 10 pixels)
    -- --- MODIFICATION END ---


    -- Draw dialog background.
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", x, y, boxWidth, boxHeight)
    love.graphics.setColor(1, 1, 1)

    -- Determine the current speaker and text.
    local current = self.lines[self.currentLine]
    local speaker = current and current.speaker or ""
    local text = self.displayedText or ""

    -- Scale portrait so that its height matches boxHeight.
    local scale = boxHeight / 64  -- original portrait height is 64
    local portraitOffset = 0
    -- Use a fallback if no portrait exists (e.g. "Test" -> use Stormlich)
    local portrait = self.portraits[speaker] or self.portraits["Stormlich"]
    if portrait then
        local frameIndex = (math.floor(self.portraitTimer / 0.2) % 2) + 1
        local portraitX = x + 10
        local portraitY = y
        love.graphics.draw(portrait.image, portrait.quads[frameIndex], portraitX, portraitY, 0, scale, scale)
        portraitOffset = (64 * scale) + 20  -- space for portrait plus margin
    else
        portraitOffset = 10
    end

    -- Draw speaker name (if any) and wrapped text.
    local textX = x + portraitOffset
    local textY = y + 10
    if speaker ~= "" then
        love.graphics.print(speaker .. ":", textX, textY)
        textY = textY + 20
    end
    local textAreaWidth = boxWidth - portraitOffset - 10
    love.graphics.printf(text, textX, textY, textAreaWidth, "left")

    -- If text is fully typed, show blinking arrow at bottom-right.
    if self.finished then
        if (self.arrowTimer % 1.0) < 0.5 then
            local arrowW = self.arrowImage:getWidth()
            local arrowH = self.arrowImage:getHeight()
            local arrowX = x + boxWidth - arrowW - 10
            local arrowY = y + boxHeight - arrowH - 10
            love.graphics.draw(self.arrowImage, arrowX, arrowY)
        end
    end
end

function Dialog:mousepressed(x, y, b)
    if not self.active then return end
    if not self.finished then
        -- Finish current line immediately.
        local current = self.lines[self.currentLine]
        if current then
            self.displayedText = current.text
            self.finished = true
            -- >> ADDED: Stop sound when skipping typing
            self:_stopSpeakerSound()
            -- << END ADDED
        end
    else
        -- Go to next line or end dialog.
        -- >> ADDED: Stop sound just in case before advancing
        self:_stopSpeakerSound()
        -- << END ADDED
        self.currentLine = self.currentLine + 1
        if self.currentLine > #self.lines then
            self.active = false
            if self.gameState and self.gameState.setPause then
                self.gameState:setPause(false)
            end
        else
            self.timer = 0
            self.displayedText = ""
            self.finished = false
            -- >> ADDED: Play sound for the new line
            self:_playSpeakerSound(self.lines[self.currentLine].speaker)
            -- << END ADDED
        end
    end
end

return Dialog