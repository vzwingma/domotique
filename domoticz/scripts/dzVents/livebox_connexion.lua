-- ## Scripts de lecture des éléments issus de la Livebox pour mettre à jour le comportement Domoticz
-- ## Paramètres nécessaires : 
--  Variables Utilisateurs : 
--      livebox_host : host de la livebox (livebox)
--      livebox_login : login (admin) de connexion
--      livebox_pwd : mot de passe de connexion
return {
    on = {
        devices = { 'TriggerTest' },
        httpResponses = { 'livebox_connexion' },
        shellCommandResponses = { 'livebox_connexion' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[ORANGE Livebox] "
    },
    execute = function(domoticz, item)
        
    -- #### Fonctions de communication avec la Livebox
    
        -- Authentification
        function authenticateToLivebox()
    
            domoticz.log("Authentification", domoticz.LOG_DEBUG) 
    
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
        	        callback = 'livebox_connexion' })
        end     
    
        -- Recherche des équipements connectés
        function getConnectedDevices(contextId, domoticz)
            domoticz.log("Recherche des équipements connectés", domoticz.LOG_DEBUG)
            local host_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_HOST).value
            local postData = { ['service'] = 'Devices.Device.HGW' , ['method'] = 'topology', ['parameters'] = {} }
            local fullcmd = "SESSID=`cat /opt/domoticz/userdata/scripts/dzVents/data/liveboxCookieAuth.cookie  | awk 'END{print}' | awk '{new_var=$(NF-1)\"=\"$(NF); print new_var}'` ; " ..
            "curl -s -H \"Content-Type: application/x-sah-ws-4-call+json\" -H \"X-Context: " .. contextId .. "\" -d '" .. domoticz.utils.toJSON(postData) .. "' -b \"$SESSID\" -X POST 'http://" .. host_livebox .. "/ws'"

        	domoticz.executeShellCommand({ 
        	        command = fullcmd, 
        	        callback = 'livebox_LAN_statuts' })            
        end

    
        -- ##### Exécution des traitments sur les API Orange
        function sessionConnectedToLivebox(contextId, domoticz)
            getConnectedDevices(contextId, domoticz)
        end 
        
        
    -- ## Déclenchement de la fonction sur time
        if(item.isDevice) then
            -- Authentification
            domoticz.log("Init de la connexion à la Livebox Orange", domoticz.LOG_DEBUG)
            authenticateToLivebox()
            
        -- ## Call back après AUth
        elseif(item.isShellCommandResponse) then 
            domoticz.log(item.statusCode .. " - " .. item.statusText)
            local contextId = item.json.data.contextID
            domoticz.log("- contextID = ["..contextId.."]")
            sessionConnectedToLivebox(contextId, domoticz)
        end

    end
}