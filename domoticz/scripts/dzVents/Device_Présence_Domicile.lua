return {
    on = {
        devices = { 'Présence' },
        -- Evénement poussé par le nombre de tels connectés
        customEvents = { 'Presence Domicile' },
    },
    data = {
        previousMode = { initial = '' }
    },
    logging = {
        level = domoticz.LOG_INFO,        
        marker = "[Présence domicile] "
    },
    execute = function(domoticz, item)
        
        -- Changement du mode de domicile suivant la Présence
        function updatePresenceDomicile(presenceTels, domoticz)
            
            local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
            local presenceDomDevice = domoticz.devices(domoticz.helpers.DEVICE_PRESENCE)
            -- mode domicile = absent
            if(presenceDomicile == '' and presenceTels == "false") then
                domoticz.log("0 présent -> Passage en mode Absent", domoticz.LOG_INFO)
                presenceDomDevice.setLevel('Absents')
            elseif(presenceDomicile == '_abs' and presenceTels == "true") then
                domoticz.log("Au moins un présent -> Retour au mode précédent Présent " .. presenceDomDevice.lastLevel, domoticz.LOG_INFO)
                presenceDomDevice.setLevel(presenceDomDevice.lastLevel)
            end
        end        
        
        -- Notification depuis ailleurs dans le système (nb de tels connectés)
        if(item.isCustomEvent) then
            domoticz.log("Réception de l'événement [" .. item.customEvent .. "] : " .. item.data, domoticz.LOG_DEBUG)
            updatePresenceDomicile(item.data, domoticz)
        elseif(item.isDevice) then        
            -- Notification lors du changement de présence, si changement
            local presenceDomDevice = domoticz.devices(domoticz.helpers.DEVICE_PRESENCE)
            if(presenceDomDevice ~= domoticz.data.previousMode) then
                domoticz.helpers.notify('Changement Domicile : ' .. item.levelName, domoticz.helpers.uuid(), domoticz)
            end
            domoticz.data.previousMode = presenceDomDevice
        end
    end
}

--