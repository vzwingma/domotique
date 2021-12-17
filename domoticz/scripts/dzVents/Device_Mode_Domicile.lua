return {
    on = {
        devices = { 'Mode Domicile' },
        -- Evénement poussé par le nombre de tels connectés
        customEvents = { 'Presence Domicile' },
    },
    data = {
        previousMode = { initial = '' }
    },
    logging = {
        level = domoticz.LOG_INFO,        
        marker = "[Mode domicile] "
    },
    execute = function(domoticz, item)
        
        -- Changement du mode de domicile suivant la Présence
        function updateDomicileMode(presenceTels, domoticz)
            
            local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
            local modeDomDevice = domoticz.devices(domoticz.helpers.DEVICE_MODE_DOMICILE)
            -- mode domicile = absent
            if((modeDomicile == '' or modeDomicile == '_ete' ) and presenceTels == "false") then
                domoticz.log("0 présent -> Passage en mode Absent", domoticz.LOG_INFO)
                modeDomDevice.setLevel('Absents')
            elseif(modeDomicile == '_abs' and presenceTels == "true") then
                domoticz.log("Au moins un présent -> Retour au mode précédent (Présent/Eté) " .. modeDomDevice.lastLevel, domoticz.LOG_INFO)
                modeDomDevice.setLevel(modeDomDevice.lastLevel)
            end
        end        
        
        -- Notification depuis ailleurs dans le système (nb de tels connectés)
        if(item.isCustomEvent) then
            domoticz.log("Réception de l'événement [" .. item.customEvent .. "] : " .. item.data, domoticz.LOG_DEBUG)
            updateDomicileMode(item.data, domoticz)
        elseif(item.isDevice) then        
            -- Notification par SMS lors du changement de mode, si changement
            local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)
            if(modeDomicile ~= domoticz.data.previousMode) then
                domoticz.helpers.notify('Changement du mode Domicile : ' .. item.levelName, domoticz.helpers.uuid(), domoticz)
            end
            domoticz.data.previousMode = modeDomicile
        end
    end
}

--