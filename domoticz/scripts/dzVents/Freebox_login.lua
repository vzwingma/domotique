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
        
    -- #### Helpers de sécurisation de la commande shell (T-B3) ####

        -- Échappe une valeur pour insertion dans un contexte shell entre guillemets simples.
        -- Remplace chaque ' par '\'' (fin de guillemet, guillemet littéral, ouverture de guillemet).
        -- Doit être appliqué à toutes les valeurs interpolées dans une commande shell.
        local function shellEscape(s)
            return "'" .. s:gsub("'", "'\\''") .. "'"
        end

        -- Valide qu'une entrée shell est acceptable : non vide, de type string, sans caractère nul ni
        -- retour à la ligne (qui permettraient une injection de commandes multi-lignes).
        -- @param value   : valeur à contrôler
        -- @param name    : nom du paramètre (pour le message de log)
        -- @param uuid    : identifiant de corrélation
        -- @return true si valide, false sinon (avec log ERROR)
        local function validateShellInput(value, name, uuid)
            if type(value) ~= 'string' or #value == 0 then
                domoticz.log("[" .. uuid .. "] Freebox shell : paramètre '" .. name .. "' absent ou vide — abandon de la commande", domoticz.LOG_ERROR)
                return false
            end
            if value:find("[\0\n\r]") then
                domoticz.log("[" .. uuid .. "] Freebox shell : paramètre '" .. name .. "' contient un caractère de contrôle non autorisé — abandon de la commande", domoticz.LOG_ERROR)
                return false
            end
            return true
        end

    -- #### Fonctions de communication avec la Freebox

        -- Authentification/ Login sur Freebox pour obtenir le challenge
        local function freeboxLogin(domoticz)
    
            domoticz.log("[" .. domoticz.data.uuid .. "] Authentification à la Freebox Delta", domoticz.LOG_DEBUG) 

            local host_freebox = domoticz.variables(domoticz.helpers.VAR_FREEBOX_HOST).value
            domoticz.openURL({
                url = 'http://'..host_freebox..'' .. "/login",
                method = 'GET',
                headers = { ['Content-Type'] = 'application/json',  ['X-CorrId'] = domoticz.data.uuid },
                callback = 'freebox_login'
            })
        end
    
        -- Calcul du challenge pour avoir le password
        local function freeboxGetPassword(challenge, domoticz)
    
            domoticz.log("[" .. domoticz.data.uuid .. "] Calcul du mot de passe", domoticz.LOG_DEBUG) 
            local apptoken_freebox = domoticz.variables(domoticz.helpers.VAR_FREEBOX_APP_TOKEN).value

            -- Validation des entrées avant construction de la commande shell (T-B3)
            -- Les valeurs challenge et app_token sont interpolées dans une commande shell ;
            -- toute valeur anormale doit interrompre le flux plutôt que produire une commande invalide.
            if not validateShellInput(challenge, 'challenge', domoticz.data.uuid) then return end
            if not validateShellInput(apptoken_freebox, 'app_token', domoticz.data.uuid) then return end

            domoticz.log("[" .. domoticz.data.uuid .. "] - challenge = [" .. challenge .. "]", domoticz.LOG_DEBUG)
            -- Note sécurité : app_token non journalisé (secret applicatif).

            -- Construction sécurisée de la commande : les deux valeurs sont échappées
            -- via shellEscape() pour neutraliser tout guillemet simple ou caractère spécial.
            local fullcmd = "echo -n " .. shellEscape(challenge)
                         .. " | openssl dgst -sha1 -hmac " .. shellEscape(apptoken_freebox)
                         .. " | cut -d '=' -f2 | sed 's/ //g'"
            -- Appel de la session
            domoticz.executeShellCommand({ 
    	            command = fullcmd, 
    	            callback = 'freebox_pwd' })
            
        end

        -- Ouverture de session
        local freeboxOpenSession = function(passHmacSha1, domoticz)
    
            domoticz.log("[" .. domoticz.data.uuid .. "] Ouverture de session à la Freebox Delta", domoticz.LOG_DEBUG) 
    
            local host_freebox = domoticz.variables(domoticz.helpers.VAR_FREEBOX_HOST).value

            -- Appel de la session
            domoticz.openURL({
                url = 'http://'..host_freebox..'' .. "/login/session",
                method = 'POST',
                headers = { ['Content-Type'] = 'application/json',  ['X-CorrId'] = domoticz.data.uuid },
                postData = {
                            app_id = 'fr.freebox.domoticz.app',
                            password = passHmacSha1
                            },
                callback = 'freebox_session'
            })            
            
        end

        -- Session ouverte sur la Freebox
        local function freeboxAuthenticated(session_token, domoticz)
            domoticz.emitEvent('freebox_session', { data = session_token, uuid = domoticz.data.uuid })
        end


        local freeboxCloseSession = function(uuid, sessionToken, domoticz)
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

        if(item.statusCode == 200) then
            -- Nil guard : vérifier que le JSON contient bien les champs attendus avant d'y accéder
            if item.json == nil or item.json.result == nil or item.json.result.challenge == nil then
                domoticz.log("[" .. domoticz.data.uuid .. "] Réponse login Freebox invalide (JSON absent ou champ 'challenge' manquant)", domoticz.LOG_ERROR)
            else
                domoticz.log("[" .. domoticz.data.uuid .. "] Login callback : " .. item.statusCode .. " - logged_in:" .. tostring(item.json.result.logged_in) .. " - result:" .. tostring(item.json.result) , domoticz.LOG_DEBUG)
                domoticz.log("[" .. domoticz.data.uuid .. "] Login callback : challenge " .. item.json.result.challenge , domoticz.LOG_DEBUG)
                freeboxGetPassword(item.json.result.challenge, domoticz)
            end
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
            -- Nil guard : vérifier que le session_token est présent avant d'y accéder
            if item.json == nil or item.json.result == nil or item.json.result.session_token == nil then
                domoticz.log("[" .. domoticz.data.uuid .. "] Réponse session Freebox invalide (JSON absent ou champ 'session_token' manquant)", domoticz.LOG_ERROR)
            else
                domoticz.log("[" .. domoticz.data.uuid .. "] Session callback : " .. item.statusCode .. " - Session Token :" .. item.json.result.session_token , domoticz.LOG_DEBUG)
                freeboxAuthenticated(item.json.result.session_token, domoticz)
            end
        else 
            local errMsg = (item.json and item.json.msg) or item.data or "réponse vide"
            domoticz.log("[" .. domoticz.data.uuid .. "] Erreur de connexion à la Freebox " .. item.statusCode .. " - " .. tostring(errMsg) , domoticz.LOG_ERROR)
        end
    elseif(item.isCustomEvent and item.customEvent == 'freebox_endsession') then 
        if item.json == nil or item.json.uuid == nil or item.json.sessionToken == nil then
            domoticz.log("[n/a] freebox_endsession : événement mal formé (json, uuid ou sessionToken absent) — clôture de session ignorée", domoticz.LOG_ERROR)
        else
            freeboxCloseSession(item.json.uuid, item.json.sessionToken, domoticz)
        end
    end
end
}