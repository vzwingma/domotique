#!/usr/bin/lua
commandArray = {}

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'utils'

-- LOG dans utils
-- Paramètres du script
telecommande_1="17337810"
telecommande_2="16679162"
gpio_pin="0"

-- Fonction d'appel à l'API du conteneur Docker Radio
-- Pour lancer une commande : apiCallPOSTReadJSON dans utils.lua
-- @param parametre : paramètre à envoyer sur la radio
function callApiDockerRadio(parametre)
	local url="http://radio:9000/cmd"
	-- Construction du body
	local json_body = "{"
	json_body = json_body .. '\"commande\" : \"radioEmission\",'
	json_body = json_body .. '\"params\" : [ "'.. gpio_pin ..'\", '.. parametre .. ']'
	json_body = json_body .. "}"
	-- logRadio("Appel de la commande : ".. json_body)
	local resultat = apiCallPOSTReadJSON(url, json_body)
	if(resultat.erreur ~= nil) then
		error("[RADIO] Erreur lors de la commande : " .. resultat.erreur)
	else
		logRadio("Résultat : "..resultat.resultat.gpio )
	end
end



-- Fonction principale
-- Détection des événements sur les interrupteurs dans domoticZ
-- Préparation des paramètres
--
if ( devicechanged[DEVICE_TELE] == 'On' ) then
	logRadio("Démarrage de la télévision")
	callApiDockerRadio("\"".. telecommande_1 .."\", \"1\", \"on\"")
	
elseif ( devicechanged[DEVICE_TELE] == 'Off' ) then
	logRadio("Arrêt de la télévision")
	callApiDockerRadio("\"".. telecommande_1 .."\", \"1\", \"off\"")
	
elseif ( devicechanged[DEVICE_LAMPE1] == 'On' ) then
	logRadio("Allumage de la lampe 1")
	callApiDockerRadio("\"".. telecommande_2.."\", \"1\", \"on\"")
	
elseif ( devicechanged[DEVICE_LAMPE1] == 'Off' ) then
	logRadio("Extinction de la lampe 1")
		callApiDockerRadio("\"".. telecommande_2 .."\", \"1\", \"off\"")
		
elseif ( devicechanged[DEVICE_LAMPE2] == 'On'  ) then
	logRadio("Allumage de la lampe 2")
		callApiDockerRadio("\"".. telecommande_2 .."\", \"2\", \"on\"")
		
elseif ( devicechanged[DEVICE_LAMPE2] == 'Off') then
	logRadio("Extinction de la lampe 2")
	callApiDockerRadio("\"".. telecommande_2 .."\", \"2\", \"off\"")
end 
return commandArray