#!/usr/bin/lua
commandArray = {}

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'livebox_tele'
require 'utils'

--
-- Fonction Commande de la télévision pour afficher une chaine sur CanalSat
-- la fonction callCommandeTV est définie dans livebox_tele.lua
-- @param ip_livebox_tv : code de la télécommande
-- @param channel_tv : Chaine à lancer
function commandeTeleCanalSat(channel_tv)

	logTV("Démarrage de la Livebox TV sur la chaine " .. channel_tv)
	-- Démarrage / ON
	callCommandeTV("116", false)
	pause(2)
	-- Son à 0
	callCommandeTV("114", true)
	callCommandeTV("114", true)
	callCommandeTV("114", true)
	callCommandeTV("114", true)
	-- CanalSat	normalement déjà configurée

	-- Découpage de la chaine en chiffre
	size=string.len(channel_tv)
	for i=1,size,1 
	do
		touche=string.sub(channel_tv, i, i)
	 	callCommandeTV(512 + touche, false)
	end
	-- Son à +3
	callCommandeTV("115", true)
	callCommandeTV("115", false)
	callCommandeTV("115", false)
end



-- Fonction principale
--   Action ssi l'état de Livebox Player est à On
--
if ( devicechanged['Livebox Player'] == 'On' ) then
	logTV("Démarrage de la télévision")
	-- Test de la variable
	channel_tv = uservariables["channel_tv"]
	if( channel_tv == nil ) then
		error("[ERREUR] La variable {channel_tv} n'est pas définie dans Domoticz")
		return 512
	else
		-- Lancement de la commande télé dans une coroutine
		co = coroutine.create(function ()
			commandeTeleCanalSat(channel_tv)
			end
		)
		coroutine.resume(co)
	end	
elseif ( devicechanged['Livebox Player'] == 'Off' ) then
	logTV("Arrêt de la télévision")
	-- Lancement de la commande télé dans une coroutine
	co = coroutine.create(function ()
		callCommandeTV("116", false)
		end
	)
	coroutine.resume(co)
end 
return commandArray