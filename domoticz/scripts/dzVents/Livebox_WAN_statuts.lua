-- ## Scripts de lecture des éléments issus de la Livebox pour mettre à jour le comportement Domoticz
-- ## Paramètres nécessaires : 
--  Variables Utilisateurs : 
--      livebox_host : host de la livebox (livebox)
return {
    on = {
        timer = { 'every hour' },
        httpResponses = { 'livebox_WAN_statuts' }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[WAN Livebox] "
    },
    execute = function(domoticz, item)
        
    -- #### Fonctions de communication avec la Livebox
    
        -- Recherche du statut WAN de la Livebox
        function getWanStatutLivebox()
    
           domoticz.log("Recherche du statut de la Livebox Orange", domoticz.LOG_DEBUG)
            
            local host_livebox = domoticz.variables(domoticz.helpers.VAR_LIVEBOX_HOST).value
            local WANData = { ['service'] = 'NMC' , ['method'] = 'getWANStatus', ['parameters'] = {} }
            
            domoticz.openURL({
                url = 'http://'..host_livebox..'/ws',
                method = 'POST',
                headers = { ['Content-type'] = 'application/x-sah-ws-4-call+json' },
                postData = WANData,
                callback = 'livebox_WAN_statuts'
            })
        
        end     
    
    
        -- ##### Exécution des traitments sur les API Orange
        function getStatutsFromLivebox(WANStatutData, domoticz)
           domoticz.log("Etat de la connexion Livebox/Orange : WAN=" .. WANStatutData.WanState .. ", Link=" .. WANStatutData.LinkState)
           local alertLevel = domoticz.ALERTLEVEL_GREY
           if(WANStatutData.WanState == "up" and  WANStatutData.LinkState == "up") then
               alertLevel = domoticz.ALERTLEVEL_GREEN
            elseif(WANStatutData.WanState == "down" and  WANStatutData.LinkState == "down") then
                alertLevel = domoticz.ALERTLEVEL_RED
            elseif(WANStatutData.WanState == "down" or  WANStatutData.LinkState == "down") then
                alertLevel = domoticz.ALERTLEVEL_ORANGE
            else
                alertLevel = domoticz.ALERTLEVEL_GREY
            end
            -- Mise à jour du statut WAN
            domoticz.devices(domoticz.helpers.DEVICE_STATUT_LIVEBOX).updateAlertSensor(alertLevel, "WAN=" .. WANStatutData.WanState .. ", Link=" .. WANStatutData.LinkState)
        end

        
        
    -- ## Déclenchement de la fonction sur time
        if(item.isTimer) then
            getWanStatutLivebox()
            
        -- ## Call back après AUth
        elseif(item.isHTTPResponse) then 
            domoticz.log(item.statusCode .. " - " .. item.statusText)
            getStatutsFromLivebox(item.json.data, domoticz)
        end

    end
}
