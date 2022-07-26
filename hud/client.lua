local currentValues = {
	["health"] = 0,
	["armor"] = 0,
	["hunger"] = 0,
	["thirst"] = 0,
    ["drunk"] = 0,
    ["stress"] = 0,
	["oxy"] = 100,
    ["maxOxy"] = 0,

    ["timeH"] = 0,
    ["timeM"] = 0,

    ["isInVehicle"] = false,
    ["gamePaused"] = false,

    ["vehicleSpeed"] = 0,
    ["carFuel"] = 0,
    ["location"] = 'Los Santos',
    ["direction"] = 'N',
    ["waypointDistance"] = 0,

    ["hudToogle"] = true,

    ["isTalking"] = false,
    ["talkingRange"] = 'Normal'
}

local directions = {
    N = 360, 0,
    NE = 315,
    E = 270,
    SE = 225,
    S = 180,
    SW = 135,
    W = 90,
    NW = 45
}

ESX = nil
local QBCore = nil
if Config.FrameWork == "QB" then
    QBCore = exports['qb-core']:GetCoreObject()
end

Citizen.CreateThread(function()
    if Config.FrameWork == "ESX" then
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
        ESX.PlayerData = ESX.GetPlayerData()
    end

    local pid = PlayerId()
    currentValues["maxOxy"] = GetPlayerUnderwaterTimeRemaining(pid)
end)

UpdateVoice = function(mode, isTalking)
    SendNUIMessage({ type = 'UPDATE_VOICE', mode = mode, isTalking = isTalking })
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        if currentValues["gamePaused"] ~= 1 then
            if IsControlJustReleased(1, 348) then
                currentValues["hudToogle"] = not currentValues["hudToogle"]
                SendNUIMessage({ type = 'TOGGLE_HUD', toogle = currentValues["hudToogle"] })
            end
        end
    end
end)

