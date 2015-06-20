#!/usr/bin/lua
commandArray = {}

-- LOG
function log(message)
	print("[TV] " .. message)
end
--
-- Fonction Commande de la télévision 
--   pour afficher une chaine sur CanalSat
-- @param freeboxCode : code de la télécommande
-- @param freeboxChannel : Chaine à lancer
function commandeTeleCanalSat(freeboxCode, freeboxChannel)
	datelog=os.date("%a")
	log("Démarrage de la FreeboxTV [" .. freeboxCode .. "] sur la chaine " .. freeboxChannel)
	
	-- callUrlFreebox(freeboxCode, "power", false, 10)
	-- Démarrage
	callUrlFreebox(freeboxCode, "power", false, 30)
	-- CanalSat	
	callUrlFreebox(freeboxCode, "down", false, 1)
	callUrlFreebox(freeboxCode, "down", false, 1)
	callUrlFreebox(freeboxCode, "down", false, 1)
	callUrlFreebox(freeboxCode, "ok", false, 10)
	-- Découpage de la chaine en chiffre : appui
	size=string.len(freeboxChannel)
	for i=1,size,1 
	do
		touche=string.sub(freeboxChannel, i, i)
		callUrlFreebox(freeboxCode, touche, false, 0.5)
	end
end



-- Fonction d'appel à l'API de la freebox TV
-- Pour lancer une commande : Curl
-- @param freeboxCode : code de la télécommande
-- @param key : touche 
-- @param appuilong : appui long ? 
-- @param tempo : tempo d'après la commande en seconde
function callUrlFreebox(freeboxCode, key, appuilong, tempo)
	url="http://hd1.freebox.fr/pub/remote_control?code=" .. freeboxCode .. "\\&key=" .. key
	if( appuilong == true ) then
		url=url .. "\&long=true"
	end
	
	log("Appel de l'URL : [" .. url .. "]")
	os.execute("curl ".. url)
	
	if( tempo > 0 ) then
		log("  Tempo de " .. tempo .. " secondes")
		os.execute("sleep ".. tempo)
	end
end



-- Fonction principale
--   Action ssi l'état de Freebox Player est à On
--
if ( devicechanged['Freebox Player'] == 'On' ) then
	log("Démarrage de la télévision")
	-- Test de la variable
	freeboxCode = uservariables["freebox_code"]
	freeboxChannel = uservariables["freebox_channel"]
	scriptShDir = uservariables["script_sh_dir"]
	if( freeboxCode == nil or freeboxChannel == nil or scriptShDir == nil ) then
		error("[ERREUR] Les variables {freebox_code} et {freebox_channel} ou {scriptShDir} ne sont pas définies dans Domoticz")
		return 512
	else
		-- Lancement de la commande télé dans une coroutine
		co = coroutine.create(function ()
					commandeTeleCanalSat(freeboxCode, freeboxChannel)
				end
		)
		coroutine.resume(co)
	end	
	log("FIN")
end 
return commandArray