--[[
Author Idler
This is helper to run various commands into creature in front of us or self for testing purposes

join idlers tavern!
https://discord.gg/BtHj5YqsSz

OTR:
https://discord.gg/sdxUJJdFzC


Creature Info & Control Commands (/cr)

Basic Info:
/cr                  - Shows list of available commands
/cr name            - Shows creature name
/cr id              - Shows creature ID
/cr target          - Shows current target name
/cr follow          - Shows followed creature name
/cr master          - Shows master name (if any)
/cr ghost           - Checks if in ghost mode
/cr healthhidden    - Checks if health is hidden
/cr blocked         - Checks if movement is blocked
/cr removed         - Checks if creature is removed
/cr cansee          - Checks if can see invisible
/cr events          - Lists all registered events
/cr light           - Shows light color and level
/cr speed           - Shows current and base speed
/cr position        - Shows x, y, z coordinates
/cr direction       - Shows facing direction
/cr health          - Shows current/max health (%)
/cr skull           - Shows skull type
/cr outfit          - Shows outfit details
/cr conditions      - Lists active conditions
/cr summons         - Lists summoned creatures
/cr description     - Shows full description
/cr zone            - Shows current zone type

/cr monster                    - Shows monster info
/cr monster rename Angry Rat   - Renames monster
/cr monster setidle true      - Sets monster to idle
/cr monster addfriend Bob     - Adds creature as friend
/cr monster addtarget Bob     - Adds creature as target
/cr monster listfriends       - Shows all friends
/cr monster returntospawn     - Makes monster return to spawn

Control Commands:
/cr setfollow       - Make creatures follow:
                      1. Target leader: /cr setfollow
                      2. Target follower: /cr setfollow bind
                      Or: /cr setfollow <name/none>

/cr settarget      - Make creatures target:
                     1. Target victim: /cr settarget
                     2. Target attacker: /cr settarget bind
                     Or: /cr settarget <name/none>

/cr setmaster      - Set creature's master: /cr setmaster <name/none>
/cr setmaxhealth   - Set max health: /cr setmaxhealth <amount>
/cr remove         - Remove creature from game
/cr tpto           - Teleport: /cr tpto x,y,z or x y z
/cr move           - Move: /cr move <north/east/south/west>
/cr setspeed       - Change speed: /cr setspeed <delta>
/cr setdroploot    - Toggle loot drops: /cr setdroploot <true/false>
/cr setskillloss   - Toggle skill loss: /cr setskillloss <true/false>
/cr setskull       - Set skull: /cr setskull <none/yellow/green/white/red/black/orange>
/cr addevent       - Register event: /cr addevent <eventname>
/cr removeevent    - Unregister event: /cr removeevent <eventname>

Examples:
/cr health        -> "Current: 150/200 (75.0%)"
/cr conditions    -> "Poison, Haste, In Fight"
/cr direction     -> "North"
/cr zone          -> "Protection"


/cr player                          - Shows all player info
/cr player setaccounttype 3        - Sets account type
/cr player setcapacity 1000        - Sets capacity to 1000
/cr player addexperience 5000      - Adds 5000 experience


]]



local talk = TalkAction("/creature", "/cr")

-- Create a local table to store follow bindings
local followBindings = {}


