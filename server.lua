ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local function ensurePlayerData(identifier, cb)
    local steamName = GetPlayerName(source)
    MySQL.Async.fetchAll('SELECT level, xp, needxp, steam_name FROM player_levels WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        if result and result[1] then
            if result[1].steam_name ~= steamName then
                MySQL.Async.execute('UPDATE player_levels SET steam_name = @steamName WHERE identifier = @identifier', {
                    ['@steamName'] = steamName,
                    ['@identifier'] = identifier
                })
            end
            if cb then cb(result[1]) end
        else
            MySQL.Async.execute('INSERT INTO player_levels (identifier, level, xp, needxp, steam_name) VALUES (@identifier, 1, 0, 100, @steamName)', {
                ['@identifier'] = identifier,
                ['@steamName'] = steamName
            }, function(rowsChanged)
                if cb then cb({level = 1, xp = 0, needxp = 100, steam_name = steamName}) end
            end)
        end
    end)
end


-- GetData Callback
lib.callback.register('one-codes:levels:GetData', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.getIdentifier()

    local data = {}
    ensurePlayerData(identifier, function(playerData)
        data = playerData
        data.nextreward = math.min(config.StartMoney + (config.RewardIncrease * (playerData.level - 1)), 1000000)
    end)

    Wait(150)
    return data
end)

-- GetAdmin Callback
lib.callback.register('one-codes:levels:GetAdmin', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getGroup() ~= "user" then
        return true
    else
        return false
    end
end)

-- SetXP Callback
lib.callback.register('one-codes:levels:SetXP', function(src, xp)
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.getIdentifier()

    MySQL.Async.execute('UPDATE player_levels SET xp = @xp WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@xp'] = xp
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Lygio Padidėjimas [ADMIN]',
                position = "top",
                description = 'Jūsų XP buvo atnaujintas iki ' .. xp,
                type = 'info'
            })
            -- local data = {
            --     ['Player'] = src,
            --     ['Log'] = 'levelup',
            --     ['Title'] = 'Set XP',
            --     ['Message'] = 'Administrator set XP to: ' .. xp .. ' for player',
            --     ['Color'] = 'blue',
            -- }
            -- TriggerEvent('Boost-Logs:SendLog', data)
            -- use this if you have lovely boost-logs that are lovely and very lovely and lovely
        end
    end)
end)


if config.VIPsystem then
    function IsVIP(playerId)
        local identifiers = GetPlayerIdentifiers(playerId)
        local licenseIdentifier = nil
    
        for _, id in ipairs(identifiers) do
            if string.match(id, "discord:") then
                licenseIdentifier = id
                break
            end
        end
    
        local data = { isVip = false, daysLeft = 0 }
    
        if licenseIdentifier then
            local result = MySQL.Sync.fetchAll(
            'SELECT DATEDIFF(vip_expiration, CURDATE()) AS days_left FROM player_vip_status WHERE identifier = @identifier AND is_vip = TRUE AND vip_expiration >= CURDATE()',
                {
                    ['@identifier'] = licenseIdentifier
                })
    
            if result and #result > 0 and result[1].days_left then
                local daysLeft = tonumber(result[1].days_left)
                if daysLeft > 0 then
                    data.isVip = true
                    data.daysLeft = daysLeft
                end
            end
        end
    
        return data
    end
else
    function IsVIP()
        return false
    end
end

-- SetLevel Callback
lib.callback.register('one-codes:levels:SetLevel', function(src, level)
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.getIdentifier()
    local newXP = 0 
    local needxp = 100 + ((level - 1) * config.BaseXP)

    MySQL.Async.execute('UPDATE player_levels SET level = @level, xp = @xp, needxp = @needxp WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@level'] = level,
        ['@xp'] = newXP,
        ['@needxp'] = needxp
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Lygio Atnaujinimas [ADMIN]',
                position = "top",
                description = 'Jūsų lygis buvo atnaujintas iki ' .. level .. ' ir XP iki ' .. newXP,
                type = 'info'
            })
            -- local data = {
            --     ['Player'] = src,
            --     ['Log'] = 'levelup',
            --     ['Title'] = 'Set Level',
            --     ['Message'] = 'Administrator set level to: ' .. level .. ' for player',
            --     ['Color'] = 'blue',
            -- }
            -- TriggerEvent('Boost-Logs:SendLog', data)
            -- use this if you have lovely boost-logs that are lovely and very lovely and lovely
        end
    end)
