return {
    on = {
        timer = { 'at 08:00' },
    },
    logging = {
        level  = domoticz.LOG_INFO,
        marker = '[HEALTH CHECK] ',
        uuid = { initial = "" }
    },
    execute = function(domoticz, item)
        local uuid       = domoticz.helpers.uuid()
        local nbWarnings = 0

        local function warn(msg)
            domoticz.log('[' .. uuid .. '] ' .. msg, domoticz.LOG_ERROR)
            nbWarnings = nbWarnings + 1
        end

        -- -----------------------------------------------
        -- 1. scenePhase exploitable
        -- -----------------------------------------------
        local phase = domoticz.globalData.scenePhase
        if phase == nil or phase == 'Inconnue' then
            -- Distinguer un état transitoire après redémarrage d'une vraie panne :
            -- si le device Phase a été mis à jour dans les 25 dernières heures,
            -- une scène a tourné récemment → l'état 'Inconnue' est probablement
            -- dû à un redémarrage ou à une restauration incomplète (transitoire).
            -- Si le device Phase est aussi périmé, il n'y a plus de doute → ERROR.
            local phaseDeviceStale = true
            pcall(function()
                local d = domoticz.devices(domoticz.helpers.DEVICE_STATUT_PHASE)
                phaseDeviceStale = d.lastUpdate.minutesAgo > (25 * 60)
            end)
            if phaseDeviceStale then
                warn('scenePhase = ' .. tostring(phase) .. ' — phase non initialisée et aucune scène depuis plus de 25h')
            else
                domoticz.log('[' .. uuid .. '] scenePhase = ' .. tostring(phase) .. ' — état transitoire probable après redémarrage (scène récente détectée)', domoticz.LOG_INFO)
            end
        else
            domoticz.log('[' .. uuid .. '] scenePhase = ' .. phase, domoticz.LOG_DEBUG)
        end

        -- -----------------------------------------------
        -- 2. Device Phase : dernière scène < 25h
        -- -----------------------------------------------
        local okPhase, errPhase = pcall(function()
            local d = domoticz.devices(domoticz.helpers.DEVICE_STATUT_PHASE)
            if d.lastUpdate.minutesAgo > (25 * 60) then
                warn('Device Phase — aucune scène depuis ' .. d.lastUpdate.minutesAgo .. ' min (seuil 25h)')
            else
                domoticz.log('[' .. uuid .. '] Device Phase — dernière scène il y a ' .. d.lastUpdate.minutesAgo .. ' min', domoticz.LOG_DEBUG)
            end
        end)
        if not okPhase then
            warn('Device Phase inaccessible : ' .. tostring(errPhase))
        end

        -- -----------------------------------------------
        -- 3. Intégration Freebox (polling ~1 min)
        -- -----------------------------------------------
        local okFreebox, errFreebox = pcall(function()
            local d = domoticz.devices(domoticz.helpers.DEVICE_STATUT_FREEBOX)
            if d.lastUpdate.minutesAgo > 10 then
                warn('Freebox — dernière mise à jour il y a ' .. d.lastUpdate.minutesAgo .. ' min (seuil 10 min)')
            else
                domoticz.log('[' .. uuid .. '] Freebox — OK (' .. d.lastUpdate.minutesAgo .. ' min)', domoticz.LOG_DEBUG)
            end
        end)
        if not okFreebox then
            warn('Device Freebox inaccessible : ' .. tostring(errFreebox))
        end

        -- -----------------------------------------------
        -- 4. Intégration Tydom température (polling ~60 min)
        -- -----------------------------------------------
        local okTydom, errTydom = pcall(function()
            local d = domoticz.devices(domoticz.helpers.DEVICE_TYDOM_TEMPERATURE)
            if d.lastUpdate.minutesAgo > 90 then
                warn('Tydom température — dernière mise à jour il y a ' .. d.lastUpdate.minutesAgo .. ' min (seuil 90 min)')
            else
                domoticz.log('[' .. uuid .. '] Tydom température — OK (' .. d.lastUpdate.minutesAgo .. ' min)', domoticz.LOG_DEBUG)
            end
        end)
        if not okTydom then
            warn('Device Tydom Temperature inaccessible : ' .. tostring(errTydom))
        end

        -- -----------------------------------------------
        -- 5. Jours fériés : liste présente et non-vide
        -- -----------------------------------------------
        local jf = domoticz.globalData.joursFeries
        if jf == nil or next(jf) == nil then
            warn('Jours fériés : liste absente ou vide — émission JoursFeries Refresh')
            domoticz.emitEvent('JoursFeries Refresh')
        else
            local nbJf = 0
            for _ in pairs(jf) do nbJf = nbJf + 1 end
            domoticz.log('[' .. uuid .. '] Jours fériés — OK (' .. nbJf .. ' entrée(s))', domoticz.LOG_DEBUG)
        end

        -- -----------------------------------------------
        -- Résumé
        -- -----------------------------------------------
        if nbWarnings == 0 then
            domoticz.log('[' .. uuid .. '] Santé dzVents OK — tous les indicateurs sont nominaux.', domoticz.LOG_INFO)
        else
            local msg = 'Health check dzVents : ' .. nbWarnings .. ' indicateur(s) dégradé(s) — consulter les logs.'
            domoticz.log('[' .. uuid .. '] ' .. msg, domoticz.LOG_ERROR)
            domoticz.helpers.notify(msg, uuid, domoticz)
        end
    end
}
