return
{
    on =
    {
        -- Evénement poussé par le changement de phase de scénario
        customEvents = { 'Scene Phase' },
        -- Restauration de scenePhase au démarrage de Domoticz
        system = { 'start' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Scénario] "
    },
    execute = function(domoticz, item)

        -- Cas boot : restauration de scenePhase depuis le device Phase
        if item.isSystemEvent and item.trigger == 'start' then
            local phaseDevice = domoticz.devices(domoticz.helpers.DEVICE_STATUT_PHASE)
            local restoredPhase = nil
            if phaseDevice ~= nil then
                restoredPhase = phaseDevice.text
            end
            -- Phases reconnues valides (cohérentes avec getMomentJournee)
            local validPhases = {
                ['PreparationChauffage'] = true, ['Reveil'] = true,
                ['Journee'] = true, ['Journee Ete'] = true, ['Journee Vacs'] = true,
                ['Soiree'] = true, ['Nuit'] = true, ['Nuit 2'] = true
            }
            if restoredPhase ~= nil and restoredPhase ~= '' and validPhases[restoredPhase] then
                domoticz.globalData.scenePhase = restoredPhase
                domoticz.log('[boot] scenePhase restaurée depuis Phase : [' .. restoredPhase .. ']', domoticz.LOG_INFO)
            else
                -- Fallback explicite : phase inconnue, getMomentJournee retournera nil
                domoticz.globalData.scenePhase = 'Inconnue'
                domoticz.log('[boot] scenePhase initialisée au fallback Inconnue (Phase=' .. tostring(restoredPhase) .. ')', domoticz.LOG_INFO)
            end
            return
        end

        -- Cas nominal : mise à jour de la phase depuis l'événement Scene Phase
        domoticz.data.uuid = item.json.uuid
        domoticz.log("[" .. domoticz.data.uuid .. "] Réception de l'événement [" .. item.customEvent .. "] : [" .. tostring(item.json.idx) .. "/" .. tostring(item.json.data) .. "]", domoticz.LOG_DEBUG)
        domoticz.globalData.scenePhase = item.json.data
        domoticz.devices(domoticz.helpers.DEVICE_STATUT_PHASE).updateText(item.json.data)

    end
}
