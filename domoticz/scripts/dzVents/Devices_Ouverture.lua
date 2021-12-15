return {
    on = {
        devices = { 'Porte' },
        customEvents = { 'Supervision Ouverture' }
    },
    data = {
        -- Délai en seconde avant alarme
        supervisionDelay = { initial = 30 }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Ouverture] "
    },
    -- Fonction chargée de surveiller l'ouverture et la fermeture d'une porte ou d'une fenêtre
    -- Si ouvert trop longtemps : Alerte
    execute = function(domoticz, item)
        
        -- Déclenchement du timeout, la porte doit être fermée avant xx secondes sinon alerte
        function startSurveillance(device, domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "] Ouverture de [" .. device.name .. "]", domoticz.LOG_INFO)
            domoticz.emitEvent('Supervision Ouverture', device.name ).afterSec(domoticz.data.supervisionDelay)
        end
        
        -- Fin du timeout, on vérifie l'état. Si toujours ouverte, alerte et relance du timeout
        function checkStateAfterTimeout(event, domoticz)
            local item = domoticz.devices(event.data)
            domoticz.log("[" .. domoticz.data.uuid .. "] [" .. event.data .. "] : état courant après " .. domoticz.data.supervisionDelay .. " s : " .. item.state, domoticz.LOG_DEBUG)
            -- Si toujours Ouvert, on alerte
            if(item.active == true) then
                notifyAlerteOuverture(item, domoticz)
                -- et relance de la supervision
                startSurveillance(item, domoticz)
            -- sinon rien
            end
        end

        -- Notification de l'alerte
        function notifyAlerteOuverture(item, domoticz)
            domoticz.helpers.notify(item.name .. ' est ouvert depuis plus de ' .. domoticz.data.supervisionDelay .. 's', domoticz.data.uuid, domoticz)
        end
        
        domoticz.data.uuid = domoticz.helpers.uuid()
        -- Etat : Open ou Closed d'une porte ou d'une fenêtre
        if(item.isDevice) then
            domoticz.log("[" .. domoticz.data.uuid .. "] Changement d'état " .. item.name .. "::".. item.state, domoticz.LOG_DEBUG)
            if(item.active == true) then
                startSurveillance(item, domoticz)
            else
                domoticz.log("[" .. domoticz.data.uuid .. "] Fermeture de [" .. item.name .. "]", domoticz.LOG_INFO)
            end
        -- Déclenchement du timer
        elseif(item.isCustomEvent ) then
            checkStateAfterTimeout(item, domoticz)
        end
    end
}
