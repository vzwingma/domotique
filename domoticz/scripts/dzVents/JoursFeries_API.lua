-- ## Script de chargement des jours fériés français depuis l'API officielle.
-- ## API : https://calendrier.api.gouv.fr/jours-feries/metropole/{annee}.json
-- ## Déclencheurs :
-- ##   - Timer  : 1er janvier 00:05 (chargement annuel)
-- ##   - Timer  : 1er du mois 00:10 (failsafe mensuel, redémarrage ou dérive)
-- ##   - customEvent 'JoursFeries Refresh' (on-demand si liste vide)
-- ## Résultat : domoticz.globalData.joursFeries = { ['YYYY-MM-DD'] = true, ... }
return {
    on = {
        timer = {
            'at 00:05 on 1/1',  -- chargement annuel (1er janvier)
            'at 00:10 on 1',    -- failsafe mensuel  (1er de chaque mois)
        },
        customEvents  = { 'JoursFeries Refresh' },
        httpResponses = { 'jours_feries_response' },
    },
    logging = {
        level  = domoticz.LOG_DEBUG,
        marker = '[JoursFeries] '
    },
    execute = function(domoticz, item)

        -- Appel GET de l'API jours fériés pour l'année courante.
        local function chargerJoursFeries(uuid)
            local annee = tostring(domoticz.time.year)
            local url   = domoticz.helpers.JOURS_FERIES_API_URL .. annee .. '.json'
            domoticz.log('[' .. uuid .. '] Appel API jours fériés : ' .. url, domoticz.LOG_DEBUG)
            domoticz.openURL({
                url      = url,
                method   = 'GET',
                headers  = { ['X-CorrId'] = uuid },
                callback = 'jours_feries_response'
            })
        end

        -- ## Timer ou customEvent → déclencher le chargement
        if item.isTimer or (item.isCustomEvent and item.customEvent == 'JoursFeries Refresh') then
            local uuid = domoticz.helpers.uuid()
            domoticz.log('[' .. uuid .. '] Chargement des jours fériés déclenché ('
                .. (item.isTimer and 'timer' or 'customEvent') .. ')', domoticz.LOG_INFO)
            chargerJoursFeries(uuid)

        -- ## Réponse HTTP de l'API jours fériés
        elseif item.isHTTPResponse and item.callback == 'jours_feries_response' then

            -- Extraction sécurisée du corrId (les headers peuvent être nil en cas d'erreur réseau)
            local corrId = (item.headers and item.headers['X-CorrId']) or 'n/a'

            -- Contrôle du statut HTTP
            if item.statusCode ~= 200 then
                domoticz.log('[' .. corrId .. '] Erreur HTTP ' .. tostring(item.statusCode)
                    .. ' lors du chargement des jours fériés — abandon', domoticz.LOG_ERROR)
                return
            end

            -- Contrôle de la présence du JSON parsé
            if item.json == nil then
                domoticz.log('[' .. corrId .. '] Réponse JSON absente ou non parsable — abandon',
                    domoticz.LOG_ERROR)
                return
            end

            -- Parser : l'API retourne { "2025-01-01": "1er janvier", ... }
            -- On construit la table de lookup { ['2025-01-01'] = true, ... }
            local joursFeries = {}
            local count = 0
            for dateKey, nom in pairs(item.json) do
                joursFeries[dateKey] = true
                count = count + 1
                domoticz.log('[' .. corrId .. '] Jour férié : ' .. tostring(dateKey)
                    .. ' (' .. tostring(nom) .. ')', domoticz.LOG_DEBUG)
            end

            -- Persistance dans globalData (partagé avec isJourFerie dans global_data.lua)
            domoticz.globalData.joursFeries = joursFeries
            domoticz.log('[' .. corrId .. '] ' .. count .. ' jours fériés chargés pour '
                .. tostring(domoticz.time.year), domoticz.LOG_INFO)
        end
    end
}
