local DevMenu = {}
local Enemy = require("enemy")
DevMenu.isVisible = false
DevMenu.state = "main"  -- Tracks which menu the dev is currently in ("main", "abilities", or "spawn_enemies")
DevMenu.selectedCharacter = nil
DevMenu.selectedAbility = nil
DevMenu.selectedRank = 1
DevMenu.selectedEnemyType = nil

-- List of available enemies to spawn
DevMenu.availableEnemies = {"goblin", "skeleton", "bat", "slime", "orc_archer", "viper", "mage_enemy", "vampire_boss"}

-- Toggle visibility of Dev Menu
function DevMenu.toggle()
    DevMenu.isVisible = not DevMenu.isVisible
end

-- Draw the Dev Menu on the side of the play screen
function DevMenu.draw()
    if DevMenu.isVisible then
        -- Set semi-transparent background for the menu on the side
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", love.graphics.getWidth() - 300, 50, 250, 400)

        -- Set text color
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(18))

        -- Title
        love.graphics.printf("Dev Menu", love.graphics.getWidth() - 280, 60, 200, "center")

        -- Menu options
        local options = {}

        if DevMenu.state == "main" then
            options = {
                "Level Up",
                "Unlock All Abilities",
                "Full Health",
                "Add Experience",
                "Modify Abilities",
                "Spawn Enemies"
            }
        elseif DevMenu.state == "abilities" then
            options = {}
            for charName, _ in pairs(player.characters) do
                table.insert(options, charName)
            end
            table.insert(options, "Back to Main Menu")
        elseif DevMenu.state == "character_abilities" then
            local character = player.characters[DevMenu.selectedCharacter]
            if character then
                for abilityName, _ in pairs(character.abilities) do
                    table.insert(options, abilityName)
                end
            end
            table.insert(options, "Back to Characters")
        elseif DevMenu.state == "spawn_enemies" then
            for _, enemyType in ipairs(DevMenu.availableEnemies) do
                table.insert(options, enemyType)
            end
            table.insert(options, "Back to Main Menu")
        end

        -- Option rendering and hover detection
        local mouseX, mouseY = love.mouse.getPosition()
        local optionY = 100
        local optionHeight = 30
        local selectedOption = nil

        for i, option in ipairs(options) do
            -- Detect if the mouse is hovering over this option
            if mouseX >= love.graphics.getWidth() - 280 and mouseX <= love.graphics.getWidth() - 80 and mouseY >= optionY and mouseY <= optionY + optionHeight then
                love.graphics.setColor(0.8, 0.2, 0.2)  -- Highlight color
                selectedOption = i
            else
                love.graphics.setColor(1, 1, 1)  -- Normal color
            end

            love.graphics.printf(option, love.graphics.getWidth() - 280, optionY, 200, "left")
            optionY = optionY + optionHeight + 10
        end

        return selectedOption
    end
end

