return
{
    on =
    {
        scenes = { 'PreparationChauffage' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Scene PreReveil] "
    },
    execute = function(domoticz, scene)
        -- Suivi de la phase du jour
        domoticz.data.uuid = domoticz.helpers.uuid()

        -- Guard : déduction du type de déclenchement (tôt = 7h semaine, tardif = 8h+ weekend)
        local isTardif     = (domoticz.time.hour >= 8)
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

        domoticz.emitEvent('Scene Phase', { idx = 0, data = scene.name, uuid = domoticz.data.uuid })

        -- Recherche de la température à appliquer suivant la présence
        local presenceDomicile = domoticz.helpers.getPresenceDomicile(domoticz)
        local tempMatin = domoticz.variables(domoticz.helpers.VAR_TEMPERATURE_MATIN .. presenceDomicile).value

        domoticz.log("[".. domoticz.helpers.uuid() .."] Activation pour le matin. Temp=[" .. tempMatin .. "]")
        -- Thermostat
        domoticz.devices(domoticz.helpers.DEVICE_TYDOM_THERMOSTAT).updateSetPoint(tempMatin)
    end       
}