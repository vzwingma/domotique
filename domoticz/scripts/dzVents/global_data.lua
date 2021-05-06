return {
    helpers = {
        -- Variables d'environnements
        -- Tydom
        VAR_TYDOM_BRIDGE = 'tydom_bridge_host',
        -- Livebox
        VAR_LIVEBOX_HOST = 'livebox_host',
        VAR_LIVEBOX_LOGIN = 'livebox_login',
        VAR_LIVEBOX_PWD = 'livebox_pwd',
        -- Configuration d'usage
        VAR_TEMPERATURE_MATIN = 'param_temp_matin',
        VAR_TEMPERATURE_SOIR = 'param_temp_soir',
        
        -- Devices
        DEVICE_VOLET_SALON_G = 'Volet Salon G',
        DEVICE_VOLET_SALON_D = 'Volet Salon D',
        DEVICE_VOLET_BEBE = 'Volet Bebe',
        DEVICE_VOLET_NOUS = 'Volet Nous',
        DEVICE_TYDOM_TEMPERATURE='Tydom Temperature',
        DEVICE_TYDOM_THERMOSTAT='Tydom Thermostat',
        -- Groupe
        GROUPE_TOUS_VOLETS='[Grp] Tous Volets',
        GROUPE_VOLETS_SALON='[Grp] Volets Salon',
        
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
        callLiveboxPOST = function (contextId, putData, callbackName, domoticz)
            
            local host_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_HOST).value
            
            if(callbackName == nil) then
               callbackName = 'global_HTTP_response' 
            end
            domoticz.log("contextId=["..contextId.."]")
            
            domoticz.openURL({
                url = 'http://'..host_livebox..'/ws',
                method = 'POST',
                headers = { ['Content-type'] = 'application/x-sah-ws-4-call+json', ['X-Context'] = contextId },
                postData = putData,
                callback = callbackName
            })
            return
        end
    }
}