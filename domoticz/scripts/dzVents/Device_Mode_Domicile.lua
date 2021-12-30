return {
    on = {
        devices = { 'Mode' },
    },
    data = {
        previousMode = { initial = '' },
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Mode Domicile] "
    },
    execute = function(domoticz, device)

        -- Replay de tous les scénarios jusqu'à la phase en cours, mais en mode "Normal"
        function replaySceneInNormal(domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "] Réactivation du scénario [" .. domoticz.globalData.scenePhase .. "]", domoticz.LOG_DEBUG) 
            domoticz.scenes(domoticz.globalData.scenePhase).switchOn()
            -- Thermostat
            local tempMatin = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_MATIN).value
            domoticz.log("[" .. domoticz.data.uuid .. "] Activation pour la journée Temp=[" .. tempMatin .. "°]")
            domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempMatin)
        end


        domoticz.data.uuid = domoticz.helpers.uuid()
        local modeDomicile = device.levelName
        
        -- Notification lors du changement de mode, si changement
        if(modeDomicile ~= domoticz.data.previousMode) then
            domoticz.helpers.notify('Changement Mode : ' .. device.levelName, domoticz.helpers.uuid(), domoticz)
            -- Activation si passage en mode "Normal" , dans ce cas, on rejoue le scénario de la journée
            if(modeDomicile == 'Normal') then
               replaySceneInNormal(domoticz)
            end
            
        end
    end
}