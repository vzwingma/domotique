-- ## Scripts de commande pour le matin en Semaine et en Week-end (mode normal : présent ou absent)
return
{
    on =
    {
        scenes = { 'Journee' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene Journee] "
    },
    execute = function(domoticz, scene)
        
        -- Activation de la lampe seulement  si présence
        function ouvertureVoletMatin(presenceDomicile)
            -- domoticz.devices(domoticz.helpers.GROUPE_TOUS_VOLETS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. presenceDomicile).value)
            -- Ouverture du groupe Salon & Chambre Nous uniquement, les volets bébé s'ouvrent manuellement
            domoticz.devices(domoticz.helpers.GROUPE_VOLETS_SALON).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. presenceDomicile).value)
            domoticz.devices(domoticz.helpers.DEVICE_VOLET_NOUS).setLevel(domoticz.variables(domoticz.helpers.VAR_PRCENT_VOLET_MATIN .. presenceDomicile).value)

        end        
        
        domoticz.data.uuid = domoticz.helpers.uuid()

        -- Guard : déduction du type de déclenchement (tôt = 8h05 semaine, tardif = 10h00 weekend)
        local isTardif     = (domoticz.time.hour >= 9)
        local isJourFerie  = domoticz.helpers.isJourFerie(domoticz)
        local isWeekEnd    = domoticz.helpers.isWeekEnd(domoticz)

        if isTardif then
            -- Déclenchement tardif : exécuter SEULEMENT si weekend OU jour férié
            if not isWeekEnd and not isJourFerie then
                domoticz.log('[' .. tostring(domoticz.data.uuid) .. '] Déclenchement tardif ignoré (semaine non-fériée)', domoticz.LOG_INFO)
                return
            end
        else
            -- Déclenchement tôt : ignorer si jour férié (le slot tardif prendra le relais)
            if isJourFerie then
                domoticz.log('[' .. tostring(domoticz.data.uuid) .. '] Déclenchement matinal ignoré (jour férié)', domoticz.LOG_INFO)
                return
            end
        end

        -- Activation du groupe (le niveau est suivant la présence Domicile) 
        -- sauf si Eté : dans ce cas, il n'y a que le scénario 2B
        -- sauf si Vacances : dans ce cas, il n'y a que le scénario 2C
        local modeDomicile = domoticz.helpers.getModeDomicile(domoticz)

        if(modeDomicile ~= '') then
            domoticz.log("[" .. domoticz.data.uuid .. "] En mode été ou vacances, le scénario 2 Journee est ignoré", domoticz.LOG_INFO)
            return
        end

        -- Sinon activation suivant présence
        -- Suivi de la phase du jour
        domoticz.emitEvent('Scene Phase', {idx = 2,  data = scene.name, uuid = domoticz.data.uuid })
        
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
        domoticz.log("[" .. domoticz.data.uuid .. "] Activation Journee pour le mode ", domoticz.LOG_INFO)
        ouvertureVoletMatin(presenceDomicile)
        
        local tempMatin = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_MATIN .. presenceDomicile).value

        domoticz.log("[".. domoticz.helpers.uuid() .."] Activation pour la journée. Temp=[" .. tempMatin .. "]")
        -- Thermostat
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempMatin)
        
    end
}