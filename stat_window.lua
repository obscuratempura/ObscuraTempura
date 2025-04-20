local statWindow = {}
statWindow.__index = statWindow

-- Colors
local baseColor    = {1, 1, 1, 1}          -- white for base numbers
local bonusColor   = {1, 0.5, 0, 1}          -- orange for bonus numbers
local totalColor   = {0, 1, 0, 1}            -- green for total/result
local headerMagenta = {1, 0, 1, 1}           -- magenta for Global header

local classColors = {
    Grimreaper  = {0.6, 0, 0},      -- Dark Red for Grimreaper
    Emberfiend  = {1, 0.4, 0},      -- Orange for Emberfiend
    Stormlich   = {0, 0.6, 1},      -- Light Blue for Stormlich
    Default     = {1, 1, 1}         -- White if class isn't listed
}

function statWindow.new(player)
    local self = setmetatable({}, statWindow)
    self.player = player  -- Reference to your player instance
    self.visible = false
    self.x = 800
    self.y = 250
    self.width = 450
    self.height = 450
    self.scrollY = 0
    self.lineHeight = 15  -- Reduced line height
    self.lines = {}
    -- Reduced font sizes:
    self.titleFont = love.graphics.newFont("fonts/gothic.ttf", 18)
    self.textFont  = love.graphics.newFont("fonts/gothic.ttf", 18)
    return self
end

function statWindow:updateFromPlayer(newPlayer)
    self.player = newPlayer
    self:updateStats()
end

-- Build the stat lines using the player's current fields.
function statWindow:updateStats()


    local p = self.player
    -- Force the combined crit chance bonus update:
p.critChanceBonus = (p.talentCritChanceBonus or 0) + (p.equipmentCritChanceBonus or 0)


  
    local globalLines = {}

    -- Global Stats (moved to top):
    table.insert(globalLines, {text = "Global:", header = true})
    local baseMove = p.baseSpeed or 0
    local moveBonus = (p.equipmentSpeedBonus or 0) + (p.talentSpeedBonus or 0) + (p.hasteBonus or 0)
    local totalMove = baseMove + moveBonus
    table.insert(globalLines, {text = string.format("Movement Speed: %d + %d = %d", baseMove, moveBonus, totalMove)})

      local totalBasePR, totalBonusPR, totalPR, count = 0, 0, 0, 0
    for _, char in pairs(p.characters) do
        local basePR  = char.basePullRange or 0
        local bonusPR = char.equipmentPullRangeBonus or 0
        totalBasePR  = totalBasePR + basePR
        totalBonusPR = totalBonusPR + bonusPR
        totalPR      = totalPR + (basePR + bonusPR)
        count = count + 1
    end
    local avgBasePR  = count > 0 and math.floor(totalBasePR / count) or 0
    local avgBonusPR = count > 0 and math.floor(totalBonusPR / count) or 0
    local avgPR      = count > 0 and math.floor(totalPR / count) or 0
    table.insert(globalLines, {text = string.format("Pull Range: %d + %d = %d", avgBasePR, avgBonusPR, avgPR)})


    local defaultTeamMaxHealth = 330  -- starting base health
    local bonusHealth = (p.teamMaxHealth or defaultTeamMaxHealth) - defaultTeamMaxHealth
    local totalHealth = p.teamHealth or 0
    table.insert(globalLines, {text = string.format("Health: %d + %d = %d", defaultTeamMaxHealth, bonusHealth, totalHealth)})

local baseCrit = p.baseCritChance or 1
local critBonus = p.critChanceBonus or 0
local totalCrit = baseCrit + critBonus

table.insert(globalLines, {text = string.format("Crit Chance: %.2f%% + %.2f%% = %.2f%%", baseCrit, critBonus, totalCrit)})




    table.insert(globalLines, {text = string.format("Crit Damage: 2.00 + %.2f = %.2f", p.critDamageBonus or 0, 2.00 + (p.critDamageBonus or 0))})

    table.insert(globalLines, {text = string.format("Armor: %d", p.armor or 0)})
    table.insert(globalLines, {text = string.format("Damage Reduction: %.1f%%", (p.armor or 0) / ((p.armor or 0) + 100) * 100)})


    -- Build character stats:
    local characterLines = {}
    for name, char in pairs(p.characters) do
        table.insert(characterLines, {text = name .. ":", header = true, class = name})

        local baseAR = char.baseAttackRange or 0
        local totalAR = char.attackRange or 0
        local bonusAR = totalAR - baseAR
        table.insert(characterLines, {text = string.format("Attack Range: %d + %d = %d", baseAR, bonusAR, totalAR)})

        local baseAS = char.baseAttackSpeed or 0
        local totalAS = char.attackSpeed or 0
        local bonusAS = totalAS - baseAS
        local bonusASPercent = (baseAS > 0) and (bonusAS / baseAS * 100) or 0
        table.insert(characterLines, {text = string.format("Attack Speed: %.2f + %.2f (%.1f%%) = %.2f", baseAS, bonusAS, bonusASPercent, totalAS)})

        local baseDmg = char.baseDamage or 0
        local totalDmg = char.damage or 0
        local bonusDmg = totalDmg - baseDmg
        table.insert(characterLines, {text = string.format("Damage: %d + %d = %d", baseDmg, bonusDmg, totalDmg)})

        local abilityFlat = 0
        if name == "Grimreaper" then
            abilityFlat = char.grimReaperAbilityBonus or 0
        elseif name == "Emberfiend" then
            abilityFlat = char.emberfiendAbilityBonus or 0
        elseif name == "Stormlich" then
            abilityFlat = char.stormlichAbilityBonus or 0
        end
        table.insert(characterLines, {text = string.format("Ability Power: %d", abilityFlat)})

        table.insert(characterLines, {text = ""})  -- Blank line for spacing
    end

    -- Combine global and character stats (Global on top):
    -- Combine global and character stats (Global on top):
