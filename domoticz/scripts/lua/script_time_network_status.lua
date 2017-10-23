commandArray = {}
-- Liste des adresse MAC des smartphones sur le Wifi
mac_adress_smartphones=uservariables["at_home_mac_adresses"]
at_home_invite=uservariables["at_home_invite"]

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'utils'
-- logOrange dans utils
-- URL des API
local apiLiveBox="http://livebox.home"
local apiDomoticz="http://localhost:8080/json.htm?"

-- 
local patternMacAdresses = string.format("([^%s]+)", ";")
local dureeInactive = 15

-- Fonction de recherche des périphériques connectés
-- Connexion à la Livebox pour lister les périphériques
-- @param apiLiveBox : URL de l'API Livebox
-- @param mac_adress_smartphones: variable domoticz de la liste des adresses MAC à vérifier
-- @return périphériques connectés ?
function getPeripheriquesConnectes() 
	local TMP_PERIPHERIQUES = "/tmp/peripheriques.tmp"

	--  Appel sur la liste des périphériques
	logOrange("Recherche des connexions des périphériques sur la LiveBox Orange")
	local commandeurl="curl -s -X POST -H 'Cache-Control: no-cache' -d '' " .. apiLiveBox .. "/sysbus/Devices:get"
	os.execute(commandeurl .. " > " .. TMP_PERIPHERIQUES)
	-- logOrange(">>" .. commandeurl.. "<<")
	local json_peripheriques = JSON:decode(readAll(TMP_PERIPHERIQUES))
	local etatSmartphone = false
	-- Liste des périphériques
	for index, peripherique in pairs(json_peripheriques.status) do
--		logOrange("Statut du périphérique " .. index .. " :: " .. peripherique.Key)
		for mac in string.gmatch(mac_adress_smartphones, patternMacAdresses) do
			if(mac == peripherique.Key)
			then
				if(peripherique.Active) then
					local lastChanged = os.time() - convertStringUTCTimeToSeconds(peripherique.LastChanged)
					local lastConnect = os.time() - convertStringUTCTimeToSeconds(peripherique.LastConnection)
					if(lastChanged < 0) then
						lastChanged = 0
					end
					if(lastConnect < 0) then
						logOrange(" Dernière activité : lastConnect= " .. lastConnect .. " s")
						lastConnect = 0
					end
					logOrange("- [" .. peripherique.Name .. "] actif; Dernière activité = " .. peripherique.LastChanged .. " :: " .. lastChanged .. "s / Dernière connexion = " .. peripherique.LastConnection .. " :: " .. lastConnect .. "s");
					if(lastChanged > dureeInactive * 60 or lastConnect > dureeInactive * 60 ) then
						logOrange(" Dernière activité, il y a plus de " .. dureeInactive .. " minutes. Le périphérique est considéré inactif")
					else
						etatSmartphone = true
					end
				end
			end
		end
	end
	return etatSmartphone
end



-- Mise à jour de l'alarme suivant le statut des périphériques
-- @param : état des périphériques
function updateAlarmeStatus(etat_peripheriques)
	local etatActuelAlarme=otherdevices[DEVICE_ALARME]
	local SEUIL_ALARME = 3
	local TMPDIR_COMPTEUR_OUT = "/tmp/compteur_smartphone_out.tmp"
	-- Activation de l'alarme au bout de SEUIL_ALARME min

	if(not etat_peripheriques and etatActuelAlarme == "Off") then
		compteurOff=readAll(TMPDIR_COMPTEUR_OUT)
		if(compteurOff == "") then
			compteurOff = 0
		end
		compteurOff = compteurOff + 1
		logAlarme("  > Compteur de mise en alarme = " .. compteurOff .. " / " .. SEUIL_ALARME)
		if(compteurOff >= SEUIL_ALARME) then
			logAlarme("Activation de l'alarme")
			commandArray[DEVICE_ALARME]="On"
			compteurOff = 0
		end
		os.execute("echo " .. compteurOff .. " > " .. TMPDIR_COMPTEUR_OUT)
	elseif(etat_peripheriques and etatActuelAlarme == "On") then
		-- Désactivation immédiate
		logAlarme("Désactivation de l'alarme")
		commandArray[DEVICE_ALARME]="Off"
		os.execute("echo 0 > " .. TMPDIR_COMPTEUR_OUT)
	end
	
	if(etat_peripheriques) then
		-- logAlarme("Remise à zéro du compte de l'alarme")
		os.execute("echo 0 > " .. TMPDIR_COMPTEUR_OUT)
	end	
end



-- Boucle principale
if( mac_adress_smartphones == nil ) then
	error("[ORANGE] La variable {mac_adress_smartphones} ne sont pas définies dans Domoticz")
	return 512
else
	-- logOrange("Test de présence des appareils d'adresses MAC (" .. mac_adress_smartphones .. ")")
	-- Recherche des périphériques connectés
	peripheriques_up = getPeripheriquesConnectes()
	
	-- Forcage si invité
	if(peripheriques_up == false and at_home_invite == "true") then
		logOrange("Invités à la maison. Présence forcée à active")
		peripheriques_up = true
	end
	-- Mise à jour de l'alarme
	updateAlarmeStatus(peripheriques_up)
end

return commandArray