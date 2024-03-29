return {
    on = {
        -- Evénement poussé par le nombre de tels connectés ou le scénario Nuit
        customEvents = { 'Presence Domicile', 'Scenario Nuit' },
        -- Evénement poussé le matin au lever du soleil
        timer = { '30 minutes after sunrise' }
    },
    data = {
        previousMode = { initial = '' },
        uuid = { initial = '' }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Lumières] "
    },
    execute = function(domoticz, item)
        
        -- Changement du mode de domicile suivant la Présence
        function updateLightsMode(statutsLampes, domoticz)
            
            if(statutsLampes == false) then
                
                domoticz.log("[" .. domoticz.data.uuid .. "] Extinction de toutes les Lumières", domoticz.LOG_INFO)
                domoticz.devices(domoticz.helpers.GROUPE_LUMIERES_TOUTES).switchOff()
                
            elseif(statutsLampes) then
                
                local prcent_lumiere = domoticz.variables(domoticz.helpers.VAR_PRCENT_LUMIERE_SALON_SOIR).value
                domoticz.log("[" .. domoticz.data.uuid .. "] Allumage de la lampe du salon " .. prcent_lumiere .. "%", domoticz.LOG_INFO)
                domoticz.devices(domoticz.helpers.DEVICE_LAMPE_TV).setLevel(prcent_lumiere)
            end
        end        

        -- Notification depuis ailleurs dans le système (nb de tels connectés)
        if(item.isCustomEvent) then
            domoticz.data.uuid = item.json.uuid
            domoticz.log("[" .. domoticz.data.uuid .. "] Réception de l'événement [" .. item.customEvent .. "] : " .. tostring(item.json.data), domoticz.LOG_DEBUG)
            
            -- Si absence :: Extinction des lampes, idem si scénario nuit ou au lever du soleil +30 mins
            if(item.customEvent == "Presence Domicile") then
                -- si présence : allumage seulement si c'est le soir
                if(item.json.data == false or (item.json.data and domoticz.globalData.scenePhase == 'Soiree')) then
                    updateLightsMode(item.json.data, domoticz)
                end
            elseif(item.customEvent == "Scenario Nuit") then
                updateLightsMode(item.json.data, domoticz)
            end
    
        elseif(item.isTimer) then
            domoticz.data.uuid = domoticz.helpers.uuid()
            domoticz.log("[" .. domoticz.data.uuid .. "] Lever du soleil + 30 mins", domoticz.LOG_INFO)
            updateLightsMode(false, domoticz)
        end
    end
}

