return {
    on = {
        devices = { 'Porte' },
        customEvents = { 'Supervision Ouverture' }
    },
    data = {
        -- Délai en seconde avant alarme
        supervisionDelay = { initial = 30 },
        -- 
        compteurDelaiOuverture = { initial = 0 },
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
            domoticz.data.compteurDelaiOuverture = domoticz.data.compteurDelaiOuverture + 1
            local delaiSurveillance = domoticz.data.compteurDelaiOuverture * domoticz.data.supervisionDelay
            domoticz.emitEvent('Supervision Ouverture', device.name ).afterSec(delaiSurveillance)
        end
        
        -- Fin du timeout, on vérifie l'état. Si toujours ouverte, alerte et relance du timeout
        function checkStateAfterTimeout(event, domoticz)
            local item = domoticz.devices(event.data)
            local delaiTotal = ((domoticz.data.compteurDelaiOuverture * (domoticz.data.compteurDelaiOuverture + 1))/2) * domoticz.data.supervisionDelay
            domoticz.log("[" .. domoticz.data.uuid .. "] [" .. event.data .. "] : état courant après " .. delaiTotal .. " s : " .. item.state, domoticz.LOG_DEBUG)
            -- Si toujours Ouvert, on alerte
            if(item.active) then
                notifyAlerteOuverture(item, delaiTotal, domoticz)
                -- et relance de la supervision
                startSurveillance(item, domoticz)
            -- sinon rien - raz du compteur
            else
                domoticz.data.compteurDelaiOuverture = 0
            end
        end

        -- Notification de l'alerte
        function notifyAlerteOuverture(item, delaiTotal, domoticz)
            domoticz.helpers.notify(item.name .. ' est ouvert depuis plus de ' .. delaiTotal .. 's', domoticz.data.uuid, domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "] " .. item.name .. ' est ouvert depuis plus de ' .. delaiTotal .. 's')
        end
        
        domoticz.data.uuid = domoticz.helpers.uuid()
        -- Etat : Open ou Closed d'une porte ou d'une fenêtre
        if(item.isDevice) then
            
            domoticz.log("[" .. domoticz.data.uuid .. "] Changement d'état " .. item.name .. "::".. item.state, domoticz.LOG_DEBUG)
            if(item.active == true) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Ouverture de [" .. item.name .. "]", domoticz.LOG_INFO)
                domoticz.helpers.notify("Ouverture de [" .. item.name .. "]", domoticz.data.uuid, domoticz)
                startSurveillance(item, domoticz)
            else
                domoticz.log("[" .. domoticz.data.uuid .. "] Fermeture de [" .. item.name .. "]", domoticz.LOG_INFO)
                domoticz.data.compteurDelaiOuverture = 0
            end
        -- Déclenchement du timer
        elseif(item.isCustomEvent ) then
            checkStateAfterTimeout(item, domoticz)
        end
    end
}
