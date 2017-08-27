#!/usr/bin/lua
commandArray = {}
-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'utils'
-- logDHT11 dans utils
-- Variables
local id_dht11=uservariables["interrupteur_id_dht11"]
local url="http://dht11:9000/cmd/recepteurDHT11"
local SEUIL_DELTA=30
local dht11temp=0
local dht11hydro=0


-- Controle des données
function controlData(new_dht11hydro, new_dht11temp)

	-- logDHT11("Anciennes valeurs " .. otherdevices_svalues["DHT11"])

	local oldvalues = splitString(otherdevices_svalues["DHT11"], ";")
	local dht11_oldhydro = oldvalues[2]
	local dht11_oldtemp = oldvalues[1]
	-- logDHT11("Anciennes valeurs : Humidite = " .. dht11_oldhydro .. " %, Température = " .. dht11_oldtemp .. "°C")
	
	local deltaHydro = (new_dht11hydro - dht11_oldhydro)/dht11_oldhydro * 100
	local deltaTemp = (new_dht11temp - dht11_oldtemp)/dht11_oldtemp * 100
	
	logDHT11("Delta Temp " .. deltaTemp .. "% / Humidite " .. deltaHydro .. "%")
	
	if(new_dht11hydro < 0 or new_dht11hydro > 100) then
		error("[DHT11] La valeur d'humidité [" .. new_dht11hydro .. "] est incohérente. Annulation de la mesure")
		return nil
	end
	if(math.abs(deltaHydro) > SEUIL_DELTA) then	
		logDHT11("Le changement d'humidité [" .. deltaHydro .. "]% est incohérent (> " .. SEUIL_DELTA .. "%). Attention")
		if(deltaHydro > 0) then
			new_dht11hydro = dht11_oldhydro * ((100 + SEUIL_DELTA) / 100)
		else
			new_dht11hydro = dht11_oldhydro * ((100 - SEUIL_DELTA) / 100)
		end
		logDHT11("Réajustement de la valeur d'humidité à " .. new_dht11hydro .. "%")
	end
	if(new_dht11temp < 0 or new_dht11temp > 40) then
		error("[DHT11] La valeur de température [" .. new_dht11temp .. "] est incohérente. Annulation de la mesure")
		return nil
	end
	if(math.abs(deltaTemp) > SEUIL_DELTA) then
		logDHT11("[DHT11] Le changement de température [" .. deltaTemp .. "]% est incohérent (> " .. SEUIL_DELTA .. "%). Attention")
		if(deltaTemp > 0) then
			new_dht11temp = dht11_oldtemp * ((100 + SEUIL_DELTA) / 100)
		else
			new_dht11temp = dht11_oldtemp * ((100 - SEUIL_DELTA) / 100)
		end
		logDHT11("Réajustement de la valeur de température à " .. new_dht11temp .. "°C")
	end
	return id_dht11 .. "|0|" .. new_dht11temp .. ";" .. new_dht11hydro .. ";1"
end


-- Boucle principale
if( id_dht11 == nil ) then
	error("[DHT11] La variable {interrupteur_id_dht11} n'est pas définie dans Domoticz")
	return 512
else
	local dht11Values = apiCallGetReadJSON(url)
	if( id_dht11 ~= nil and dht11Values ~= nil) then
		dht11temp=dht11Values.temperature
		dht11hydro=dht11Values.humidite
		logDHT11("                    Humidite = " .. dht11hydro .. " %, Température = " .. dht11temp .. "°C")
		
		commandeTH=controlData(dht11hydro, dht11temp)
		if(commandeTH ~= nil) then
			-- commande de mise à jour vers Domoticz
			-- logDHT11("Commande : " .. commandeTH)
			commandArray['UpdateDevice']=commandeTH
		else
			logDHT11("Pas de mise à jour de la température")
		end
	else
		error("[DHT11] Erreur lors de la lecture de DHT11")
	end
end
return commandArray