#!/usr/bin/lua
commandArray = {}

-- Variables
local id_dht11=uservariables["interrupteur_id_dht11"]
local APPLI_DIR="/home/pi/appli/receptionDHT11/receptionDHT11"

local SEUIL_DELTA=30
local dht11temp=0
local dht11hydro=0

-- LOG
function log(message)
	print("[DHT11] " .. message)
end

-- Fonction de lecture du contenu d'un fichier
-- @param : chemin vers le fichier
-- @return le contenu du fichier
function readLine(file)
    local f = io.open(file, "rb")
	if(f == nil) then
		return ""
	else
		local content = f:read("*all")
		-- log(content)
		f:close()
		return content
	end
end

-- Fonction de split 
-- @param inputstr : chaine à splitter
-- @param sep : séparateur
function splitString(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
				-- log(" Split [" .. i .. "] " .. str)
                i = i + 1
        end
        return t
end


-- Lecture depuis le DHT11
function readFromDHT11()
	local TMPDIR_DHT11 = "/tmp/dht11.tmp"
	log("Récupération des valeurs du DHT11")
	os.execute("sudo " .. APPLI_DIR .. " > " .. TMPDIR_DHT11)
	return splitString(readLine(TMPDIR_DHT11), '|')
end

-- Controle des données
function controlData(new_dht11hydro, new_dht11temp)

	local oldvalues = splitString(otherdevices_svalues["DHT11"], ";")
	local dht11_oldhydro = oldvalues[2]
	local dht11_oldtemp = oldvalues[1]
	log("Anciennes valeurs : Humidite = " .. dht11_oldhydro .. " %, Température = " .. dht11_oldtemp .. "°C")
	
	local deltaHydro = (new_dht11hydro - dht11_oldhydro)/dht11_oldhydro * 100
	local deltaTemp = (new_dht11temp - dht11_oldtemp)/dht11_oldtemp * 100
	
	log("Delta Temp " .. deltaTemp .. "% / Humidite " .. deltaHydro .. "%")
	
	if(new_dht11hydro < 0 or new_dht11hydro > 100) then
		error("[DHT11] La valeur d'humidité [" .. new_dht11hydro .. "] est incohérente. Annulation de la mesure")
		return nil
	end
	if(math.abs(deltaHydro) > SEUIL_DELTA) then	
		log("Le changement d'humidité [" .. deltaHydro .. "]% est incohérent (> " .. SEUIL_DELTA .. "%). Attention")
		if(deltaHydro > 0) then
			new_dht11hydro = dht11_oldhydro * ((100 + SEUIL_DELTA) / 100)
		else
			new_dht11hydro = dht11_oldhydro * ((100 - SEUIL_DELTA) / 100)
		end
		log("Réajustement de la valeur d'humidité à " .. new_dht11hydro .. "%")
	end
	if(new_dht11temp < 0 or new_dht11temp > 40) then
		error("[DHT11] La valeur de température [" .. new_dht11temp .. "] est incohérente. Annulation de la mesure")
		return nil
	end
	if(math.abs(deltaTemp) > SEUIL_DELTA) then
		log("[DHT11] Le changement de température [" .. deltaTemp .. "]% est incohérent (> " .. SEUIL_DELTA .. "%). Attention")
		if(deltaTemp > 0) then
			new_dht11temp = dht11_oldtemp * ((100 + SEUIL_DELTA) / 100)
		else
			new_dht11temp = dht11_oldtemp * ((100 - SEUIL_DELTA) / 100)
		end
		log("Réajustement de la valeur de température à " .. new_dht11temp .. "°C")
	end
	return id_dht11 .. "|0|" .. new_dht11temp .. ";" .. new_dht11hydro .. ";1"
end


-- Boucle principale
if( id_dht11 == nil ) then
	error("[DHT11] La variable {interrupteur_id_dht11} n'est pas définie dans Domoticz")
	return 512
else
	local dht11Values = readFromDHT11()
	dht11temp=dht11Values[2] / 10	
	dht11hydro=dht11Values[3] / 10
	log("                    Humidite = " .. dht11hydro .. " %, Température = " .. dht11temp .. "°C")
	
	commandeTH=controlData(dht11hydro, dht11temp)
	if(commandeTH ~= nil) then
		-- commande de mise à jour vers Domoticz
		log("Commande : " .. commandeTH)
		commandArray['UpdateDevice']=commandeTH
	end
end
return commandArray