-- ## Scripts de login à la freebox pour mettre à jour le comportement Domoticz
-- ## Paramètres nécessaires : 
--  Variables Utilisateurs : 
--      freebox_host : host de la freebox : mafreebox.freebox.fr/api/v9
--      freebox_apptoken : app Token
return {
    on = {
        timer = { 'every minute' },
        customEvents = { 'freebox_initsession', 'freebox_endsession' },
        httpResponses = { 'freebox_login', 'freebox_session' },
        shellCommandResponses = { 'freebox_pwd' }
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[Freebox Delta] "
    },
    execute = function(domoticz, item)
        
    -- #### Fonctions de communication avec la Freebox

        -- Authentification/ Login sur Freebox pour obtenir le challenge
        function freeboxLogin(domoticz)
    
            domoticz.log("[" .. domoticz.data.uuid .. "] Authentification à la Freebox Delta", domoticz.LOG_DEBUG) 

            local host_freebox = domoticz.variables(domoticz.helpers.VAR_FREEBOX_HOST).value
            domoticz.openURL({
                url = 'http://'..host_freebox..'' .. "/login",
                method = 'GET',
                headers = { ['Content-Type'] = 'application/json',  ['X-CorrId'] = corrId },
                callback = 'freebox_login'
            })
        end
    
        -- Calcul du challenge pour avoir le password
        function freeboxGetPassword(challenge, domoticz)
    
            domoticz.log("[" .. domoticz.data.uuid .. "] Calcul du mot de passe", domoticz.LOG_DEBUG) 
            local apptoken_freebox = domoticz.variables(domoticz.helpers.VAR_FREEBOX_APP_TOKEN).value
            domoticz.log("[" .. domoticz.data.uuid .. "] - challenge = [" .. challenge .. "]", domoticz.LOG_DEBUG)
            domoticz.log("[" .. domoticz.data.uuid .. "] - app_token = [" .. apptoken_freebox .. "]", domoticz.LOG_DEBUG)
            local fullcmd = "echo -n '" .. challenge .. "' | openssl dgst -sha1 -hmac '" .. apptoken_freebox .. "' | cut -d '=' -f2 | sed 's/ //g'"
            -- Appel de la session
            domoticz.executeShellCommand({ 
        	            command = fullcmd, 
        	            callback = 'freebox_pwd' })
            
        end

        -- Ouverture de session
        freeboxOpenSession = function(passHmacSha1, domoticz)
    
            domoticz.log("[" .. domoticz.data.uuid .. "] Ouverture de session à la Freebox Delta", domoticz.LOG_DEBUG) 
    
            local host_freebox = domoticz.variables(domoticz.helpers.VAR_FREEBOX_HOST).value

            -- Appel de la session
            domoticz.openURL({
                url = 'http://'..host_freebox..'' .. "/login/session",
                method = 'POST',
                headers = { ['Content-Type'] = 'application/json',  ['X-CorrId'] = corrId },
                postData = {
                            app_id = 'fr.freebox.domoticz.app',
                            password = passHmacSha1
                            },
                callback = 'freebox_session'
            })            
            
        end

        -- Session ouverte sur la Freebox
        function freeboxAuthenticated(session_token, domoticz)
            domoticz.emitEvent('freebox_session', { data = session_token, uuid = domoticz.data.uuid })
        end


        freeboxCloseSession = function(uuid, sessionToken, domoticz)
            domoticz.log("[" .. uuid .. "][sessionToken=" .. sessionToken .. "] Clôture de la session", domoticz.LOG_DEBUG)
            local host_freebox = domoticz.variables(domoticz.helpers.VAR_FREEBOX_HOST).value
            -- Appel de la session
            domoticz.openURL({
                url = 'http://'..host_freebox..'' .. "/login/logout",
                method = 'POST',
                headers = { ['Content-Type'] = 'application/json',  ['X-CorrId'] = uuid, ['X-Fbx-App-Auth'] = sessionToken },
                callback = 'global_HTTP_response'
            })          
        end

        
    -- ## Déclenchement de la fonction /
    if(item.isTimer or (item.isCustomEvent and item.customEvent == 'freebox_initsession')) then
        domoticz.data.uuid = domoticz.helpers.uuid()
        -- d'abord l'Authentification
        domoticz.log("[" .. domoticz.data.uuid .. "] Init de la connexion à la Freebox", domoticz.LOG_DEBUG)
        freeboxLogin(domoticz)
            
    -- ## Call back après login
    elseif(item.isHTTPResponse and item.callback == 'freebox_login') then 

        domoticz.log("[" .. domoticz.data.uuid .. "] Login callback : " .. item.statusCode .. " - logged_in:" .. tostring(item.json.result.logged_in) .. " - result:" .. tostring(item.json.result) , domoticz.LOG_DEBUG)
        domoticz.log("[" .. domoticz.data.uuid .. "] Login callback : challenge " .. item.json.result.challenge , domoticz.LOG_DEBUG)
        
        if(item.statusCode == 200) then
            freeboxGetPassword(item.json.result.challenge, domoticz)
        else 
            domoticz.log("[" .. domoticz.data.uuid .. "] Erreur de connexion à la Freebox " .. item.statusCode .. " - " .. item.data , domoticz.LOG_ERROR)
        end
    -- ## Callback après calcul du HMAc SHA1
    elseif(item.isShellCommandResponse and item.callback == 'freebox_pwd') then 

        domoticz.log("[" .. domoticz.data.uuid .. "] Pwd callback : [" .. item.statusCode .. "] - HMAC Sha1: [" .. item.data .."]" , domoticz.LOG_DEBUG)
        if(item.statusCode == 0) then
            freeboxOpenSession(item.data, domoticz)
        else 
            domoticz.log("[" .. domoticz.data.uuid .. "] Erreur de connexion à la Freebox " .. item.statusCode .. " - " .. item.data , domoticz.LOG_ERROR)
        end

    -- ## Call back après session
    elseif(item.isHTTPResponse and  item.callback == 'freebox_session') then 
            
        if(item.statusCode == 200) then
            domoticz.log("[" .. domoticz.data.uuid .. "] Session callback : " .. item.statusCode .. " - Session Token :" .. item.json.result.session_token , domoticz.LOG_DEBUG)
            freeboxAuthenticated(item.json.result.session_token, domoticz)
            
        else 
            domoticz.log("[" .. domoticz.data.uuid .. "] Erreur de connexion à la Freebox " .. item.statusCode .. " - " .. item.json.msg , domoticz.LOG_ERROR)
        end
    elseif(item.isCustomEvent and item.customEvent == 'freebox_endsession') then 
        freeboxCloseSession(item.json.uuid, item.json.sessionToken, domoticz)
    end
end
}