end)



-- AddXP Callback
lib.callback.register('one-codes:levels:AddXP', function(src, addedXP, admin, reason)
    local xPlayer = ESX.GetPlayerFromId(src)
    local identifier = xPlayer.getIdentifier()

    ensurePlayerData(identifier, function(playerData)
        local newXP = playerData.xp + addedXP
        local levelUp = false
        local moneyReward = 0 

        while newXP >= playerData.needxp do
            newXP = newXP - playerData.needxp
            playerData.level = playerData.level + 1
            playerData.needxp = playerData.needxp + config.BaseXP
            levelUp = true
            moneyReward = math.min(config.StartMoney + (config.RewardIncrease * (playerData.level - 1)), 1000000) - 10000
        end

        local vipData = IsVIP(src)
        local xpMultiplier = vipData.isVip and 2 or 1 
        newXP = newXP * xpMultiplier

        MySQL.Async.execute('UPDATE player_levels SET level = @level, xp = @xp, needxp = @needxp WHERE identifier = @identifier', {
            ['@identifier'] = identifier,
            ['@level'] = playerData.level,
            ['@xp'] = newXP,
            ['@needxp'] = playerData.needxp
        }, function(rowsChanged)
            if levelUp then
                if not admin then
                    xPlayer.addAccountMoney('bank', moneyReward)
                    local notificationText = vipData.isVip and 'VIP narys 2X XP!' or 'Lygio Padidėjimas!'
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = notificationText,
                        position = "top",
                        description = 'Sveikiname! Jūs pasiekėte ' .. playerData.level .. ' lygį. Jums pervedėme ' .. moneyReward .. '$ į banką.',
                        type = 'success'
                    })
                else
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'Lygio Atnaujinimas [ADMIN]',
                        position = "top",
                        description = 'Jūsų lygis atnaujintas iki ' .. playerData.level,
                        type = 'info'
                    })
                    -- local data = {
                    --     ['Player'] = src,
                    --     ['Log'] = 'levelup',
                    --     ['Title'] = 'Add XP [ADMIN]',
                    --     ['Message'] = 'Administrator added ' .. addedXP .. ' XP for player',
                    --     ['Color'] = 'blue',
                    -- }
                    -- TriggerEvent('Boost-Logs:SendLog', data)
                    -- use this if you have lovely boost-logs that are lovely and very lovely and lovely
                end
            else
                if addedXP > 0 then
                    local notificationText = vipData.isVip and 'VIP narys 2X XP!' or 'XP Pridėtas!'
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = notificationText,
                        position = "top",
                        description = 'Jūs gavote ' .. addedXP .. ' XP. ' .. (reason or 'Jokių papildomų duomenų.'),
                        type = 'info'
                    })
                end
            end
        end)
    end)
end)


-- GetLeaderboard Callback
lib.callback.register('one-codes:levels:GetLeaderboard', function(src, page)
    local limit = 10
    local offset = (page - 1) * limit
    local leaderboardData = {}

    MySQL.Async.fetchAll(
    'SELECT identifier, steam_name, level, xp FROM player_levels ORDER BY level DESC LIMIT @limit OFFSET @offset', {
        ['@limit'] = limit,
        ['@offset'] = offset
    }, function(results)
        for _, result in ipairs(results) do
            table.insert(leaderboardData, {
                name = result.steam_name,
                level = result.level,
                xp = result.xp
            })
        end
    end)
    
    Wait(150)
    return leaderboardData
end)