Citizen.CreateThread(function ()
    while true do
        Citizen.Wait(100)
        -- BeginScaleformMovieMethod(minimap, 'HIDE_SATNAV') 
        -- EndScaleformMovieMethod() 
        if currentValues["hudToogle"] then
            local pid = PlayerId()
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local playerHeading = GetEntityHeading(ped)
            local vehicle = GetVehiclePedIsIn(ped, false)

            local percentHP = GetEntityHealth(ped) / GetPedMaxHealth(ped) * 100

            currentValues["health"] = percentHP
            currentValues["armor"] = GetPedArmour(ped)

            if GetPlayerUnderwaterTimeRemaining(pid) > currentValues["maxOxy"] then
                currentValues["maxOxy"] = GetPlayerUnderwaterTimeRemaining(pid)
            end
            currentValues["oxy"] = GetPlayerUnderwaterTimeRemaining(pid) / currentValues["maxOxy"] * 100

            currentValues["timeH"] = GetClockHours()
            currentValues["timeM"] = GetClockMinutes()

            currentValues["isInVehicle"] = IsPedInAnyVehicle(ped, true)
            currentValues["gamePaused"] = ThefeedIsPaused()

            currentValues["isTalking"] = MumbleIsPlayerTalking(pid)
            if Config.FrameWork == "ESX" then
                ESX.TriggerServerCallback('esx-tirex_to_kokx:pma-voice', function(data)
                    if data ~= nil then
                        SendNUIMessage({ type = 'UPDATE_VOICE', mode = data })
                    else
                        if NetworkGetTalkerProximity() == 3.5 then
                            SendNUIMessage({ type = 'UPDATE_VOICE', mode = 'Whisper' })
                        elseif NetworkGetTalkerProximity() == 10.0 then
                            SendNUIMessage({ type = 'UPDATE_VOICE', mode = 'Normal' })
                        elseif NetworkGetTalkerProximity() == 25.0 then
                            SendNUIMessage({ type = 'UPDATE_VOICE', mode = 'Shouting' })
                        end
                    end
                end)
            elseif Config.FrameWork == "QB" then
                QBCore.Functions.TriggerCallback('qb-tirex_to_kokx:pma-voice', function(data)
                    if data ~= nil then
                        SendNUIMessage({ type = 'UPDATE_VOICE', mode = data })
                    else
                        if NetworkGetTalkerProximity() == 3.5 then
                            SendNUIMessage({ type = 'UPDATE_VOICE', mode = 'Whisper' })
                        elseif NetworkGetTalkerProximity() == 10.0 then
                            SendNUIMessage({ type = 'UPDATE_VOICE', mode = 'Normal' })
                        elseif NetworkGetTalkerProximity() == 25.0 then
                            SendNUIMessage({ type = 'UPDATE_VOICE', mode = 'Shouting' })
                        end
                    end
                end)
            end

            if currentValues["isInVehicle"] then
                local asd, dsa = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
                currentValues["carFuel"] = exports["LegacyFuel"]:GetFuel(vehicle, false)
                currentValues["location"] = GetStreetNameFromHashKey(asd)
                if Config.SpeedUnits == "Miles" then
                    currentValues["vehicleSpeed"] = (math.floor(GetEntitySpeed(ped)*2.236936))..' MPH'
                elseif Config.SpeedUnits == "Kilometers" then
                    currentValues["vehicleSpeed"] = (math.floor(GetEntitySpeed(ped)*3.6))..' KM/H'
                end
                for k, v in pairs(directions) do
                    if (math.abs(playerHeading - v) < 22.5) then
                        currentValues["direction"] = k
            
                        if (currentValues["direction"] == 1) then
                            currentValues["direction"] = 'N'
                            break
                        end
            
                        break
                    end
                end

                local blip = GetFirstBlipInfoId(8)
                if blip ~= 0 then
                    local Bcoord = GetBlipCoords(blip)
                    local distance = GetDistanceBetweenCoords(playerCoords, Bcoord, false)
                    local algo = distance * 0.00062137
                    currentValues["waypointDistance"] = string.format("%.2f", algo)
                else
                    currentValues["waypointDistance"] = 0
                end
            end

            local units = 'mi'
            if Config.SpeedUnits == "Kilometers" then
                units = 'km'
            end

            SendNUIMessage({
                type = "UPDATE_ALL",
                health = currentValues["health"],
                armor = currentValues["armor"],
                hunger = currentValues["hunger"],
                thirst = currentValues["thirst"],
                drunk = currentValues["drunk"],
                stress = currentValues["stress"],
                oxy = currentValues["oxy"],

                timeH = currentValues["timeH"],
                timeM = currentValues["timeM"],

                inVehicle = currentValues["isInVehicle"],
                gamePaused = currentValues["gamePaused"],
                waypointDistance = currentValues["waypointDistance"],
                waypointDistanceUnuts = units,

                vehicleSpeed = currentValues["vehicleSpeed"],
                carFuel = currentValues["carFuel"],
                location = currentValues["location"],
                direction = currentValues["direction"],

                isTalking = currentValues["isTalking"]
            })
        end
    end
end)

if Config.FrameWork == "ESX" then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
            if currentValues["hudToogle"] then
                TriggerEvent('esx_status:getStatus', 'hunger', function(hungerstatus)
                    TriggerEvent('esx_status:getStatus', 'thirst', function(thirststatus)
                        TriggerEvent('esx_status:getStatus', 'drunk', function(drunkstatus)
                            TriggerEvent('esx_status:getStatus', 'stress', function(stressstatus)
                                currentValues["hunger"] = (hungerstatus.val / 1000000) * 100
                                currentValues["thirst"] = (thirststatus.val / 1000000) * 100
                                currentValues["drunk"] = (drunkstatus.val / 1000000) * 100
                                currentValues["stress"] = (stressstatus.val / 1000000) * 100
                            end)
                        end)
                    end)
                end)
            end
        end
    end)