-- Handle Dev Menu mouse clicks
function DevMenu.handleMouseClick(x, y)
    if not DevMenu.isVisible then return end

    local optionY = 100
    local optionHeight = 30
    local selectedOption = nil

    -- Options list
    local options = {}
    if DevMenu.state == "main" then
        options = { "Level Up", "Unlock All Abilities", "Full Health", "Add Experience", "Modify Abilities", "Spawn Enemies" }
    elseif DevMenu.state == "abilities" then
        for charName, _ in pairs(player.characters) do
            table.insert(options, charName)
        end
        table.insert(options, "Back to Main Menu")
    elseif DevMenu.state == "character_abilities" then
        local character = player.characters[DevMenu.selectedCharacter]
        if character then
            for abilityName, ability in pairs(character.abilities) do
                -- Show ability name and current rank (default to 1 if rank is nil)
                local abilityInfo = abilityName .. " (Rank: " .. tostring(ability.rank or 1) .. ")"
                table.insert(options, abilityInfo)
            end
        end
        table.insert(options, "Back to Characters")
    elseif DevMenu.state == "spawn_enemies" then
        for _, enemyType in ipairs(DevMenu.availableEnemies) do
            table.insert(options, enemyType)
        end
        table.insert(options, "Back to Main Menu")
    end

    -- Determine which option was clicked
    for i, option in ipairs(options) do
        if x >= love.graphics.getWidth() - 280 and x <= love.graphics.getWidth() - 80 and y >= optionY and y <= optionY + optionHeight then
            selectedOption = i
            break
        end
        optionY = optionY + optionHeight + 10
    end

    -- Handle the selected option
    if selectedOption then
        if DevMenu.state == "main" then
            if selectedOption == 1 then
                -- Level up player
                if experience and experience.levelUp then 
                    experience:levelUp()

                    -- Trigger the upgrade selection UI manually
                    if experience.isLevelingUp then
                        gamePaused = true
                        ui:showUpgradeOptions(experience.upgradeOptions, function(selectedUpgrade)
                            selectedUpgrade.apply()
                            experience.isLevelingUp = false
                            gamePaused = false
                        end)
                    end
                end
            elseif selectedOption == 2 then
                -- Unlock all abilities
                if player and player.unlockAllAbilities then player:unlockAllAbilities() end
            elseif selectedOption == 3 then
                -- Heal player to full health
                if player then for _, char in pairs(player.characters) do char.health = char.maxHealth end end
            elseif selectedOption == 4 then
                -- Add experience
                if experience and experience.addExperience then experience:addExperience(100) end
            elseif selectedOption == 5 then
                -- Go to character selection for ability modification
                DevMenu.state = "abilities"
            elseif selectedOption == 6 then
                -- Go to enemy spawning menu
                DevMenu.state = "spawn_enemies"
            end
        elseif DevMenu.state == "abilities" then
            local characters = {}
            for charName, _ in pairs(player.characters) do
                table.insert(characters, charName)
            end
            if selectedOption == #characters + 1 then
                DevMenu.state = "main"
            else
                DevMenu.selectedCharacter = characters[selectedOption]
                DevMenu.state = "character_abilities"
            end
        elseif DevMenu.state == "character_abilities" then
            local character = player.characters[DevMenu.selectedCharacter]
            if selectedOption == #options then
                DevMenu.state = "abilities"
            else
                local abilities = {}
                for abilityName, _ in pairs(character.abilities) do
                    table.insert(abilities, abilityName)
                end
                DevMenu.selectedAbility = abilities[selectedOption]

                -- Modify the ability rank, staying in this state
                local ability = character.abilities[DevMenu.selectedAbility]
                ability.rank = math.min((ability.rank or 1) + 1, 3)  -- Cap rank at 3
            end
        elseif DevMenu.state == "spawn_enemies" then
            if selectedOption == #DevMenu.availableEnemies + 1 then
                DevMenu.state = "main"
            else
                DevMenu.selectedEnemyType = DevMenu.availableEnemies[selectedOption]
                spawnEnemyByType(DevMenu.selectedEnemyType)  -- Call function to spawn enemy
            end
        end
    end

    -- Ensure UI responds to mouse clicks when in upgrade mode
    if ui.upgradeOptionsVisible then
        ui:mousepressed(x, y, 1)
    end
end


function spawnEnemyByType(enemyType)
    if enemyType and player and player.characters and enemies then
        -- Select a random character from the player's characters
        local charNames = {"ranger", "mage", "spearwarden"}
        local selectedChar = player.characters[charNames[math.random(#charNames)]]

        -- Make sure the selected character exists and has valid coordinates
        if selectedChar and selectedChar.x and selectedChar.y then
            -- Define a random offset range from the character's position
            local offsetX = math.random(-200, 200)  -- X offset between -200 and 200 pixels
            local offsetY = math.random(-200, 200)  -- Y offset between -200 and 200 pixels

            -- Set the spawn position near the selected character
            local spawnPos = {
                x = selectedChar.x + offsetX,
                y = selectedChar.y + offsetY
            }

            -- Create the enemy and add to the game
            table.insert(enemies, Enemy.new(enemyType, spawnPos.x, spawnPos.y, experience.level))
            print("Spawned enemy: " .. enemyType .. " at (" .. spawnPos.x .. ", " .. spawnPos.y .. ") near " .. selectedChar.type)
        else
            print("Error: selected character does not have valid coordinates.")
        end
    else
        print("Error: enemyType or player characters not defined correctly.")
    end
end




function DevMenu.handleKeyPress(key)
    -- If the DevMenu is visible, we don't want to process any key inputs except for toggling it off
    if key == "f1" then
        DevMenu.toggle()  -- Allow the dev menu to toggle on/off with F1
    elseif key == "escape" then
        showMenu = true   -- Open the escape menu if escape is pressed
    end
end

return DevMenu