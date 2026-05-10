-- ## Script de chargement des jours fériés français depuis l'API officielle.
-- ## API : https://calendrier.api.gouv.fr/jours-feries/metropole/{annee}.json
-- ## Déclencheurs :
-- ##   - Timer  : quotidien à 00:05 — n'agit que le 1er du mois (filtre dans execute)
-- ##   - customEvent 'JoursFeries Refresh' (on-demand si liste vide)
-- ## Résultat : domoticz.globalData.joursFeries = { ['YYYY-MM-DD'] = true, ... }
return {
    on = {
        -- Timer quotidien simple : la syntaxe 'at HH:MM on N' (jour du mois) n'est pas
        -- portable en dzVents. On filtre dans execute() sur domoticz.time.day == 1.
        timer         = { 'at 00:05' },
        customEvents  = { 'JoursFeries Refresh' },
        httpResponses = { 'jours_feries_response' },
    },
    logging = {
        -- Constante numérique : domoticz.LOG_* peut être nil lors de l'évaluation du module
        -- (cf. Config_check.lua, même convention).
        level  = domoticz.LOG_INFO,
        marker = '[JoursFeries] ',
        uuid = { initial = "" }
    },
    execute = function(domoticz, item)

        -- Appel GET de l'API jours fériés pour l'année courante.
        local function chargerJoursFeries(uuid)
            local annee = tostring(domoticz.time.year)
            local url   = domoticz.helpers.JOURS_FERIES_API_URL .. annee .. '.json'
            domoticz.log('[' .. uuid .. '] Appel API jours fériés : ' .. url, domoticz.LOG_INFO)
            domoticz.openURL({
                url      = url,
                method   = 'GET',
                headers  = { ['X-CorrId'] = uuid },
                callback = 'jours_feries_response'
            })
        end

        -- ## Timer quotidien → agir uniquement le 1er du mois
        -- ## customEvent 'JoursFeries Refresh' → toujours agir (on-demand)
        if (item.isTimer and domoticz.time.day ~= 1) or (item.isCustomEvent and item.customEvent == 'JoursFeries Refresh') then
            local uuid = domoticz.helpers.uuid()
            domoticz.log('[' .. uuid .. '] Chargement des jours fériés déclenché ('
                .. (item.isTimer and 'timer 1er du mois' or 'customEvent') .. ')', domoticz.LOG_INFO)
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
