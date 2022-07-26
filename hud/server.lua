if Config.FrameWork == 'ESX' then
    ESX = nil
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

    ESX.RegisterServerCallback('esx-tirex_to_kokx:pma-voice', function(source, cb)
        local plyState = Player(source).state
        local proximity = plyState.proximity
        if proximity ~= nil then
            cb(proximity.mode)
        else
            cb(nil)
        end
    end)
elseif Config.FrameWork == 'QB' then
    local QBCore = exports['qb-core']:GetCoreObject()

    QBCore.Functions.CreateCallback('qb-tirex_to_kokx:pma-voice', function(source, cb)
        local plyState = Player(source).state
        local proximity = plyState.proximity
        if proximity ~= nil then
            cb(proximity.mode)
        else
            cb(nil)
        end
    end)

    RegisterNetEvent('hud:server:GainStress', function(amount)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local newStress
        if not Player or (Config.DisablePoliceStress and Player.PlayerData.job.name == 'police') then return end
        if not ResetStress then
            if not Player.PlayerData.metadata['stress'] then
                Player.PlayerData.metadata['stress'] = 0
            end
            newStress = Player.PlayerData.metadata['stress'] + amount
            if newStress <= 0 then newStress = 0 end
        else
            newStress = 0
        end
        if newStress > 100 then
            newStress = 100
        end
        Player.Functions.SetMetaData('stress', newStress)
        TriggerClientEvent('hud:client:UpdateStress', src, newStress)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.stress_gain"), 'error', 1500)
    end)
    
    RegisterNetEvent('hud:server:RelieveStress', function(amount)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local newStress
        if not Player then return end
        if not ResetStress then
            if not Player.PlayerData.metadata['stress'] then
                Player.PlayerData.metadata['stress'] = 0
            end
            newStress = Player.PlayerData.metadata['stress'] - amount
            if newStress <= 0 then newStress = 0 end
        else
            newStress = 0
        end
        if newStress > 100 then
            newStress = 100
        end
        Player.Functions.SetMetaData('stress', newStress)
        TriggerClientEvent('hud:client:UpdateStress', src, newStress)
        TriggerClientEvent('QBCore:Notify', src, Lang:t("notify.stress_removed"))
    end)
end