self.lines = {}
for _, line in ipairs(globalLines) do
    table.insert(self.lines, line)
end
table.insert(self.lines, {text = ""})  -- Blank line between Global and character stats
for _, line in ipairs(characterLines) do
    table.insert(self.lines, line)
end

end

function statWindow:draw()
    if not self.visible then return end

    self:updateStats()

    -- Draw popup background and border:
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 10, 10)
    love.graphics.setColor(239/255, 158/255, 78/255, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 10, 10)
    love.graphics.setLineWidth(1)

    -- Draw title:
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Stats", self.x, self.y + 10, self.width, "center")

    -- Draw stat lines:
    love.graphics.setFont(self.textFont)
    local yCursor = self.y + 40 - self.scrollY
    for i, line in ipairs(self.lines) do
        if line.header then
            if line.text == "Global:" then
                love.graphics.setColor(headerMagenta)
            else
                local classColor = classColors[line.class] or classColors.Default
                love.graphics.setColor(classColor)
            end
            love.graphics.printf(line.text, self.x + 10, yCursor, self.width - 20, "left")
        elseif line.text == "" then
            -- Blank line for spacing; do nothing
        else
            -- We expect the line to be formatted as "Label: base + bonus = total"
           -- We expect the line to be formatted as "Label: base + bonus = total"
local label, numbers = line.text:match("^(.-):%s*(.*)$")
if label and numbers then
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf(label..": ", self.x + 10, yCursor, self.width - 20, "left")
    local offset = love.graphics.getFont():getWidth(label..": ")
    if label == "Attack Speed" then
        local baseStr, bonusStr, percentStr, totalStr = numbers:match("^(%-?%d+%.?%d*)%s*%+%s*(%-?%d+%.?%d*)%s*%((%-?%d+%.?%d*%%)%)%s*=%s*(%-?%d+%.?%d*)$")
        if baseStr and bonusStr and percentStr and totalStr then
            love.graphics.setColor(baseColor)
            love.graphics.print(baseStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(baseStr)
            local plusStr = " + "
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(plusStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(plusStr)
            love.graphics.setColor(bonusColor)
            love.graphics.print(bonusStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(bonusStr)
            local space = " "
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(space, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(space)
            love.graphics.print("(", self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth("(")
            love.graphics.print(percentStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(percentStr)
            love.graphics.print(")", self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(")")
            local eqStr = " = "
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(eqStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(eqStr)
            love.graphics.setColor(totalColor)
            love.graphics.print(totalStr, self.x + 10 + offset, yCursor)
        else
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(line.text, self.x + 10, yCursor, self.width - 20, "left")
        end
    elseif label == "Crit Chance" then
      local baseStr, bonusStr, totalStr = numbers:match("^(%-?%d+%.?%d*)%%?%s*%+%s*(%-?%d+%.?%d*)%%?%s*=%s*(%-?%d+%.?%d*)%%?$")

        if baseStr and bonusStr and totalStr then
            love.graphics.setColor(baseColor)
            love.graphics.print(baseStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(baseStr)
            local plusStr = " + "
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(plusStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(plusStr)
            love.graphics.setColor(bonusColor)
            love.graphics.print(bonusStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(bonusStr)
            local eqStr = " = "
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(eqStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(eqStr)
            love.graphics.setColor(totalColor)
            love.graphics.print(totalStr, self.x + 10 + offset, yCursor)
        else
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(line.text, self.x + 10, yCursor, self.width - 20, "left")
        end
    else
        local baseStr, bonusStr, totalStr = numbers:match("^(%d+)%s*%+%s*(%-?%d+)%s*=%s*(%d+)$")
        if baseStr and bonusStr and totalStr then
            love.graphics.setColor(baseColor)
            love.graphics.print(baseStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(baseStr)
            local plusStr = " + "
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(plusStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(plusStr)
            love.graphics.setColor(bonusColor)
            love.graphics.print(bonusStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(bonusStr)
            local eqStr = " = "
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(eqStr, self.x + 10 + offset, yCursor)
            offset = offset + love.graphics.getFont():getWidth(eqStr)
            love.graphics.setColor(totalColor)
            love.graphics.print(totalStr, self.x + 10 + offset, yCursor)
        else
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(line.text, self.x + 10, yCursor, self.width - 20, "left")
        end
    end
else
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf(line.text, self.x + 10, yCursor, self.width - 20, "left")
end

        end
        yCursor = yCursor + self.lineHeight
    end
end

function statWindow:wheelmoved(dx, dy)
    self.scrollY = self.scrollY - dy * 20
    if self.scrollY < 0 then self.scrollY = 0 end

    local totalHeight = #self.lines * self.lineHeight
    local maxScroll = math.max(0, totalHeight - (self.height - 40))
    if self.scrollY > maxScroll then self.scrollY = maxScroll end
end

return statWindow
