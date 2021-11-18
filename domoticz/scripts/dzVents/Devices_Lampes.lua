return {
    on = {
        -- Evénement poussé par le nombre de tels connectés ou le scénario Nuit
        customEvents = { 'Presence Domicile', 'Scenario Nuit' },
    },
    data = {
        previousMode = { initial = '' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Lampes] "
    },
    execute = function(domoticz, item)
        
        -- Changement du mode de domicile suivant la Présence
        function updateLightsMode(statutsLampes, domoticz)
            
            if(statutsLampes == "false") then
                domoticz.log("Extinction de toutes les lampes", domoticz.LOG_DEBUG)
                domoticz.devices(domoticz.helpers.DEVICE_LAMPE_TV).switchOff()
                domoticz.devices(domoticz.helpers.DEVICE_LAMPE_SALON).switchOff()
                domoticz.devices(domoticz.helpers.DEVICE_LAMPE_CUISINE).switchOff()
            end
        end        
        
        -- Notification depuis ailleurs dans le système (nb de tels connectés)
        if(item.isCustomEvent) then
            domoticz.log("Réception de l'événement [" .. item.customEvent .. "] : " .. item.data, domoticz.LOG_DEBUG)
            
            if(item.customEvent == "Presence Domicile") then
                updateLightsMode(item.data, domoticz)
            elseif(item.customEvent == "Scenario Nuit") then
                updateLightsMode("false", domoticz)
            end
        end
    end
}

--