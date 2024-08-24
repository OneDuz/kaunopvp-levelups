local page = 1
local limit = 10

RegisterCommand("xp", function(src, args, _)
    lib.callback('one-codes:levels:GetData', src, function(data)
        print(json.encode(data))
        local procents = (data.xp / data.needxp) * 100 -- Apskaičiuoti XP procentus

        lib.registerContext({
            id = 'some_menu',
            title = 'Lygis: '..data.level..'',
            options = {
                {
                    description = ''..data.xp..'/'..data.needxp..' XP',
                    progress = procents,
                    colorScheme = "blue",
                },
                {
                    title = 'Jums reikia '..(data.needxp - data.xp)..' daugiau XP, kad pakiltumėte lygiu',
                },
                {
                    title = 'Kitas lygio atlygis',
                    description = ""..data.nextreward.."$",
                    icon = 'money-bill',
                },
                {
                    title = 'Lyderių lentelė',
                    icon = 'list-ol',
                    onSelect = function()
                        lib.callback('one-codes:levels:GetLeaderboard', 1, function(leaderboardData)
                            local leaderboardOptions = {}
                            for i, entry in ipairs(leaderboardData) do
                                table.insert(leaderboardOptions, {
                                    title = (i + (page - 1) * limit) .. '. ' .. entry.name,
                                    description = 'Lygis: ' .. entry.level .. ' XP: ' .. entry.xp
                                })
                            end
                
                            lib.registerContext({
                                id = 'leaderboard_menu',
                                title = 'Lyderių lentelė',
                                options = leaderboardOptions
                            })
                            lib.showContext('leaderboard_menu')
                        end, page)
                    end
                },
                {
                    title = 'Administratoriaus meniu',
                    icon = 'user-tie',
                    disabled = true,
                },
            }
        })
        lib.registerContext({
            id = 'admin_menu',
            title = 'Lygis: '..data.level..'',
            options = {
                {
                    description = ''..data.xp..'/'..data.needxp..' XP',
                    progress = procents,
                    colorScheme = "blue",
                },
                {
                    title = 'Jums reikia '..(data.needxp - data.xp)..' daugiau XP, kad pakiltumėte lygiu',
                },
                {
                    title = 'Kitas lygio atlygis',
                    description = ""..data.nextreward.."$",
                    icon = 'money-bill',
                },
                {
                    title = 'Lyderių lentelė',
                    icon = 'list-ol',
                    onSelect = function()
                        lib.callback('one-codes:levels:GetLeaderboard', src, function(leaderboardData)
                            print(json.encode(leaderboardData))
                            local leaderboardOptions = {}
                            for i, entry in ipairs(leaderboardData) do
                                table.insert(leaderboardOptions, {
                                    title = (i + (page - 1) * limit) .. '. ' .. entry.name,
                                    description = 'Lygis: ' .. entry.level .. ' XP: ' .. entry.xp
                                })
                            end
                
                            lib.registerContext({
                                id = 'leaderboard_menu',
                                title = 'Lyderių lentelė',
                                options = leaderboardOptions
                            })
                            lib.showContext('leaderboard_menu')
                        end, page)
                    end
                },
                {
                    title = 'Administratoriaus meniu',
                    icon = 'user-tie',
                    onSelect = function()
                        lib.showContext('admin_menu2')
                    end
                },
            }
        })
        lib.callback('one-codes:levels:GetAdmin', src, function(data)
            if data then
                lib.showContext('admin_menu')
            else
                lib.showContext('some_menu')
            end
        end)
    end)
end)

