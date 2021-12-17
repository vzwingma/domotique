return {
    on = {
        -- Evénement poussé par le nombre de tels connectés ou le scénario Nuit
        customEvents = { 'Presence Domicile', 'Scenario Nuit' },
        -- Evénement poussé le matin au lever du soleil
        timer = { '30 minutes after sunrise' }
    },
    data = {
        previousMode = { initial = '' }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Lumières] "
    },
    execute = function(domoticz, item)
        
        -- Changement du mode de domicile suivant la Présence
        function updateLightsMode(statutsLampes, domoticz)
            
            if(statutsLampes == "false") then
                domoticz.log("Extinction de toutes les Lumières", domoticz.LOG_INFO)
                domoticz.devices(domoticz.helpers.GROUPE_LUMIERES_SALON).switchOff()
            end
        end        
        
        -- Notification depuis ailleurs dans le système (nb de tels connectés)
        if(item.isCustomEvent) then
            domoticz.log("Réception de l'événement [" .. item.customEvent .. "] : " .. item.data, domoticz.LOG_INFO)
            
            if(item.customEvent == "Presence Domicile") then
                updateLightsMode(item.data, domoticz)
            elseif(item.customEvent == "Scenario Nuit") then
                updateLightsMode("false", domoticz)
            end
        elseif(item.isTimer) then
            domoticz.log("Lever du soleil + 30 mins", domoticz.LOG_INFO)
            updateLightsMode("false", domoticz)
        end
    end
}

--