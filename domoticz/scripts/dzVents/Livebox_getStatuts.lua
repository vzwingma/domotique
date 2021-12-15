-- ## Scripts de lecture des éléments issus de la Livebox pour mettre à jour le comportement Domoticz
-- ## Paramètres nécessaires : 
--  Variables Utilisateurs : 
--      livebox_host : host de la livebox (livebox)
--      livebox_login : login (admin) de connexion
--      livebox_pwd : mot de passe de connexion
return {
    on = {
        timer = { 'every minute' },
        shellCommandResponses = { 'livebox_getStatuts' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[ORANGE Livebox] "
    },
    execute = function(domoticz, item)
        
    -- #### Fonctions de communication avec la Livebox
      
    
        -- Recherche des équipements connectés
        function getConnectedDevices(contextId, domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "] Recherche des équipements connectés", domoticz.LOG_DEBUG)
            local postData = { ['service'] = 'Devices.Device.HGW' , ['method'] = 'topology', ['parameters'] = {} }
            domoticz.helpers.callLiveboxPOST(contextId, postData, domoticz.data.uuid, 'livebox_LAN_statuts', domoticz)
        end

    
        -- ##### Exécution des traitments sur les API Orange
        function sessionConnectedToLivebox(contextId, domoticz)
            domoticz.log("[" .. domoticz.data.uuid .. "] Connecté à la Livebox - contextID = ["..contextId.."]", domoticz.LOG_DEBUG)
            -- Une fois connecté, on appelle les différents services
            getConnectedDevices(contextId, domoticz)
        end 
        
        
    -- ## Déclenchement de la fonction /
        if(item.isTimer) then
            domoticz.data.uuid = domoticz.helpers.uuid()
            -- d'abord l'Authentification
            domoticz.log("[" .. domoticz.data.uuid .. "] Init de la connexion à la Livebox Orange", domoticz.LOG_DEBUG)
            domoticz.helpers.authenticateToLivebox(domoticz.data.uuid, 'livebox_getStatuts', domoticz)
            
        -- ## Call back après AUth
        elseif(item.isShellCommandResponse) then 
            domoticz.log("[" .. domoticz.data.uuid .. "] Auth Callback " .. item.statusCode .. " - " .. item.statusText, domoticz.LOG_DEBUG)
            sessionConnectedToLivebox(item.json.data.contextID, domoticz)
        end

    end
}