lib.registerContext({
    id = 'admin_menu2',
    title = 'Administratoriaus Meniu Lygių Sistema',
    menu = "admin_menu",
    onExit = function ()
        lib.showContext('admin_menu')
    end,
    options = {
        {
            title = 'Duoti XP sau',
            icon = 'user-tie',
            onSelect = function()
                local input = lib.inputDialog('Administratoriaus Meniu', {
                    {type = 'number', label = 'Kiek duoti?'},
                })
                if not input then return end
                local amount = tonumber(input[1])
                if amount then
                    lib.callback('one-codes:levels:AddXP', src, function() end, amount, false)
                end
                lib.showContext('admin_menu2')
            end,
        },
        {
            title = 'Nustatyti XP sau',
            icon = 'user-tie',
            onSelect = function()
                local input = lib.inputDialog('Administratoriaus Meniu', {
                    {type = 'number', label = 'Nustatyti XP iki:'},
                })
                if not input then return end
                local xp = tonumber(input[1])
                if xp then
                    lib.callback('one-codes:levels:SetXP', src, function() end, xp)
                end
                lib.showContext('admin_menu2')
            end,
        },
        {
            title = 'Nustatyti lygį sau',
            icon = 'user-tie',
            onSelect = function()
                local input = lib.inputDialog('Administratoriaus Meniu', {
                    {type = 'number', label = 'Nustatyti lygį iki:'},
                })
                if not input then return end
                local level = tonumber(input[1])
                if level then
                    lib.callback('one-codes:levels:SetLevel', src, function() end, level)
                end
                lib.showContext('admin_menu2')
            end,
        },
        {
            title = 'Duoti XP kitam',
            icon = 'user-tie',
            onSelect = function()
                local input = lib.inputDialog('Administratoriaus Meniu', {
                    {type = 'number', label = 'Žaidėjo ID'},
                    {type = 'number', label = 'Kiek duoti?'},
                })
                if not input then return end
                local targetId = tonumber(input[1])
                local amount = tonumber(input[2])
                if targetId and amount then
                    lib.callback('one-codes:levels:AddXP', targetId, function() end, amount, true)
                end
                lib.showContext('admin_menu2')
            end,
        },
        {
            title = 'Nustatyti XP kitam',
            icon = 'user-tie',
            onSelect = function()
                local input = lib.inputDialog('Administratoriaus Meniu', {
                    {type = 'number', label = 'Žaidėjo ID'},
                    {type = 'number', label = 'Nustatyti XP iki:'},
                })
                if not input then return end
                local targetId = tonumber(input[1])
                local xp = tonumber(input[2])
                if targetId and xp then
                    lib.callback('one-codes:levels:SetXP', targetId, function() end, xp)
                end
                lib.showContext('admin_menu2')
            end,
        },
        {
            title = 'Nustatyti lygį kitam',
            icon = 'user-tie',
            onSelect = function()
                local input = lib.inputDialog('Administratoriaus Meniu', {
                    {type = 'number', label = 'Žaidėjo ID'},
                    {type = 'number', label = 'Nustatyti lygį iki:'},
                })
                if not input then return end
                local targetId = tonumber(input[1])
                local level = tonumber(input[2])
                if targetId and level then
                    lib.callback('one-codes:levels:SetLevel', targetId, function() end, level)
                end
                lib.showContext('admin_menu2')
            end,
        },
        {
            title = 'Gauti informaciją apie kažką',
            icon = 'user-tie',
            onSelect = function()
                local input = lib.inputDialog('Administratoriaus Meniu', {
                    {type = 'number', label = 'Žaidėjo ID'},
                })
                if not input then return end
                local targetId = tonumber(input[1])
                if targetId then
                    lib.callback('one-codes:levels:GetData', targetId, function(data)
                        if data then
                            TriggerEvent('esx:showNotification', 'Lygis: ' .. data.level .. ', XP: ' .. data.xp .. '/' .. data.needxp)
                        end
                    end)
                end
                lib.showContext('admin_menu2')
            end,
        },
    }
})


CreateThread(function()
    while true do 
        Wait(300000)
        lib.callback('one-codes:levels:AddXP', source, function() end, 5, false, "Del 5min playtime")
    end
end)