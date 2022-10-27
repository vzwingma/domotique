return {
    on = {
        devices = { 'Présence' },
        -- Evénement poussé par le nombre de tels connectés
        customEvents = { 'Presence Domicile' },
    },
    data = {
        previousMode = { initial = '' },
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,        
        marker = "[Présence domicile] "
    },
    execute = function(domoticz, item)
        
        -- Replay de tous les scénarios jusqu'à la phase en cours, lors du changement de présence
        function replayScene(uuid, domoticz)
            domoticz.log("[" .. uuid .. "] Réactivation du scénario [" .. domoticz.globalData.scenePhase .. "]", domoticz.LOG_DEBUG) 
            domoticz.scenes(domoticz.globalData.scenePhase).switchOn()
        end        
        
        -- Changement du mode de domicile suivant la Présence
        function updatePresenceDomicile(presenceTels, domoticz)
            
            local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
            local presenceDomDevice = domoticz.devices(domoticz.helpers.DEVICE_PRESENCE)
            -- mode domicile = absent
            if(presenceDomicile == '' and presenceTels == false) then
                domoticz.log("[" .. domoticz.data.uuid .. "] 0 présent -> Passage en mode Absent", domoticz.LOG_INFO)
                presenceDomDevice.setLevel('Absents')
            elseif(presenceDomicile == '_abs' and presenceTels) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Au moins un présent -> Retour au mode précédent Présent " .. presenceDomDevice.lastLevel, domoticz.LOG_INFO)
                presenceDomDevice.setLevel(presenceDomDevice.lastLevel)
            end
        end        
        
        -- Notification depuis ailleurs dans le système (nb de tels connectés)
        if(item.isCustomEvent) then
            domoticz.data.uuid = item.json.uuid
            domoticz.log("[" .. domoticz.data.uuid .. "] Réception de l'événement [" .. item.customEvent .. "] : " .. tostring(item.json.data), domoticz.LOG_DEBUG)
            updatePresenceDomicile(item.json.data, domoticz)
            
        elseif(item.isDevice) then
            domoticz.data.uuid = domoticz.helpers.uuid()
            -- Notification lors du changement de présence, si changement
            local presenceDomDevice = domoticz.devices(domoticz.helpers.DEVICE_PRESENCE)
            if(presenceDomDevice ~= domoticz.data.previousMode) then
                domoticz.log('[' .. domoticz.data.uuid .. '][' .. domoticz.globalData.scenePhase .. '] Changement Domicile : ' .. item.levelName, domoticz.LOG_INFO)
                domoticz.helpers.notify('[' .. domoticz.globalData.scenePhase .. '] Changement Domicile : ' .. item.levelName, domoticz.data.uuid, domoticz)
                replayScene(domoticz.data.uuid, domoticz)
            end
            domoticz.data.previousMode = presenceDomDevice
        end
    end
}

--