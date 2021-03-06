return {
    helpers = {
        -- Variables d'environnements
        -- Tydom
        VAR_TYDOM_BRIDGE = 'host_tydom_bridge',
        -- Livebox
        VAR_LIVEBOX_HOST = 'livebox_host',
        VAR_LIVEBOX_LOGIN = 'livebox_login',
        VAR_LIVEBOX_PWD = 'livebox_pwd',
        -- Connected Devices sur Livebox
        VAR_LIVEBOX_DEVICES = 'livebox_devices',
        -- #### Configuration d'usage ####
        -- Config Température
        VAR_TEMPERATURE_MATIN = 'param_temp_matin',
        VAR_TEMPERATURE_SOIR = 'param_temp_soir',
        -- Config Volets
        VAR_PRCENT_VOLET_REVEIL = 'param_volet_reveil',
        VAR_PRCENT_VOLET_MATIN = 'param_volet_matin',
        VAR_PRCENT_VOLET_SOIR  = 'param_volet_soir',
        -- Si Mode Domicile == Absent ou Vacances
        VAR_TEMPERATURE_MATIN_ABS = 'param_temp_matin_abs',
        VAR_TEMPERATURE_SOIR_ABS = 'param_temp_soir_abs',
        VAR_PRCENT_VOLET_REVEIL_ABS = 'param_volet_reveil',
        -- Config Lumière Salon
        VAR_PRCENT_LUMIERE_SALON_SOIR = 'param_lampe_salon_soir',
        
        -- # Configuration des composants #
        -- Devices
        DEVICE_VOLET_SALON_G = 'Volet Salon G',
        DEVICE_VOLET_SALON_D = 'Volet Salon D',
        DEVICE_VOLET_BEBE = 'Volet Bebe',
        DEVICE_VOLET_NOUS = 'Volet Nous',
        DEVICE_TYDOM_TEMPERATURE='Tydom Temperature',
        DEVICE_TYDOM_THERMOSTAT='Tydom Thermostat',
        DEVICE_LAMPE_SALON='Lumière salon',
        -- Groupe
        GROUPE_TOUS_VOLETS = '[Grp] Tous Volets',
        GROUPE_VOLETS_CHAMBRES = '[Grp] Volets Chambres',
        GROUPE_VOLETS_SALON = '[Grp] Volets Salon',
        -- Mode
        DEVICE_MODE_DOMICILE = 'Mode Domicile',
        -- livebox
        DEVICE_STATUT_LIVEBOX = 'Livebox',
        DEVICE_STATUT_DOMOTIQUE = 'Domotique',
        DEVICE_STATUT_TV = 'TV',
        DEVICE_STATUT_PERSONNAL_DEVICES = 'Equipements Personnels',
        
        -- ### Fonctions utilitaires
        isWeekEnd = function(domoticz)
            local weekDay = domoticz.time.wday
            domoticz.log("weekDay = " .. weekDay)
            return (weekDay == 1 or weekDay == 7)
        end,
        -- # Fonction de recherche du suffixe suivant le mode du Domicile
        getModeDomicile = function(domoticz)
            local modeDomicile = domoticz.devices(domoticz.helpers.DEVICE_MODE_DOMICILE).levelName
            domoticz.log("Mode Domicile : [" .. domoticz.devices(domoticz.helpers.DEVICE_MODE_DOMICILE).levelName .. "]")
            local suffixeMode = ''
            if(modeDomicile == 'Présents') then
                suffixeMode = ''
            elseif(modeDomicile == 'Absents') then
                suffixeMode = '_abs'
            elseif(modeDomicile == 'Vacances') then
                suffixeMode = '_vacs'
            elseif(modeDomicile == 'Eté') then
                suffixeMode = '_ete'
            end
            return suffixeMode
        end,
        -- # Fonction de recherche d'un node dans un arbre JSON à partir de son nom
        getNodeFromJSonTreeByName = function(jsonData, nodeName)
            for i, node in pairs(jsonData) do
                if(node.name == nodeName) then
                    return node
                end
            end
            return nil
        end,
        -- ### FONCTIONS HTTP VERS LE BRIDGE TYDOM
        -- # Fonction d'appel GET de la passerelle Tydom
        callTydomBridgeGET = function (uriToCall, callbackName, domoticz)
            local host_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE).value

            if(callbackName == nil) then
               callbackName = 'global_HTTP_response' 
            end
            
            domoticz.openURL({
                url = 'http://'..host_tydom_bridge..'' .. uriToCall,
                method = 'GET',
                header = { ['Content-Type'] = 'application/json' },
                callback = callbackName
            })
            return
        end,
        
        -- # Fonction d'appel POST de la passerelle Tydom
        callTydomBridgePOST = function (uriToCall, domoticz)
            
            local host_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE).value

            domoticz.openURL({
                url = 'http://'..host_tydom_bridge..'' .. uriToCall,
                method = 'POST',
                header = { ['Content-Type'] = 'application/json' },
                callback = 'global_HTTP_response'
            })
            return
        end,
        
        -- # Fonction d'appel PUT de la passerelle Tydom
        callTydomBridgePUT = function (uriToCall, putData, callbackName, domoticz)
            
            local host_tydom_bridge = domoticz.variables(domoticz.helpers.VAR_TYDOM_BRIDGE).value
            
            if(callbackName == nil) then
               callbackName = 'global_HTTP_response' 
            end

            domoticz.openURL({
                url = 'http://'..host_tydom_bridge..'' .. uriToCall,
                method = 'PUT',
                header = { ['Content-Type'] = 'application/json' },
                postData = putData,
                callback = callbackName
            })
            return
        end,
        
        -- ### FONCTIONS HTTP VERS LA LIVEBOX

        -- Authentification
        authenticateToLivebox = function(callbackName, domoticz)
    
            domoticz.log("Authentification à la Livebox ORANGE", domoticz.LOG_DEBUG) 
    
            local host_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_HOST).value
            local login_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_LOGIN).value
            local pwd_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_PWD).value
            local authData = { ['service'] = 'sah.Device.Information', 
                               ['method'] = 'createContext',
                               ['parameters'] = { ['applicationName'] = 'so_sdkut', 
                                                  ['username'] = login_livebox, 
                                                  ['password'] = pwd_livebox }}
            -- Appel de l'authentification
            local fullcmd = "curl -s -H \"Content-Type: application/x-sah-ws-4-call+json\" -H \"Authorization:X-Sah-Login\" -d '" 
                            .. domoticz.utils.toJSON(authData) .. "' -c /opt/domoticz/userdata/scripts/dzVents/data/liveboxCookieAuth.cookie -X POST " ..
                            "'http://" .. host_livebox .. "/ws'"

        	domoticz.executeShellCommand({ 
        	            command = fullcmd, 
        	            callback = callbackName })
        end,  
        -- Appel POST
        callLiveboxPOST = function (contextId, postData, callbackName, domoticz)
            
            local host_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_HOST).value
            
            if(callbackName == nil) then
               callbackName = 'global_HTTP_response' 
            end
            domoticz.log("contextId=["..contextId.."]")
            local fullcmd = "SESSID=`cat /opt/domoticz/userdata/scripts/dzVents/data/liveboxCookieAuth.cookie  | awk 'END{print}' | awk '{new_var=$(NF-1)\"=\"$(NF); print new_var}'` ; " ..
            "curl -s -H \"Content-Type: application/x-sah-ws-4-call+json\" -H \"X-Context: " .. contextId .. "\" -d '" .. domoticz.utils.toJSON(postData) .. "' -b \"$SESSID\" -X POST 'http://" .. host_livebox .. "/ws'"

        	domoticz.executeShellCommand({ 
        	        command = fullcmd, 
        	        callback = callbackName })            
        end
    }
}