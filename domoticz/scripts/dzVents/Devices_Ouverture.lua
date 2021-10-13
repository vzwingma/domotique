return {
    on = {
        devices = { 'Porte', 'TriggerTest' },
        customEvents =
        {
            'Supervision Ouverture',
        },
    },
    data = {
        -- Délai en seconde avant alarme
        supervisionDelay = { initial = 30 }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Ouverture] "
    },
    -- Fonction chargée de surveiller l'ouverture et la fermeture d'une porte ou d'une fenêtre
    -- Si ouvert trop longtemps : Alerte
    execute = function(domoticz, item)
        
        -- Déclenchement du timeout, la porte doit être fermée avant xx secondes sinon alerte
        function startSurveillance(device, domoticz)
            domoticz.log("Surveillance de l'ouverture de [" .. device.name .. "]")
            domoticz.emitEvent('Supervision Ouverture', device.name ).afterSec(domoticz.data.supervisionDelay)
        end
        
        -- Fin du timeout, on vérifie l'état. Si toujours ouverte, alerte et relance du timeout
        function checkStateAfterTimeout(event, domoticz)
            local item = domoticz.devices(event.data)
            domoticz.log("[" .. event.data .. "] : état courant après " .. domoticz.data.supervisionDelay .. " s : " .. item.state)
            -- Si toujours Ouvert, on alerte
            if(item.state == "Open" or item.state == "On") then
                notifyAlerteOuverture(item, domoticz)
                -- et relance de la supervision
                startSurveillance(item, domoticz)
            -- sinon rien
            end
        end

        -- Notification de l'alerte
        function notifyAlerteOuverture(item, domoticz)
            domoticz.helpers.notify(item.name .. ' est ouvert depuis plus de ' .. domoticz.data.supervisionDelay .. 's', domoticz)
        end
        
        
        -- Etat : Open ou Closed d'une porte ou d'une fenêtre
        if(item.isDevice) then
            domoticz.log("Changement d'état " .. item.name .. "::".. item.state)
            if(item.state == "Open" or item.state == "On") then
                startSurveillance(item, domoticz)
            elseif(item.state == "Closed" or item.state == "Off") then
                domoticz.log("Fermeture de [" .. item.name .. "]")
            end
        -- Déclenchement du timer
        elseif(item.isCustomEvent ) then
            checkStateAfterTimeout(item, domoticz)
        end
    end
}
