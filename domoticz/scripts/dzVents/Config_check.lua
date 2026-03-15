commandArray = {}

-- ###############################################
-- #           CONFIG CHECK — DEV-4              #
-- ###############################################
-- Contrôle de prérequis Domoticz au démarrage.
--
-- Ce script vérifie, une seule fois au boot, que tous les devices, groupes,
-- scènes Domoticz et variables utilisateur critiques sont bien présents.
-- En cas de prérequis manquant, un message LOG_ERROR est émis pour chaque
-- élément absent, suivi d'un résumé global.
--
-- Comportement :
--   - Aucun flux existant n'est bloqué ou interrompu par ce script.
--   - Les erreurs sont purement informatives : elles signalent un problème de
--     configuration sans provoquer d'effet de bord.
--   - Les identifiants Tydom ne sont pas vérifiés ici (leur source de vérité
--     est TYDOM_DEVICES dans global_data.lua ; leur cohérence est garantie
--     par construction dès lors que global_data.lua est chargé).
--
-- Mise à jour :
--   - Si un nouveau device, groupe, scène ou variable est ajouté au système,
--     l'ajouter dans la liste correspondante ci-dessous.
-- ###############################################

return {
    on = {
        system = { 'start' },
    },
    logging = {
        level    = 3, -- domoticz.LOG_INFO (constante numérique : domoticz n'est pas disponible au chargement)
        marker   = '[CONFIG CHECK] ',
    },
    execute = function(domoticz, item)

        local nbErrors = 0

        -- -----------------------------------------------
        -- Fonction interne : vérifie l'existence d'un
        -- objet Domoticz via pcall pour ne pas planter
        -- si l'objet est absent.
        -- -----------------------------------------------
        local function checkExists(getter, name, category)
            local ok, obj = pcall(getter)
            if not ok or obj == nil then
                domoticz.log(
                    'PREREQUIS MANQUANT [' .. category .. '] : ' .. name,
                    domoticz.LOG_ERROR
                )
                nbErrors = nbErrors + 1
                return false
            end
            return true
        end

        -- -----------------------------------------------
        -- 1. Devices Domoticz critiques
        -- -----------------------------------------------
        local requiredDevices = {
            -- Volets
            domoticz.helpers.DEVICE_VOLET_SALON_G,
            domoticz.helpers.DEVICE_VOLET_SALON_D,
            domoticz.helpers.DEVICE_VOLET_BEBE,
            domoticz.helpers.DEVICE_VOLET_NOUS,
            -- Tydom / Chauffage
            domoticz.helpers.DEVICE_TYDOM_TEMPERATURE,
            domoticz.helpers.DEVICE_TYDOM_THERMOSTAT,
            -- Lumières
            domoticz.helpers.DEVICE_LAMPE_TV,
            domoticz.helpers.DEVICE_LAMPE_TV_2,
            domoticz.helpers.DEVICE_LAMPE_SALON,
            domoticz.helpers.DEVICE_LAMPE_CUISINE,
            domoticz.helpers.DEVICE_LAMPE_BEBE,
            domoticz.helpers.DEVICE_LAMPE_VEILLEUSE_BEBE,
            domoticz.helpers.DEVICE_LAMPE_NOUS,
            -- Présence / Mode
            domoticz.helpers.DEVICE_PRESENCE,
            domoticz.helpers.DEVICE_MODE_DOMICILE,
            -- Supervision
            domoticz.helpers.DEVICE_STATUT_FREEBOX,
            domoticz.helpers.DEVICE_STATUT_DOMOTIQUE,
            domoticz.helpers.DEVICE_STATUT_TV,
            domoticz.helpers.DEVICE_STATUT_NAS,
            domoticz.helpers.DEVICE_STATUT_PERSONNAL_DEVICES,
            domoticz.helpers.DEVICE_STATUT_PHASE,
        }

        domoticz.log('--- Vérification des devices ---', domoticz.LOG_DEBUG)
        for _, name in ipairs(requiredDevices) do
            checkExists(function() return domoticz.devices(name) end, name, 'Device')
        end

        -- -----------------------------------------------
        -- 2. Groupes Domoticz critiques
        -- -----------------------------------------------
        local requiredGroups = {
            domoticz.helpers.GROUPE_TOUS_VOLETS,
            domoticz.helpers.GROUPE_VOLETS_CHAMBRES,
            domoticz.helpers.GROUPE_VOLETS_SALON,
            domoticz.helpers.GROUPE_LUMIERES_SALON,
            domoticz.helpers.GROUPE_LUMIERES_TOUTES,
        }

        domoticz.log('--- Vérification des groupes ---', domoticz.LOG_DEBUG)
        for _, name in ipairs(requiredGroups) do
            checkExists(function() return domoticz.groups(name) end, name, 'Groupe')
        end

        -- -----------------------------------------------
        -- 3. Scènes Domoticz critiques
        --    (noms exacts attendus dans Domoticz, tels que
        --     référencés dans les scripts Scene_*)
        -- -----------------------------------------------
        local requiredScenes = {
            'PreparationChauffage',
            'Reveil',
            'Journee',
            'Journee Ete',
            'Journee Vacs',
            'Soiree',
            'Nuit',
            'Nuit 2',
        }

        domoticz.log('--- Vérification des scènes ---', domoticz.LOG_DEBUG)
        for _, name in ipairs(requiredScenes) do
            checkExists(function() return domoticz.scenes(name) end, name, 'Scene')
        end

        -- -----------------------------------------------
        -- 4. Variables utilisateur critiques
        -- -----------------------------------------------
        local requiredVariables = {
            -- Connexion Tydom
            domoticz.helpers.VAR_TYDOM_BRIDGE,
            domoticz.helpers.VAR_TYDOM_BRIDGE_AUTH,
            -- Connexion Freebox
            domoticz.helpers.VAR_FREEBOX_HOST,
            domoticz.helpers.VAR_FREEBOX_APP_TOKEN,
            domoticz.helpers.VAR_LIVEBOX_DEVICES,
            -- Paramètres métier (mode Normal)
            domoticz.helpers.VAR_TEMPERATURE_MATIN,
            domoticz.helpers.VAR_TEMPERATURE_SOIR,
            domoticz.helpers.VAR_PRCENT_VOLET_REVEIL,
            domoticz.helpers.VAR_PRCENT_VOLET_MATIN,
            domoticz.helpers.VAR_PRCENT_VOLET_SOIR,
            domoticz.helpers.VAR_PRCENT_LUMIERE_SALON_SOIR,
        }

        domoticz.log('--- Vérification des variables ---', domoticz.LOG_DEBUG)
        for _, name in ipairs(requiredVariables) do
            checkExists(function() return domoticz.variables(name) end, name, 'Variable')
        end

        -- -----------------------------------------------
        -- 5. Résumé
        -- -----------------------------------------------
        if nbErrors == 0 then
            domoticz.log(
                'Contrôle de configuration OK — tous les prérequis sont présents.',
                domoticz.LOG_INFO
            )
        else
            domoticz.log(
                'Contrôle de configuration INCOMPLET — ' .. nbErrors ..
                ' prérequis manquant(s). Consulter les logs ERROR ci-dessus.',
                domoticz.LOG_ERROR
            )
        end
    end,
}
