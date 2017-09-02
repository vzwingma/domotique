commandArray = {}
-- Liste des adresse MAC des smartphones sur la Freebox
mac_adress_smartphones=uservariables["mac_adress_smartphones"]

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'utils'
-- logOrange dans utils
-- URL des API
apiLiveBox="http://livebox.home"
apiDomoticz="http://localhost:8080/json.htm?"

-- 
local patternMacAdresses = string.format("([^%s]+)", ";")


-- Fonction de recherche des périphériques connectés
-- Connexion à la Livebox pour lister les périphériques
-- @param apiLiveBox : URL de l'API Livebox
-- @param mac_adress_smartphones: variable domoticz de la liste des adresses MAC à vérifier
-- @return périphériques connectés ?
function getPeripheriquesConnectes() 
	local TMP_PERIPHERIQUES = "/tmp/peripheriques.tmp"

	--  Appel sur la liste des périphériques
	logOrange("Recherche des connexions des périphériques sur la LiveBox Orange")
	local commandeurl="curl -X POST -H 'Cache-Control: no-cache' -d '' " .. apiLiveBox .. "/sysbus/Devices:get"
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
					logOrange("- [" .. peripherique.Name .. "] actif")
					local lastChanged = os.time() - convertStringUTCTimeToSeconds(peripherique.LastChanged)
					logOrange(" Dernière activité = " .. peripherique.LastChanged .. " :: " .. lastChanged .. "s");
					if(lastChanged > 600) then
						logOrange(" Dernière activité date d'il y a plus de 10 minutes. Le périphérique est considéré inactif")
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
	-- Mise à jour de l'alarme
	updateAlarmeStatus(peripheriques_up)
end

return commandArray