elseif Config.FrameWork == "QB" then
    RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
        currentValues["hunger"] = newHunger
        currentValues["thirst"] = newThirst
    end)
    
    RegisterNetEvent('hud:client:UpdateStress', function(newStress)
        currentValues["stress"] = newStress
    end)


    CreateThread(function() -- Speeding
        local mnoznik = 2.23694
        if Config.SpeedUnits == 'Kilometers' then
            mnoznik = 3.6
        end
        while true do
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local speed = GetEntitySpeed(GetVehiclePedIsIn(ped, false)) * mnoznik
                    local stressSpeed = Config.MinimumSpeed
                    if speed >= stressSpeed then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                end
            end
            Wait(10000)
        end
    end)
    
    local function IsWhitelistedWeaponStress(weapon)
        if weapon then
            for _, v in pairs(Config.WhitelistedWeaponStress) do
                if weapon == v then
                    return true
                end
            end
        end
        return false
    end
    
    CreateThread(function() -- Shooting
        while true do
            if LocalPlayer.state.isLoggedIn then
                local ped = PlayerPedId()
                local weapon = GetSelectedPedWeapon(ped)
                if weapon ~= `WEAPON_UNARMED` then
                    if IsPedShooting(ped) and not IsWhitelistedWeaponStress(weapon) then
                        if math.random() < Config.StressChance then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                else
                    Wait(1000)
                end
            end
            Wait(8)
        end
    end)

    local function GetBlurIntensity(stresslevel)
        for _, v in pairs(Config.Intensity['blur']) do
            if stresslevel >= v.min and stresslevel <= v.max then
                return v.intensity
            end
        end
        return 1500
    end
    
    local function GetEffectInterval(stresslevel)
        for _, v in pairs(Config.EffectInterval) do
            if stresslevel >= v.min and stresslevel <= v.max then
                return v.timeout
            end
        end
        return 60000
    end
    
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local effectInterval = GetEffectInterval(currentValues["stress"])
            if currentValues["stress"] >= 100 then
                local BlurIntensity = GetBlurIntensity(currentValues["stress"])
                local FallRepeat = math.random(2, 4)
                local RagdollTimeout = FallRepeat * 1750
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
    
                if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                    SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
                end
    
                Wait(1000)
                for _ = 1, FallRepeat, 1 do
                    Wait(750)
                    DoScreenFadeOut(200)
                    Wait(1000)
                    DoScreenFadeIn(200)
                    TriggerScreenblurFadeIn(1000.0)
                    Wait(BlurIntensity)
                    TriggerScreenblurFadeOut(1000.0)
                end
            elseif currentValues["stress"] >= Config.MinimumStress then
                local BlurIntensity = GetBlurIntensity(currentValues["stress"])
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end
            Wait(effectInterval)
        end
    end)
end


RegisterCommand("hud", function()
SendNUIMessage({ type = 'ON_HUD' })
SetNuiFocus(true,true)
end)

RegisterNUICallback("nuioff", function()
SetNuiFocus(false,false)
end)





local voiceToggled = false
local UIHidden = false
local UIRadar = false

--Cricle Radar
Citizen.CreateThread(function()
    RequestStreamedTextureDict("circlemap", false)
    while not HasStreamedTextureDictLoaded("circlemap") do
        Wait(100)
    end

    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")

    SetMinimapClipType(1)
    SetMinimapComponentPosition("minimap", "L", "B", 0.025, -0.03, 0.153, 0.24)
    SetMinimapComponentPosition("minimap_mask", "L", "B", 0.135, 0.12, 0.093, 0.164)
    SetMinimapComponentPosition("minimap_blur", "L", "B", 0.012, 0.022, 0.256, 0.337)

    local minimap = RequestScaleformMovie("minimap")

    SetRadarBigmapEnabled(true, false)
    Citizen.Wait(100)
    SetRadarBigmapEnabled(false, false)

    Citizen.Wait(1000)

    SendNUIMessage(
        {
            type = "Init",
        }
    )

    while true do
        Wait(0)
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
            
        
    end
end)

Citizen.CreateThread(
    function()
        while true do

            Citizen.Wait(500)
            
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped)
            local pauseMenu = IsPauseMenuActive()

           if pauseMenu and not UIHidden then
                 SendNUIMessage(
                        {
                            type = "hideUI"
                        }
                    )
                 UIHidden = true
            elseif UIHidden and not pauseMenu then
                 SendNUIMessage(
                        {
                            type = "showUI"
                        }
                    )
                UIHidden = false
            end

            if not false then
                if vehicle ~= 0 and UIRadar then
                    SendNUIMessage(
                        {
                            type = "openMapUI"
                        }
                    )
                    DisplayRadar(true)
                    UIRadar = false
                elseif not UIRadar and vehicle == 0 then
                    SendNUIMessage(
                        {
                            type = "closeMapUI"
                        }
                    )
                    UIRadar = true
                    DisplayRadar(false)
                end
            else
                DisplayRadar(true)
            end

            
        end
    end
)