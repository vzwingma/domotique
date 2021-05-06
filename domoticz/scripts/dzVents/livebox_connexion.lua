-- ## Scripts de lecture des éléments issus de la Livebox pour mettre à jour le comportement Domoticz
-- ## Paramètres nécessaires : 
--  Variables Utilisateurs : 
--      livebox_host : host de la livebox (livebox)
--      livebox_login : login (admin) de connexion
--      livebox_pwd : mot de passe de connexion
return {
    on = {
     --   timer = { 'every minute' },
        httpResponses = { 'livebox_connexion' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[ORANGE Livebox] "
    },
    execute = function(domoticz, item)
        
    -- #### Fonctions de communication avec la Livebox
    
        -- Authentification
        function authenticateLivebox()
    
            domoticz.log("Authentification", domoticz.LOG_DEBUG) 
    
            local host_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_HOST).value
            local login_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_LOGIN).value
            local pwd_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_PWD).value
            local authData = { ['service'] = 'sah.Device.Information', 
                              ['method'] = 'createContext',
                              ['parameters'] = { ['applicationName'] = 'so_sdkut', 
                                                 ['username'] = login_livebox, 
                                                 ['password'] = pwd_livebox }}
    
            -- Appel du service d'auth
            domoticz.openURL({
                url = 'http://'..host_livebox..'/ws',
                method = 'POST',
                headers = { ['Content-type'] = 'application/x-sah-ws-4-call+json', ['Authorization'] = 'X-Sah-Login' },
                postData = authData,
                callback = 'livebox_connexion'
            })
        end     
    
    
        -- ##### Exécution des traitments sur les API Orange
        function getStatutsFromLivebox(contextId, domoticz)
            getConnectedDevices(contextId, domoticz)
            
        end
        
        
        -- Requete sur les équipements
        function getConnectedDevices(contextId, domoticz)
            
            domoticz.log("Recherche des équipements connectés", domoticz.LOG_DEBUG)
            
            local postData = { ['service'] = 'Devices.Device.HGW' , ['method'] = 'topology', ['parameters'] = {} }
            domoticz.helpers.callLiveboxPOST(contextId, postData, 'livebox_wan_statuts', domoticz)
        end
        
        
    -- ## Déclenchement de la fonction sur time
        if(item.isTimer) then
            -- Authentification
            domoticz.log("Init de la connexion à la Livebox Orange", domoticz.LOG_DEBUG)
            authenticateLivebox()
            
        -- ## Call back après AUth
        elseif(item.isHTTPResponse) then
            domoticz.log(item.statusCode .. " - " .. item.statusText)
            
            if (item.ok) then -- statusCode == 2xx
                local contextId = item.json.data.contextID
                domoticz.log("- contextID = ["..contextId.."]")
                getStatutsFromLivebox(contextId, domoticz)
            end
        end

    end
}