return {
    helpers = {
        -- #### Variables d'environnements ####
        -- Tydom
        VAR_TYDOM_BRIDGE = 'tydom_bridge_host',
        VAR_TYDOM_BRIDGE_AUTH = 'tydom_bridge_auth',
        -- Freebox
        VAR_FREEBOX_HOST = 'freebox_host',
        VAR_FREEBOX_APP_TOKEN = 'freebox_apptoken',
        -- Connected Devices sur Livebox
        VAR_LIVEBOX_DEVICES = 'livebox_devices',
        
        -- #### Configuration d'usage ####
        -- ces variables sont ensuite suffixées par le mode Domicile
        -- Config Température
        VAR_TEMPERATURE_MATIN = 'param_temp_matin',
        VAR_TEMPERATURE_SOIR = 'param_temp_soir',
        -- Config Volets
        VAR_PRCENT_VOLET_REVEIL = 'param_volet_reveil',
        VAR_PRCENT_VOLET_MATIN = 'param_volet_matin',
        VAR_PRCENT_VOLET_SOIR  = 'param_volet_soir',
        -- Config Lumière Salon
        VAR_PRCENT_LUMIERE_SALON_SOIR = 'param_lampe_salon_soir',
        
        -- #### Configuration des composants ####
        -- # Devices #
        --   Volets
        DEVICE_VOLET_SALON_G = 'Volet Salon G',
        DEVICE_VOLET_SALON_D = 'Volet Salon D',
        DEVICE_VOLET_BEBE = 'Volet Bebe',
        DEVICE_VOLET_NOUS = 'Volet Nous',
        DEVICES_TOUS_VOLETS = { 'Volet Salon D', 'Volet Salon G', 'Volet Bebe', 'Volet Nous' },
        --   Tydom
        DEVICE_TYDOM_TEMPERATURE = 'Tydom Temperature',
        DEVICE_TYDOM_THERMOSTAT = 'Tydom Thermostat',
        --   Lumières
        DEVICE_LAMPE_TV = 'Lumière TV G.',
        DEVICE_LAMPE_TV_2 = 'Prise Lumière TV D.',
        DEVICE_LAMPE_SALON = 'Lumière Salon',
        DEVICE_LAMPE_CUISINE = 'Lumière Cuisine',
        DEVICE_LAMPE_BEBE = 'Lumière Bébé',
        DEVICE_LAMPE_VEILLEUSE_BEBE = 'Prise Veilleuse Bébé',
        DEVICE_LAMPE_NOUS = 'Lumière Nous',
        -- Mode
        DEVICE_PRESENCE = 'Présence',
        DEVICE_MODE_DOMICILE = 'Mode',
        -- Livebox
        DEVICE_STATUT_FREEBOX = 'Freebox',
        DEVICE_STATUT_DOMOTIQUE = 'Domotique',
        DEVICE_STATUT_TV = 'TV',
        DEVICE_STATUT_NAS = 'NAS',
        DEVICE_STATUT_PERSONNAL_DEVICES = 'Equipements Personnels',
        DEVICE_STATUT_PHASE = 'Phase',

        -- # Groupes #
        GROUPE_TOUS_VOLETS = '[Grp] Tous Volets',
        GROUPE_VOLETS_CHAMBRES = '[Grp] Volets Chambres',
        GROUPE_VOLETS_SALON = '[Grp] Volets Salon',
        GROUPE_LUMIERES_SALON = '[Grp] Lumières Salon',
        GROUPE_LUMIERES_TOUTES = '[Grp] Toutes lumières',
        -- ###############################################
        -- #         SOURCE DE VÉRITÉ TYDOM IDs         #
        -- ###############################################
        -- Table centralisée des identifiants Tydom (deviceId / endpointId).
        -- TOUTE référence à un ID Tydom dans les scripts doit passer par cette table.
        -- En cas de remplacement matériel, seule cette table est à modifier.
        --
        -- Structure :
        --   TYDOM_DEVICES.thermostat   → chauffage (Tydom_heat_*)
        --   TYDOM_DEVICES.volets[nom]  → volets (Tydom_volets_*), clé = nom du device Domoticz
        TYDOM_DEVICES = {
            thermostat = {
                deviceId   = 1612171197,
                endpointId = 1612171197,
            },
            volets = {
                ['Volet Salon G'] = { deviceId = 1612171343, endpointId = 1612171343 },
                ['Volet Salon D'] = { deviceId = 1612171455, endpointId = 1612171455 },
                ['Volet Bebe']    = { deviceId = 1612171345, endpointId = 1612171343 },
                ['Volet Nous']    = { deviceId = 1612171344, endpointId = 1612171343 },
            },
        },

        -- ###############################################
        -- #                Tydom DATA                   #
        -- ###############################################
        -- Retourne l'URI REST du thermostat Tydom (chauffage).
        -- Usage : domoticz.helpers.getTydomHeatURI(domoticz)
        getTydomHeatURI = function(domoticz)
            local ids = domoticz.helpers.TYDOM_DEVICES.thermostat
            return '/device/' .. ids.deviceId .. '/endpoints/' .. ids.endpointId
        end,

        -- n° devices Tydom à partir des n° domoticz
        -- Retourne { deviceId, endpointId } ou {} si le nom n'est pas reconnu.
        getTydomDeviceNumberFromDzItem = function(itemName, domoticz)
            local mapping = domoticz.helpers.TYDOM_DEVICES.volets[itemName]
            if mapping ~= nil then
                return { deviceId = mapping.deviceId, endpointId = mapping.endpointId }
            end
            return {}
        end,

        -- n° devices domoticz à partir des n° Tydom
        -- Retourne le nom du device Domoticz, ou nil si non trouvé.
        -- Les IDs reçus en paramètre sont des chaînes (issus des headers HTTP).
        getDzItemFromTydomDeviceId = function(deviceId, endpointId, domoticz)
            for dzName, ids in pairs(domoticz.helpers.TYDOM_DEVICES.volets) do
                if tostring(ids.deviceId) == deviceId and tostring(ids.endpointId) == endpointId then
                    return dzName
                end
            end
            return nil
        end,
        -- ###############################################
        -- ###           Fonctions utilitaires         ###
        -- ###############################################
        -- #### URL de l'API jours fériés (data.gouv.fr) ####
        -- Usage : domoticz.helpers.JOURS_FERIES_API_URL .. annee .. '.json'
        JOURS_FERIES_API_URL = 'https://calendrier.api.gouv.fr/jours-feries/metropole/',

        -- # Fonction si le jour courant est un jour férié
        -- # Vérifie dans domoticz.globalData.joursFeries (chargé par JoursFeries_API.lua).
        -- # Si la liste est vide/nil → émet 'JoursFeries Refresh' et retourne false (conservatif).
        -- # @return boolean : true si jour férié, false sinon
        isJourFerie = function(domoticz)
            local jf = domoticz.globalData.joursFeries
            -- Nil guard + empty guard : si la table est absente ou vide, déclencher le refresh
            if jf == nil or next(jf) == nil then
                domoticz.log('[isJourFerie] Liste des jours fériés vide ou nil — déclenchement du refresh', domoticz.LOG_INFO)
                domoticz.emitEvent('JoursFeries Refresh')
                return false
            end
            -- Construire la clé YYYY-MM-DD du jour courant
            local dateKey = string.format('%04d-%02d-%02d',
                domoticz.time.year,
                domoticz.time.month,
                domoticz.time.day)
            local result = jf[dateKey] == true
            domoticz.log('[isJourFerie] ' .. dateKey .. ' -> ' .. tostring(result), domoticz.LOG_DEBUG)
            return result
        end,

        -- # Fonction si le jour courant est dans le week end
        isWeekEnd = function(domoticz)
            local weekDay = domoticz.time.wday
            domoticz.log("[isWeekEnd] = " .. weekDay, domoticz.LOG_INFO)
            return (weekDay == 1 or weekDay == 7)
        end,
        -- # Fonction de recherche du suffixe suivant la présence au domicile
        -- @param domoticz.helpers.DEVICE_PRESENCE : présence au domicile
        getPresenceDomicile = function(domoticz)
            
            local presenceDomicile = domoticz.devices(domoticz.helpers.DEVICE_PRESENCE).levelName
            domoticz.log("Présence Domicile : [" .. presenceDomicile .. "]", domoticz.LOG_INFO)
            local suffixeMode = ''
            if(presenceDomicile == 'Présents') then
                suffixeMode = ''
            elseif(presenceDomicile == 'Absents') then
                suffixeMode = '_abs'
            end
            return suffixeMode
        end,
        -- # Fonction de recherche du suffixe suivant le mode du Domicile
        -- @param domoticz.helpers.DEVICE_MODE_DOMICILE : mode domicile
        getModeDomicile = function(domoticz)
            local modeDomicile = domoticz.devices(domoticz.helpers.DEVICE_MODE_DOMICILE).levelName
            domoticz.log("Mode Domicile : [" .. modeDomicile .. "]", domoticz.LOG_INFO)
            local suffixeMode = ''
            if(modeDomicile == 'Normal') then
                suffixeMode = ''
            elseif(modeDomicile == 'Vacances') then
                suffixeMode = '_vacs'
            elseif(modeDomicile == 'Summer') then
                suffixeMode = '_ete'
            end
            domoticz.log("  suffixeMode Domicile : [" .. suffixeMode .. "]",  domoticz.LOG_DEBUG)
            return suffixeMode
        end,
        -- # Fonction de recherche du moment de la journée (matin / soir) suivant le scénario activé
        -- @param domoticz.globalData.scenePhase : scène phase
        getMomentJournee = function(domoticz)
            local moment = nil
            if(domoticz.globalData.scenePhase == 'PreparationChauffage' or domoticz.globalData.scenePhase == 'Reveil' or domoticz.globalData.scenePhase == 'Journee' or domoticz.globalData.scenePhase == 'Journee Ete'  or domoticz.globalData.scenePhase == 'Journee Vacs') then
               moment = 'matin'
            elseif(domoticz.globalData.scenePhase == 'Soiree' or domoticz.globalData.scenePhase == 'Nuit' or domoticz.globalData.scenePhase == 'Nuit 2') then
                moment = 'soir'
            else
                moment = nil
            end
            domoticz.log("  moment de la Journee : [" .. tostring(moment) .. "]",  domoticz.LOG_DEBUG)
            return moment
        end,
        -- # Fonction pour identifier le niveau, suivant l'état du device
        -- si On  : c'est le level du device, ou 100 pour un simple switch On/Off
        -- si Off : c'est 0
        getLevelFromState = function(device)
            if(device == nil) then
                return nil
            end
            if(device.state == 'On') then
                 -- Un switch On/Off n'expose pas de "level" : l'état On est assimilé à 100%
                if(device.level == nil) then
                    return 100
                end
                return device.level
            else
                 -- Si état=Off, le niveau est 0
                return 0
            end
        end,
        
        -- # Fonction d'envoi de notification
        -- @param messageToSent : message à envoyer
        -- @param : uuid de traçabilité
        sendNotification = function(messageToSent, protocol, uuid, domoticz)
            domoticz.log("[" .. uuid .. "] Notification " .. protocol .. " : " .. messageToSent, domoticz.LOG_INFO)
            domoticz.notify('Domoticz', messageToSent, domoticz.PRIORITY_NORMAL, domoticz.SOUND_NONE,'', protocol)
        end,
        notifySignal = function(messageToSent, uuid, domoticz)
            domoticz.helpers.sendNotification(messageToSent, domoticz.NSS_HTTP, uuid, domoticz)
        end,
        notifySMS = function(messageToSent, uuid, domoticz)
            domoticz.helpers.sendNotification(messageToSent, domoticz.NSS_CLICKATELL, uuid, domoticz)
        end,
        notify = function(messageToSent, uuid, domoticz)
            domoticz.helpers.notifySignal(messageToSent, uuid, domoticz)
        end,        

        -- # Fonction de recherche d'un node dans un arbre JSON à partir de son nom
        -- @param jsonData : contenu json
        -- @param nodeName : nom du node
        getNodeFromJSonTreeByName = function(jsonData, nodeName)
            for _, node in pairs(jsonData) do
                if(node.name == nodeName) then
                    return node
                end
            end
            return nil
        end,
        -- # Fonction pour vérifier si un item est dans le tableau
        -- @param table : tableau
        -- @param item : item à vérifier
        tabContainsItem = function(table, item, domoticz)
            for i, value in ipairs(table) do
                if value == item then
                    return true
                end
            end
            return false
        end,
        -- # Vérification et réalignement silencieux d'un groupe Domoticz à partir de ses items.
        -- # Si tous les items partagent le même niveau et que le groupe est à un niveau différent,
        -- # le groupe est réaligné silencieusement (.silent()) sans déclencher de nouvel événement.
        -- # Applicable aux volets comme aux lampes (getLevelFromState gère l'état Off).
        -- # @param groupe   : nom du groupe Domoticz (device ou groupe Domoticz)
        -- # @param items    : liste ordonnée des noms d'items (devices ou groupes)
        -- # @param uuid     : uuid de traçabilité
        -- # @param domoticz : contexte domoticz
        verifyGroupeFromItem = function(groupe, items, uuid, domoticz)
            domoticz.log("[" .. uuid .. "] Vérification groupe [" .. groupe .. "]", domoticz.LOG_DEBUG)
            local valeur    = nil
            local sameLevel = true
            local missingItem = false
            for _, itemName in ipairs(items) do
                local okItem, itemDevice = pcall(function()
                    return domoticz.devices(itemName)
                end)
                local itemLevel = domoticz.helpers.getLevelFromState(itemDevice)

                if not okItem or itemDevice == nil or itemLevel == nil then
                    domoticz.log("[" .. uuid .. "] Item introuvable pour réalignement groupe [" .. groupe .. "] : " .. itemName, domoticz.LOG_ERROR)
                    missingItem = true
                else
                    domoticz.log("[" .. uuid .. "]  > " .. itemName .. " : " .. itemLevel .. "%", domoticz.LOG_DEBUG)
                    if valeur == nil then
                        valeur = itemLevel
                    else
                        sameLevel = sameLevel and (valeur == itemLevel)
                    end
                end
            end
            if valeur == nil or missingItem then return end

            local okGroup, groupDevice = pcall(function()
                return domoticz.devices(groupe)
            end)
            local groupeLevel = domoticz.helpers.getLevelFromState(groupDevice)
            if not okGroup or groupDevice == nil or groupeLevel == nil then
                domoticz.log("[" .. uuid .. "] Groupe introuvable pour réalignement : " .. groupe, domoticz.LOG_ERROR)
                return
            end

            if sameLevel and groupeLevel ~= valeur then
                domoticz.log("[" .. uuid .. "] Réalignement groupe [" .. groupe .. "] " .. groupeLevel .. " -> " .. valeur .. "%", domoticz.LOG_INFO)
                groupDevice.setLevel(valeur).silent()
            end
        end,
        -- # Fonction de génération d'UUID
        uuid = function()
            local random = math.random
            local template ='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
            return string.gsub(template, '[xy]', function (c)
                    local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
                    return string.format('%x', v)
                end)
        end,
        -- ###############################################
        -- ###  FONCTIONS HTTP — HELPERS COMMUNS       ###
        -- ###############################################

        -- # Classifie un code HTTP en catégorie lisible.
        -- # Utilisable par les scripts appelants pour enrichir leur journalisation d'erreur.
        -- # @return string : 'OK' | 'TIMEOUT/CONNEXION' | 'ERREUR_CLIENT' | 'ERREUR_SERVEUR' | 'INCONNU'
        httpErrorClass = function(statusCode)
            local code = statusCode or 0
            if code >= 200 and code <= 299     then return 'OK'
            elseif code == 0                   then return 'TIMEOUT/CONNEXION'
            elseif code >= 400 and code <= 499 then return 'ERREUR_CLIENT'
            elseif code >= 500                 then return 'ERREUR_SERVEUR'
            else                               return 'INCONNU'
            end
        end,

        -- ###############################################
        -- ###  FONCTIONS HTTP VERS LE BRIDGE TYDOM    ###
        -- ###############################################        
        
        -- # Fonction d'appel GET de la passerelle Tydom
        -- # IDEMPOTENT — peut être rejoué par l'appelant en cas d'échec transitoire.
        callTydomBridgeGET = function (uriToCall, corrId, callbackName, domoticz)
            domoticz.log("[".. corrId .. "] Appel Tydom GET [" .. uriToCall .. "]", domoticz.LOG_DEBUG)
            local host_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE).value
            local auth_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE_AUTH).value
            if(callbackName == nil) then
               callbackName = 'global_HTTP_response' 
            end
            
            domoticz.openURL({
                url = 'http://'..host_tydom_bridge..'' .. uriToCall,
                method = 'GET',
                headers = { ['Content-Type'] = 'application/json', ['Authorization'] = auth_tydom_bridge,  ['X-CorrId'] = corrId },
                callback = callbackName
            })
            return
        end,
        
        -- # Fonction d'appel POST de la passerelle Tydom
        -- # NON IDEMPOTENT — ne pas rejouer sans précaution (commande d'actionnement).
        callTydomBridgePOST = function (uriToCall, corrId, domoticz)
            domoticz.log("[".. corrId .. "] Appel Tydom POST [" .. uriToCall .. "]", domoticz.LOG_DEBUG)
            
            local host_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE).value
            local auth_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE_AUTH).value
            domoticz.openURL({
                url = 'http://'..host_tydom_bridge..'' .. uriToCall,
                method = 'POST',
                headers = { ['Content-Type'] = 'application/json', ['Authorization'] = auth_tydom_bridge,  ['X-CorrId'] = corrId },
                callback = 'global_HTTP_response'
            })
            return
        end,
        
        -- # Fonction d'appel PUT de la passerelle Tydom
        -- # NON IDEMPOTENT — ne pas rejouer sans précaution (commande de positionnement).
        callTydomBridgePUT = function (uriToCall, putData, corrId, callbackName, domoticz)
            domoticz.log("[".. corrId .. "] Appel Tydom PUT [" .. uriToCall .. "]", domoticz.LOG_DEBUG)
            
            local host_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE).value
            local auth_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE_AUTH).value
            
            if(callbackName == nil) then
               callbackName = 'global_HTTP_response' 
            end

            domoticz.openURL({
                url = 'http://'..host_tydom_bridge..'' .. uriToCall,
                method = 'PUT',
                headers = { ['Content-Type'] = 'application/json', ['Authorization'] = auth_tydom_bridge,  ['X-CorrId'] = corrId},
                postData = putData,
                callback = callbackName
            })
            return
        end,

        -- ###############################################
        -- ###     FONCTIONS HTTP VERS LA FREEBOX      ###
        -- ###############################################
        -- # IDEMPOTENT — peut être rejoué par l'appelant en cas d'échec transitoire.
        callFreeboxGET = function (uriToCall, sessionToken, corrId, callbackName, domoticz)
            
            local host_freebox = domoticz.variables(domoticz.helpers.VAR_FREEBOX_HOST).value
            domoticz.log("[".. corrId .. "] Appel Freebox GET", domoticz.LOG_DEBUG)
            if(callbackName == nil) then
               callbackName = 'global_HTTP_response' 
            end
            domoticz.log("[".. corrId .. "] sessionToken=["..sessionToken.."]", domoticz.LOG_DEBUG)
            domoticz.openURL({
                url = 'http://'..host_freebox..'' .. uriToCall,
                method = 'GET',
                headers = { ['Content-Type'] = 'application/json', ['X-Fbx-App-Auth'] = sessionToken,  ['X-CorrId'] = corrId},
                callback = callbackName
            })      
        end
    },
    data = {
            scenePhase  = { initial = nil },
            -- Table de lookup des jours fériés français : { ['YYYY-MM-DD'] = true, ... }
            -- Alimentée par JoursFeries_API.lua, consultée via domoticz.helpers.isJourFerie(domoticz).
            joursFeries = { initial = {} }
    }
}
