#!/usr/bin/lua
commandArray = {}

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'livebox_tele'
require 'utils'

--
-- Fonction Commande de la télévision pour afficher une chaine sur CanalSat
-- la fonction callCommandeLivebox est définie dans livebox_tele.lua
-- @param ip_livebox_tv : code de la télécommande
-- @param channel_tv : Chaine à lancer
function commandeTeleCanalSat(ip_livebox_tv, channel_tv)

	logTV("Démarrage de la Livebox TV [" .. ip_livebox_tv .. "] sur la chaine " .. channel_tv)
	-- Démarrage / ON
	callCommandeLivebox(ip_livebox_tv, "116", false)
	pause(2)
	-- Son à 0
	callCommandeLivebox(ip_livebox_tv, "114", true)
	callCommandeLivebox(ip_livebox_tv, "114", true)
	callCommandeLivebox(ip_livebox_tv, "114", true)
	callCommandeLivebox(ip_livebox_tv, "114", true)
	-- CanalSat	normalement déjà configurée

	-- Découpage de la chaine en chiffre
	size=string.len(channel_tv)
	for i=1,size,1 
	do
		touche=string.sub(channel_tv, i, i)
	 	callCommandeLivebox(ip_livebox_tv, 512 + touche, false)
	end
	-- Son à +3
	callCommandeLivebox(ip_livebox_tv, "115", true)
	callCommandeLivebox(ip_livebox_tv, "115", false)
	callCommandeLivebox(ip_livebox_tv, "115", false)
end



-- Fonction principale
--   Action ssi l'état de Livebox Player est à On
--
if ( devicechanged['Livebox Player'] == 'On' ) then
	logTV("Démarrage de la télévision")
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
elseif ( devicechanged['Livebox Player'] == 'Off' ) then
	logTV("Arrêt de la télévision")
	-- Test de la variable
	ip_livebox_tv = uservariables["ip_livebox_tv"]
	if( ip_livebox_tv == nil ) then
		error("[ERREUR] La variable {ip_livebox_tv} n'est pas définie dans Domoticz")
		return 512
	else
		-- Lancement de la commande télé dans une coroutine
		co = coroutine.create(function ()
			callCommandeLivebox(ip_livebox_tv, "116", false)
			end
		)
		coroutine.resume(co)
	end		
end 
return commandArray