function talk.onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end

    -- Extract command and arguments
    local params = param:lower():trim():split(" ")
    local commandName = params[1]
    local isSelfTarget = commandName == "self"
    
    -- Handle empty command - show help
    if param == "" then
        -- Show available commands
        local cmdList = {}
        for cmd, info in pairs(commands) do
            table.insert(cmdList, cmd .. " - " .. info.desc)
        end
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Available commands:\n" .. table.concat(cmdList, "\n"))
        return false
    end

    -- Get target based on command type
    local target
    if isSelfTarget then
        target = player
        -- Shift parameters to remove "self"
        table.remove(params, 1)
        commandName = params[1]
    else
        -- Get position in front of player
        local position = player:getPosition()
        position:getNextPosition(player:getDirection())

        local tile = Tile(position)
        if not tile then
            target = player
        else
            target = tile:getTopCreature()
            if not target then
                target = player
            end
        end
    end

    -- Available commands/properties to check
    local commands = {
        ["events"] = {
            func = function(creature) 
                local events = creature:getEvents()
                return #events > 0 and table.concat(events, ", ") or "No events"
            end,
            desc = "List all registered events"
        },
        ["id"] = {
            func = function(creature) return creature:getId() end,
            desc = "Get creature ID"
        },
        ["name"] = {
            func = function(creature) return creature:getName() end,
            desc = "Get creature name"
        },
        ["target"] = {
            func = function(creature) 
                local target = creature:getTarget()
                return target and target:getName() or "No target"
            end,
            desc = "Get current target"
        },
        ["follow"] = {
            func = function(creature) 
                local follow = creature:getFollowCreature()
                return follow and follow:getName() or "Not following"
            end,
            desc = "Get followed creature"
        },
        ["master"] = {
            func = function(creature) 
                local master = creature:getMaster()
                return master and master:getName() or "No master"
            end,
            desc = "Get creature's master"
        },
        ["ghost"] = {
            func = function(creature) return creature:isInGhostMode() end,
            desc = "Check if in ghost mode"
        },
        ["healthhidden"] = {
            func = function(creature) return creature:isHealthHidden() end,
            desc = "Check if health is hidden"
        },
        ["blocked"] = {
            func = function(creature) return creature:isMovementBlocked() end,
            desc = "Check if movement is blocked"
        },
        ["removed"] = {
            func = function(creature) return creature:isRemoved() end,
            desc = "Check if creature is removed"
        },
        ["cansee"] = {
            func = function(creature) return creature:canSeeInvisibility() end,
            desc = "Check if can see invisible"
        },
        ["light"] = {
            func = function(creature) 
                local light = creature:getLight()
                return string.format("Color: %d, Level: %d", light.color, light.level)
            end,
            desc = "Get light info"
        },
        ["speed"] = {
            func = function(creature) 
                return string.format("Current: %d, Base: %d", creature:getSpeed(), creature:getBaseSpeed())
            end,
            desc = "Get speed info"
        },
        ["position"] = {
            func = function(creature) 
                local pos = creature:getPosition()
                return string.format("x: %d, y: %d, z: %d", pos.x, pos.y, pos.z)
            end,
            desc = "Get position"
        },
        ["direction"] = {
            func = function(creature) 
                local directions = {[0] = "North", [1] = "East", [2] = "South", [3] = "West"}
                return directions[creature:getDirection()] or "Unknown"
            end,
            desc = "Get facing direction"
        },
        ["health"] = {
            func = function(creature) 
                return string.format("Current: %d/%d (%.1f%%)", 
                    creature:getHealth(), 
                    creature:getMaxHealth(),
                    (creature:getHealth() / creature:getMaxHealth()) * 100)
            end,
            desc = "Get health info"
        },
        ["addhp"] = {
            func = function(creature, param) 
                local amount = tonumber(param) -- Convert param to number
                if not amount then
                    return "Usage: /cr addhp <amount>"
                end

               
                -- Add health to the target (either creature in front or self)
                creature:addHealth(amount)
                
                if target == creature then
                    return string.format("Added %d health to yourself.", amount)
                else
                    return string.format("Added %d health to %s.", amount, creature:getName())
                end
            end,
            desc = "Add health to the creature in front or self (usage: /cr addhp 100)"
        },
        ["addmp"] = {
            func = function(creature, param)
                local amount = tonumber(param)
                if not amount then
                    return "Usage: /cr addmp <amount>"
                end
        
                -- Add mana to the target (either creature in front or self)
                creature:addMana(amount)
                
                if target == creature then
                    return string.format("Added %d mana to yourself.", amount)
                else
                    return string.format("Added %d mana to %s.", amount, creature:getName())
                end
            end,
            desc = "Add mana to the creature in front or self (usage: /cr addmp 100)"
        },
        ["skull"] = {
            func = function(creature) 
                local skulls = {
                    [SKULL_NONE] = "None",
                    [SKULL_YELLOW] = "Yellow",
                    [SKULL_GREEN] = "Green",
                    [SKULL_WHITE] = "White",
                    [SKULL_RED] = "Red",
                    [SKULL_BLACK] = "Black",
                    [SKULL_ORANGE] = "Orange"
                }
                return skulls[creature:getSkull()] or "Unknown"
            end,
            desc = "Get skull type"
        },
        ["outfit"] = {
            func = function(creature) 
                local outfit = creature:getOutfit()
                return string.format("LookType: %d, Head: %d, Body: %d, Legs: %d, Feet: %d", 
                    outfit.lookType, outfit.lookHead, outfit.lookBody, 
                    outfit.lookLegs, outfit.lookFeet)
            end,
            desc = "Get outfit details"
        },
        ["conditions"] = {
            func = function(creature)
                local conditions = {
                    [CONDITION_POISON] = "Poison",
                    [CONDITION_FIRE] = "Fire",
                    [CONDITION_ENERGY] = "Energy",
                    [CONDITION_BLEEDING] = "Bleeding",
                    [CONDITION_HASTE] = "Haste",
                    [CONDITION_PARALYZE] = "Paralyze",
                    [CONDITION_INVISIBLE] = "Invisible",
                    [CONDITION_LIGHT] = "Light",
                    [CONDITION_MANASHIELD] = "Mana Shield",
                    [CONDITION_INFIGHT] = "In Fight",
                    [CONDITION_DRUNK] = "Drunk",
                    [CONDITION_REGENERATION] = "Regeneration"
                }
                local active = {}
                for conditionType, name in pairs(conditions) do
                    if creature:hasCondition(conditionType) then
                        table.insert(active, name)
                    end
                end
                return #active > 0 and table.concat(active, ", ") or "No conditions"
            end,
            desc = "List active conditions"
        },
        ["summons"] = {
            func = function(creature)
                local summons = creature:getSummons()
                if #summons == 0 then
                    return "No summons"
                end
                local names = {}
                for _, summon in ipairs(summons) do
                    table.insert(names, summon:getName())
                end
                return table.concat(names, ", ")
            end,
            desc = "List all summons"
        },
        ["description"] = {
            func = function(creature) return creature:getDescription(0) end,
            desc = "Get full description"
        },
        ["zone"] = {
            func = function(creature) 
                local zones = {
                    [ZONE_PROTECTION] = "Protection",
                    [ZONE_NOPVP] = "No-PvP",
                    [ZONE_PVP] = "PvP",
                    [ZONE_NOLOGOUT] = "No-Logout",
                    [ZONE_NORMAL] = "Normal"
                }
                return zones[creature:getZone()] or "Unknown"
            end,
            desc = "Get current zone"
        },
        ["settarget"] = {
            func = function(creature, param) 
                local targetCreature = Creature(param)
                if not targetCreature then
                    return "Target creature not found."
                end
                creature:setTarget(targetCreature)
                return string.format("Set target to: %s", targetCreature:getName())
            end,
            desc = "Set creature's target (usage: /cr settarget <name>)"
        },
        ["setfollow"] = {
            func = function(creature, param) 
                -- Check if we're storing first creature
                if not param or param == "" then
                    -- Store the current target creature as leader
                    if not followBindings[player:getId()] then
                        followBindings[player:getId()] = creature:getId()
                        return string.format("Selected %s as leader. Now target follower and use /cr setfollow bind", creature:getName())
                    else
                        followBindings[player:getId()] = nil
                        return "Cancelled follow binding process"
                    end
                end
        
                -- If param is 'bind', complete the process
                if param == "bind" then
                    if not followBindings[player:getId()] then
                        return "No leader selected. First target leader and use /cr setfollow, then target follower and use /cr setfollow bind"
                    end
        
                    -- Get the stored leader
                    local leader = Creature(followBindings[player:getId()])
                    if not leader then
                        followBindings[player:getId()] = nil
                        return "Leader creature no longer exists"
                    end
        
                    -- Set the follow relationship using the current target as follower
                    if creature:setFollowCreature(leader) then
                        local leaderType = leader:isPlayer() and "player" or leader:isNpc() and "NPC" or leader:isMonster() and "monster" or "creature"
                        local followerType = creature:isPlayer() and "player" or creature:isNpc() and "NPC" or creature:isMonster() and "monster" or "creature"
                        followBindings[player:getId()] = nil
                        return string.format("%s (%s) is now following %s (%s)", 
                            creature:getName(), followerType,
                            leader:getName(), leaderType)
                    else
                        followBindings[player:getId()] = nil
                        return "Failed to set follow relationship"
                    end
                end
        
                -- Handle the original name-based following
                if param == "none" then
                    creature:setFollowCreature(nil)
                    return "Stopped following"
                end
                
                local targetCreature = Creature(param)
                if not targetCreature then
                    return "Follow creature not found."
                end
                
                if creature:setFollowCreature(targetCreature) then
                    return string.format("Now following: %s", targetCreature:getName())
                else
                    return "Failed to set follow target."
                end
            end,
            desc = "Set creature to follow another (usage: /cr setfollow for two-step binding, or /cr setfollow <name/none>)"
        },
        ["setmaster"] = {
            func = function(creature, param) 
                if param == "none" then
                    creature:setMaster(nil)
                    return "Master removed"
                end
                
                local masterCreature = Creature(param)
                if not masterCreature then
                    return "Master creature not found."
                end
                creature:setMaster(masterCreature)
                return string.format("Set master to: %s", masterCreature:getName())
            end,
            desc = "Set creature's master (usage: /cr setmaster <name/none>)"
        },
        ["addevent"] = {
            func = function(creature, param) 
                if not param or param == "" then
                    return "Usage: /cr addevent <eventname>"
                end
                if creature:registerEvent(param) then
                    return string.format("Event '%s' registered", param)
                end
                return "Failed to register event"
            end,
            desc = "Register an event to creature (usage: /cr addevent <eventname>)"
        },
        ["removeevent"] = {
            func = function(creature, param) 
                if not param or param == "" then
                    return "Usage: /cr removeevent <eventname>"
                end
                if creature:unregisterEvent(param) then
                    return string.format("Event '%s' unregistered", param)
                end
                return "Failed to unregister event"
            end,
            desc = "Unregister an event from creature (usage: /cr removeevent <eventname>)"
        },
        ["setmaxhealth"] = {
            func = function(creature, param)
                local maxHealth = tonumber(param)
                if not maxHealth then
                    return "Usage: /cr setmaxhealth <amount>"
                end
                creature:setMaxHealth(maxHealth)
                return string.format("Set max health of %s to %d", creature:getName(), maxHealth)
            end,
            desc = "Set creature's maximum health (usage: /cr setmaxhealth <amount>)"
        },
        
        ["remove"] = {
            func = function(creature)
                creature:remove()
                return string.format("Removed creature: %s", creature:getName())
            end,
            desc = "Remove creature from the game"
        },
        
        ["tpto"] = {
            func = function(creature, param)
                if not param or param == "" then
                    return "Usage: /cr tpto x,y,z or x y z"
                end
                
                local x, y, z
                if param:find(",") then
                    x, y, z = param:match("(%d+),(%d+),(%d+)")
                else
                    x, y, z = param:match("(%d+)%s+(%d+)%s+(%d+)")
                end
                
                if not (x and y and z) then
                    return "Invalid position format. Use: x,y,z or x y z"
                end
                
                local position = Position(tonumber(x), tonumber(y), tonumber(z))
                if creature:teleportTo(position) then
                    return string.format("Teleported %s to %d,%d,%d", creature:getName(), position.x, position.y, position.z)
                end
                return "Failed to teleport creature"
            end,
            desc = "Teleport creature to position (usage: /cr tpto x,y,z or x y z)"
        },
        
        ["move"] = {
            func = function(creature, param)
                local directions = {
                    north = DIRECTION_NORTH,
                    east = DIRECTION_EAST,
                    south = DIRECTION_SOUTH,
                    west = DIRECTION_WEST
                }
                local direction = directions[param:lower()]
                if not direction then
                    return "Usage: /cr move <north/east/south/west>"
                end
                
                if creature:move(direction) then
                    return string.format("Moved %s %s", creature:getName(), param:lower())
                end
                return "Failed to move creature"
            end,
            desc = "Move creature in direction (usage: /cr move <north/east/south/west>)"
        },
        
        ["setspeed"] = {
            func = function(creature, param)
                local delta = tonumber(param)
                if not delta then
                    return "Usage: /cr setspeed <delta>"
                end
                
                creature:changeSpeed(delta)
                return string.format("Changed speed of %s by %d", creature:getName(), delta)
            end,
            desc = "Change creature's speed (usage: /cr setspeed <delta>)"
        },
        
        ["setdroploot"] = {
            func = function(creature, param)
                local doDrop = param:lower() == "true"
                creature:setDropLoot(doDrop)
                return string.format("Set loot dropping for %s to: %s", creature:getName(), tostring(doDrop))
            end,
            desc = "Set if creature drops loot (usage: /cr setdroploot <true/false>)"
        },
        
        ["setskillloss"] = {
            func = function(creature, param)
                local skillLoss = param:lower() == "true"
                creature:setSkillLoss(skillLoss)
                return string.format("Set skill loss for %s to: %s", creature:getName(), tostring(skillLoss))
            end,
            desc = "Set if creature can lose skills (usage: /cr setskillloss <true/false>)"
        },
        
        ["setskull"] = {
            func = function(creature, param)
                local skulls = {
                    none = 0,
                    yellow = 1,
                    green = 2,
                    white = 3,
                    red = 4,
                    black = 5,
                    orange = 6
                }
                
                local skull = skulls[param:lower()]
                if not skull then
                    return "Usage: /cr setskull <none/yellow/green/white/red/black/orange>"
                end
                
                creature:setSkull(skull)
                return string.format("Set skull of %s to: %s", creature:getName(), param:lower())
            end,
            desc = "Set creature's skull type (usage: /cr setskull <type>)"
        },
        ["monster"] = {
            func = function(creature, param)
                if not creature:isMonster() then
                    return "This command only works on monsters"
                end
                
                local monster = Monster(creature:getId())
                
                -- Show monster info if no parameter
                if not param or param == "" then
                    local spawnPos = monster:getSpawnPosition()
                    local spawnPosStr = spawnPos and string.format("%d,%d,%d", spawnPos.x, spawnPos.y, spawnPos.z) or "No spawn position"
                    
                    return string.format("Monster: %s (ID: %d)\nSpawn Position: %s\nIn Spawn Range: %s\nIdle: %s\nWalking to Spawn: %s\nTargets: %d\nFriends: %d",
                        monster:getName(),
                        monster:getId(),
                        spawnPosStr,
                        tostring(monster:isInSpawnRange()),
                        tostring(monster:isIdle()),
                        tostring(monster:isWalkingToSpawn()),
                        monster:getTargetCount(),
                        monster:getFriendCount()
                    )
                end

                local cmd, value = param:match("^(%w+)%s*(.*)$")
                if not cmd then return "Invalid command format" end
                
                cmd = cmd:lower()
                
                local commands = {
                    rename = function(val)
                        if val == "" then return "Usage: /cr monster rename <name> [description]" end
                        local name, desc = val:match("^([^,]+),?%s*(.*)$")
                        if monster:rename(name, desc ~= "" and desc or nil) then
                            return string.format("Renamed monster to: %s", name)
                        end
                        return "Failed to rename monster"
                    end,
                    
                    setidle = function(val)
                        local idle = val:lower() == "true"
                        monster:setIdle(idle)
                        return string.format("Set monster idle state to: %s", tostring(idle))
                    end,
                    
                    addfriend = function(val)
                        if val == "" then return "Usage: /cr monster addfriend <id>" end
                        local friendId = tonumber(val)
                        if not friendId then return "Invalid creature ID" end
                        local friend = Creature(friendId)
                        if not friend then return "Friend creature not found with ID: " .. friendId end
                        if monster:addFriend(friend) then
                            return string.format("Added %s (ID: %d) as friend", friend:getName(), friendId)
                        end
                        return "Failed to add friend"
                    end,
                    
                    removefriend = function(val)
                        if val == "" then return "Usage: /cr monster removefriend <id>" end
                        local friendId = tonumber(val)
                        if not friendId then return "Invalid creature ID" end
                        local friend = Creature(friendId)
                        if not friend then return "Friend creature not found with ID: " .. friendId end
                        if monster:removeFriend(friend) then
                            return string.format("Removed %s (ID: %d) from friends", friend:getName(), friendId)
                        end
                        return "Failed to remove friend"
                    end,
                    
                    addtarget = function(val)
                        if val == "" then return "Usage: /cr monster addtarget <id> [front]" end
                        local targetId, front = val:match("^(%d+)%s*(.*)$")
                        targetId = tonumber(targetId)
                        if not targetId then return "Invalid creature ID" end
                        local target = Creature(targetId)
                        if not target then return "Target creature not found with ID: " .. targetId end
                        if monster:addTarget(target, front:lower() == "front") then
                            return string.format("Added %s (ID: %d) to targets", target:getName(), targetId)
                        end
                        return "Failed to add target"
                    end,
                    
                    removetarget = function(val)
                        if val == "" then return "Usage: /cr monster removetarget <id>" end
                        local targetId = tonumber(val)
                        if not targetId then return "Invalid creature ID" end
                        local target = Creature(targetId)
                        if not target then return "Target creature not found with ID: " .. targetId end
                        if monster:removeTarget(target) then
                            return string.format("Removed %s (ID: %d) from targets", target:getName(), targetId)
                        end
                        return "Failed to remove target"
                    end,
                    
                    listfriends = function()
                        local friends = monster:getFriendList()
                        if #friends == 0 then return "No friends" end
                        local info = {}
                        for _, friend in ipairs(friends) do
                            table.insert(info, string.format("%s (ID: %d)", friend:getName(), friend:getId()))
                        end
                        return "Friends: " .. table.concat(info, ", ")
                    end,
                    
                    listtargets = function()
                        local targets = monster:getTargetList()
                        if #targets == 0 then return "No targets" end
                        local info = {}
                        for _, target in ipairs(targets) do
                            table.insert(info, string.format("%s (ID: %d)", target:getName(), target:getId()))
                        end
                        return "Targets: " .. table.concat(info, ", ")
                    end
                }
                
                if commands[cmd] then
                    return commands[cmd](value)
                end
                
                return string.format("Unknown monster command: %s", cmd)
            end,
            desc = "Monster controls (usage: /cr monster <command> [params]). Commands: rename, setidle, addfriend <id>, removefriend <id>, addtarget <id>, removetarget <id>, listfriends, listtargets"
        },
        ["player"] = {
            func = function(creature, param)
                if not creature:isPlayer() then
                    return "This command only works on players"
                end
                
                local player = Player(creature:getId())
                
                -- Show player info if no parameter
                if not param or param == "" then
                    local lastLogin = os.date("%Y-%m-%d %H:%M:%S", player:getLastLoginSaved())
                    local lastLogout = os.date("%Y-%m-%d %H:%M:%S", player:getLastLogout())
                    
                    return string.format([[
Player: %s (ID: %d)
GUID: %d
IP: %s
Account ID: %d
Account Type: %d
Last Login: %s
Last Logout: %s
Capacity: %d/%d (Free: %d)
Experience: %d
Skull Time: %d
Death Penalty: %.2f%%]],
                        player:getName(),
                        player:getId(),
                        player:getGuid(),
                        player:getIp(),
                        player:getAccountId(),
                        player:getAccountType(),
                        lastLogin,
                        lastLogout,
                        player:getCapacity(),
                        player:getFreeCapacity(),
                        player:getCapacity() - player:getFreeCapacity(),
                        player:getExperience(),
                        player:getSkullTime(),
                        player:getDeathPenalty() * 100
                    )
                end

                local cmd, value = param:match("^(%w+)%s*(.*)$")
                if not cmd then return "Invalid command format" end
                
                cmd = cmd:lower()
                
                local commands = {
                    setaccounttype = function(val)
                        local accountType = tonumber(val)
                        if not accountType then
                            return "Usage: /cr player setaccounttype <type>"
                        end
                        player:setAccountType(accountType)
                        return string.format("Set account type to: %d", accountType)
                    end,
                    
                    setcapacity = function(val)
                        local capacity = tonumber(val)
                        if not capacity then
                            return "Usage: /cr player setcapacity <amount>"
                        end
                        player:setCapacity(capacity)
                        return string.format("Set capacity to: %d", capacity)
                    end,
                    
                    setskulltime = function(val)
                        local skullTime = tonumber(val)
                        if not skullTime then
                            return "Usage: /cr player setskulltime <time>"
                        end
                        player:setSkullTime(skullTime)
                        return string.format("Set skull time to: %d", skullTime)
                    end,
                    
                    addexperience = function(val)
                        local exp = tonumber(val)
                        if not exp then
                            return "Usage: /cr player addexperience <amount>"
                        end
                        player:addExperience(exp, true)
                        return string.format("Added %d experience", exp)
                    end,
                    
                    getmagiclevel = function()
                        return string.format("Magic Level: %d (Base: %d)", 
                            player:getMagicLevel(),
                            player:getBaseMagicLevel())
                    end,
                    
                    countitem = function(val)
                        local itemId = tonumber(val)
                        if not itemId then
                            return "Usage: /cr player countitem <itemId>"
                        end
                        return string.format("Item count: %d", player:getItemCount(itemId))
                    end,
                    
                    finditem = function(val)
                        local itemId = tonumber(val)
                        if not itemId then
                            return "Usage: /cr player finditem <itemId>"
                        end
                        local item = player:getItemById(itemId, true)
                        return item and "Item found" or "Item not found"
                    end,
                    
                    setsex = function(val)
                        local sex = tonumber(val)
                        if not sex or (sex ~= 0 and sex ~= 1) then
                            return "Usage: /cr player setsex <0/1>"
                        end
                        player:setSex(sex)
                        return string.format("Set sex to: %d", sex)
                    end,
                    
                    settown = function(val)
                        local townId = tonumber(val)
                        if not townId then
                            return "Usage: /cr player settown <townId>"
                        end
                        local town = Town(townId)
                        if not town then
                            return "Invalid town ID"
                        end
                        player:setTown(town)
                        return string.format("Set town to: %s", town:getName())
                    end,
                    
                    setstamina = function(val)
                        local stamina = tonumber(val)
                        if not stamina then
                            return "Usage: /cr player setstamina <minutes>"
                        end
                        player:setStamina(stamina)
                        return string.format("Set stamina to: %d minutes", stamina)
                    end,
                    
                    addsoul = function(val)
                        local soul = tonumber(val)
                        if not soul then
                            return "Usage: /cr player addsoul <amount>"
                        end
                        player:addSoul(soul)
                        return string.format("Added %d soul points", soul)
                    end,
                    
                    setbalance = function(val)
                        local balance = tonumber(val)
                        if not balance then
                            return "Usage: /cr player setbalance <amount>"
                        end
                        player:setBankBalance(balance)
                        return string.format("Set bank balance to: %d", balance)
                    end,
                    
                    additem = function(val)
                        if val == "" then return "Usage: /cr player additem <itemId> [count] [canDrop] [subType] [slot]" end
                        local args = val:split(" ")
                        local itemId = tonumber(args[1])
                        if not itemId then return "Invalid item ID" end
                        
                        local count = tonumber(args[2]) or 1
                        local canDrop = args[3] and args[3]:lower() == "true"
                        local subType = tonumber(args[4]) or 1
                        local slot = tonumber(args[5])
                        
                        local item = player:addItem(itemId, count, canDrop, subType, slot)
                        if item then
                            return string.format("Added %dx %d to inventory", count, itemId)
                        end
                        return "Failed to add item"
                    end,
                    
                    removeitem = function(val)
                        if val == "" then return "Usage: /cr player removeitem <itemId> <count> [subType] [ignoreEquipped]" end
                        local args = val:split(" ")
                        local itemId = tonumber(args[1])
                        local count = tonumber(args[2])
                        if not (itemId and count) then return "Invalid item ID or count" end
                        
                        local subType = tonumber(args[3]) or -1
                        local ignoreEquipped = args[4] and args[4]:lower() == "true"
                        
                        if player:removeItem(itemId, count, subType, ignoreEquipped) then
                            return string.format("Removed %dx %d from inventory", count, itemId)
                        end
                        return "Failed to remove item"
                    end,
                    
                    money = function(val)
                        if not val or val == "" then
                            return string.format("Current money: %d", player:getMoney())
                        end
                        
                        local amount = tonumber(val)
                        if not amount then return "Invalid amount" end
                        
                        if amount > 0 then
                            player:addMoney(amount)
                            return string.format("Added %d money", amount)
                        else
                            if player:removeMoney(-amount) then
                                return string.format("Removed %d money", -amount)
                            end
                            return "Not enough money"
                        end
                    end,
                    
                    showtext = function(val)
                        if val == "" then return "Usage: /cr player showtext <itemId> [text] [canWrite] [length]" end
                        local args = val:split(" ")
                        local itemId = tonumber(args[1])
                        if not itemId then return "Invalid item ID" end
                        
                        table.remove(args, 1)
                        local text = table.concat(args, " ")
                        local canWrite = text:find("--write")
                        if canWrite then
                            text = text:gsub("--write", ""):trim()
                        end
                        
                        player:showTextDialog(itemId, text, canWrite)
                        return "Showing text dialog"
                    end
                }
                
                if commands[cmd] then
                    return commands[cmd](value)
                end
                
                return string.format("Unknown player command: %s", cmd)
            end,
            desc = [[Player controls (usage: /cr player <command> [params]). 
Commands: 
- setaccounttype <type>
- setcapacity <amount>
- setskulltime <time>
- addexperience <amount>
- getdepot <id>
- getinbox
- getmagiclevel
- countitem <itemId>
- finditem <itemId>
- setsex <0/1>
- settown <townId>
- setstamina <minutes>
- addsoul <amount>
- setbalance <amount>
- additem <itemId> [count] [canDrop] [subType] [slot]
- removeitem <itemId> <count> [subType] [ignoreEquipped]
- money <amount>
- showtext <itemId> [text] [canWrite] [length]]
        }
    }

    -- Get the command
    local command = commands[commandName]
    if not command then
        player:sendCancelMessage("Invalid command. Use /cr for list of commands.")
        return false
    end

    -- Build argument string for commands that need additional parameters
    local argString = ""
    if #params > 1 then
        table.remove(params, 1) -- Remove command name
        argString = table.concat(params, " ")
    end
    
    -- Execute the command safely
    local success, result = pcall(command.func, target, argString)
    if not success then
        print("Error executing command: " .. tostring(result))
        return false
    end
    
    -- Format the result message
    local message
    if type(result) == "boolean" then
        message = string.format("Result for %s: %s", commandName, result and "true" or "false")
    else
        message = string.format("Result for %s: %s", commandName, tostring(result))
    end
    
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, message)
    --player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
    return false
end

talk:separator(" ")
talk:register() 