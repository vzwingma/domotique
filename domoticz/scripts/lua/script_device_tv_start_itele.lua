#!/usr/bin/lua
commandArray = {}

-- LOG
function log(message)
	print("[TV] " .. message)
end
--
-- Fonction Commande de la télévision 
--   pour afficher une chaine sur CanalSat
-- @param ip_livebox_tv : code de la télécommande
-- @param channel_tv : Chaine à lancer
function commandeTeleCanalSat(ip_livebox_tv, channel_tv)
	datelog=os.date("%a")
	log("Démarrage de la Livebox TV [" .. ip_livebox_tv .. "] sur la chaine " .. channel_tv)
	-- Démarrage / ON
	callUrlLivebox(ip_livebox_tv, "116", false)
	pause(10)
	-- Son à 0
	callUrlLivebox(ip_livebox_tv, "114", true)
	callUrlLivebox(ip_livebox_tv, "114", true)
	callUrlLivebox(ip_livebox_tv, "114", true)
	callUrlLivebox(ip_livebox_tv, "114", true)
	callUrlLivebox(ip_livebox_tv, "114", true)
	-- CanalSat	normalement déjà configurée

	-- Découpage de la chaine en chiffre
	size=string.len(channel_tv)
	for i=1,size,1 
	do
		touche=string.sub(channel_tv, i, i)
	 	callUrlLivebox(ip_livebox_tv, 512 + touche, false)
	end
	-- Son à +3
	callUrlLivebox(ip_livebox_tv, "115", true)
	callUrlLivebox(ip_livebox_tv, "115", false)
	callUrlLivebox(ip_livebox_tv, "115", false)
end



-- Fonction d'appel à l'API du Orange Livebox Player
-- Pour lancer une commande : Curl
-- @param ip_livebox_tv : IP de la livebox
-- @param key : touche 
-- @param appuilong : appui long ? 

function callUrlLivebox(ip_livebox_tv, key, appuilong)
	baseurl="http://" .. ip_livebox_tv .. ":8080/remoteControl/cmd?operation=01&key=" .. key .. "&mode="
	if( appuilong == true ) then
		url=baseurl .. "1"
	else
		url=baseurl .. "0"
	end
	
	-- log("Appel de l'URL : [" .. url .. "]")
	os.execute("curl '".. url .. "'")
	
	if( appuilong == true ) then
		os.execute("sleep 1")
		url=baseurl .. "2"
	--	log("Appel de l'URL : [" .. url .. "]")
		os.execute("curl '".. url .. "'")
	end
end

-- Pause
-- @param tempo : tempo d'après la commande en seconde
function pause(tempo)
	if( tempo > 0 ) then
		log("  Tempo de " .. tempo .. " secondes")
		os.execute("sleep ".. tempo)
	end
end

-- Fonction principale
--   Action ssi l'état de Livebox Player est à On
--
if ( devicechanged['Livebox Player'] == 'On' ) then
	log("Démarrage de la télévision")
	-- Test de la variable
	ip_livebox_tv = uservariables["ip_livebox_tv"]
	channel_tv = uservariables["channel_tv"]
	if( ip_livebox_tv == nil or channel_tv == nil ) then
		error("[ERREUR] Les variables {ip_livebox_tv} et {channel_tv} ne sont pas définies dans Domoticz")
		return 512
	else
		-- Lancement de la commande télé dans une coroutine
		co = coroutine.create(function ()
			commandeTeleCanalSat(ip_livebox_tv, channel_tv)
			end
		)
		coroutine.resume(co)
	end	
	log("FIN")
end 
return commandArray