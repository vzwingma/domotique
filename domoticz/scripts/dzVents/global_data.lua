return {
    helpers = {
        -- #### Variables d'environnements ####
        -- Tydom
        VAR_TYDOM_BRIDGE = 'tydom_bridge_host',
        VAR_TYDOM_BRIDGE_AUTH = 'tydom_bridge_auth',
        -- Livebox
        VAR_LIVEBOX_HOST = 'livebox_host',
        VAR_LIVEBOX_LOGIN = 'livebox_login',
        VAR_LIVEBOX_PWD = 'livebox_pwd',
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
        DEVICE_TYDOM_TEMPERATURE='Tydom Temperature',
        DEVICE_TYDOM_THERMOSTAT='Tydom Thermostat',
        --   Lumières
        DEVICE_LAMPE_TV='Lumière TV',
        DEVICE_LAMPE_SALON='Lumière Salon',
        DEVICE_LAMPE_CUISINE='Lumière Cuisine',
        -- Mode
        DEVICE_PRESENCE = 'Présence',
        DEVICE_MODE_DOMICILE = 'Mode',
        -- Livebox
        DEVICE_STATUT_LIVEBOX = 'Livebox',
        DEVICE_STATUT_DOMOTIQUE = 'Domotique',
        DEVICE_STATUT_TV = 'TV',
        DEVICE_STATUT_PERSONNAL_DEVICES = 'Equipements Personnels',

        -- # Groupes #
        GROUPE_TOUS_VOLETS = '[Grp] Tous Volets',
        GROUPE_VOLETS_CHAMBRES = '[Grp] Volets Chambres',
        GROUPE_VOLETS_SALON = '[Grp] Volets Salon',
        GROUPE_LUMIERES_SALON = '[Grp] Lumières Salon',
        
        -- ###############################################
        -- #                Tydom DATA                   #
        -- ###############################################
        -- n° devices Tydom
        getTydomDeviceNumberFromDzItem = function(itemName, domoticz)
            local tydomIds = {}   

            if(itemName == domoticz.helpers.DEVICE_VOLET_SALON_G) then
                tydomIds.deviceId=1612171343
                tydomIds.endpointId=1612171343
            elseif(itemName == domoticz.helpers.DEVICE_VOLET_SALON_D) then
                tydomIds.deviceId=1612171455
                tydomIds.endpointId=1612171455
            elseif(itemName == domoticz.helpers.DEVICE_VOLET_BEBE) then
                tydomIds.deviceId=1612171345
                tydomIds.endpointId=1612171343
            elseif(itemName == domoticz.helpers.DEVICE_VOLET_NOUS) then
                tydomIds.deviceId=1612171344
                tydomIds.endpointId=1612171343
            end
            return tydomIds
        end,
        getDzItemFromTydomDeviceId = function(deviceId, endpointId, domoticz)
            local dzItemId = nil
            if(deviceId == '1612171343' and endpointId == '1612171343') then
                dzItemId = domoticz.helpers.DEVICE_VOLET_SALON_G
            elseif(deviceId == '1612171455' and endpointId == '1612171455') then
                dzItemId = domoticz.helpers.DEVICE_VOLET_SALON_D
            elseif(deviceId == '1612171345' and endpointId == '1612171343') then
                dzItemId = domoticz.helpers.DEVICE_VOLET_BEBE
            elseif(deviceId == '1612171344' and endpointId == '1612171343') then
                dzItemId = domoticz.helpers.DEVICE_VOLET_NOUS
            end
            return dzItemId
        end,        
        -- ###############################################
        -- ###           Fonctions utilitaires         ###
        -- ###############################################
        isWeekEnd = function(domoticz)
            local weekDay = domoticz.time.wday
            domoticz.log("weekDay = " .. weekDay, domoticz.LOG_INFO)
            return (weekDay == 1 or weekDay == 7)
        end,
        -- # Fonction de recherche du suffixe suivant la présence au domicile
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
        getModeDomicile = function(domoticz)
            local modeDomicile = domoticz.devices(domoticz.helpers.DEVICE_MODE_DOMICILE).levelName
            domoticz.log("Mode Domicile : [" .. modeDomicile .. "]", domoticz.LOG_INFO)
            if(modeDomicile == 'Normal') then
                suffixeMode = ''
            elseif(modeDomicile == 'Vacances') then
                suffixeMode = '_vacs'
            elseif(modeDomicile == 'Eté') then
                suffixeMode = '_ete'
            end
            domoticz.log("  suffixeMode Domicile : [" .. suffixeMode .. "]",  domoticz.LOG_DEBUG)
            return suffixeMode
        end,
        -- # Fonction d'envoi de notification
        notify = function(messageToSent, uuid, domoticz)
            domoticz.log("[" .. uuid .. "] Notification : " .. messageToSent, domoticz.LOG_INFO)
            domoticz.notify('Domoticz', messageToSent, domoticz.PRIORITY_NORMAL, domoticz.SOUND_NONE,'', domoticz.NSS_HTTP)
        end,
        -- # Fonction de recherche d'un node dans un arbre JSON à partir de son nom
        getNodeFromJSonTreeByName = function(jsonData, nodeName)
            for _, node in pairs(jsonData) do
                if(node.name == nodeName) then
                    return node
                end
            end
            return nil
        end,
        -- # Fonction pour vérifier si un item est dans le tableau
        tabContainsItem = function(table, item, domoticz)
            for _, value in pairs(table) do
                if value == item then
                    return true
                end
            end
            return false
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
        -- ###  FONCTIONS HTTP VERS LE BRIDGE TYDOM    ###
        -- ###############################################        
        
        -- # Fonction d'appel GET de la passerelle Tydom
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
        -- ###     FONCTIONS HTTP VERS LA LIVEBOX      ###
        -- ###############################################
        -- Authentification
        authenticateToLivebox = function(uuid, callbackName, domoticz)
    
            domoticz.log("[" .. uuid .. "] Authentification à la Livebox ORANGE", domoticz.LOG_DEBUG) 
    
            local host_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_HOST).value
            local login_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_LOGIN).value
            local pwd_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_PWD).value
            local authData = { ['service'] = 'sah.Device.Information', 
                               ['method'] = 'createContext',
                               ['parameters'] = { ['applicationName'] = 'so_sdkut', 
                                                  ['username'] = login_livebox, 
                                                  ['password'] = pwd_livebox }}
            -- Appel de l'authentification
            local fullcmd = "curl -s -H \"Content-Type: application/x-sah-ws-4-call+json\" -H \"X-CorrId:".. uuid .."\" -H \"Authorization:X-Sah-Login\" -d '" 
                            .. domoticz.utils.toJSON(authData) .. "' -c /opt/domoticz/userdata/scripts/dzVents/data/liveboxCookieAuth.cookie -X POST " ..
                            "'http://" .. host_livebox .. "/ws'"

        	domoticz.executeShellCommand({ 
        	            command = fullcmd, 
        	            callback = callbackName })
        end,  
        -- Appel POST
        callLiveboxPOST = function (contextId, postData, corrId, callbackName, domoticz)
            
            local host_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_HOST).value
            domoticz.log("[".. corrId .. "] Appel Livebox POST", domoticz.LOG_DEBUG)
            if(callbackName == nil) then
               callbackName = 'global_HTTP_response' 
            end
            domoticz.log("[".. corrId .. "] contextId=["..contextId.."]", domoticz.LOG_DEBUG)
            local fullcmd = "SESSID=`cat /opt/domoticz/userdata/scripts/dzVents/data/liveboxCookieAuth.cookie  | awk 'END{print}' | awk '{new_var=$(NF-1)\"=\"$(NF); print new_var}'` ; " ..
            "curl -s -H \"Content-Type: application/x-sah-ws-4-call+json\"  -H \"X-CorrId: " .. corrId ..  "\"  -H \"X-Context: " .. contextId ..  "\" -d '" .. domoticz.utils.toJSON(postData) .. "' -b \"$SESSID\" -X POST 'http://" .. host_livebox .. "/ws'"

        	domoticz.executeShellCommand({ 
        	        command = fullcmd, 
        	        callback = callbackName })            
        end
    },
    data = {
            scenePhase = { initial = nil }
    }
}