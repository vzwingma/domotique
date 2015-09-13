#!/usr/bin/lua
commandArray = {}

-- Variables
local id_dht11=uservariables["interrupteur_id_dht11"]
local APPLI_DIR="/home/pi/appli/receptionDHT11/receptionDHT11"

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
function controlData(dht11hydro, dht11temp)

	local oldvalues = splitString(otherdevices_svalues["DHT11"], ";")
	local dht11_oldhydro = oldvalues[2]
	local dht11_oldtemp = oldvalues[1]
	log("Anciennes valeurs : Humidite = " .. dht11_oldhydro .. " %, Température = " .. dht11_oldtemp .. "°C")
	
	local deltaHydro = (dht11hydro - dht11_oldhydro)/dht11_oldhydro * 100
	local deltaTemp = (dht11temp - dht11_oldtemp)/dht11_oldtemp * 100
	
	log("Delta Temp " .. deltaTemp .. "% / Humidite " .. deltaHydro .. "%")
	
	if(dht11hydro < 0 or dht11hydro > 100) then
		error("[DHT11] La valeur d'humidité [" .. dht11hydro .. "] est incohérente. Annulation de la mesure")
		return false
	end
	if(math.abs(deltaHydro) > 30) then
		error("[DHT11] Le changement d'humidité [" .. deltaHydro .. "]% est incohérent (> 30%). Attention")
		return true
	end
	if(dht11temp < 0 or dht11temp > 40) then
		error("[DHT11] La valeur de température [" .. dht11temp .. "] est incohérente. Annulation de la mesure")
		return false
	end
	if(math.abs(deltaTemp) > 30) then
		error("[DHT11] Le changement de températeur[" .. deltaTemp .. "]% est incohérent (> 30%). Attention")
		return true
	end
	return true
end


-- Boucle principale
if( id_dht11 == nil ) then
	error("[DHT11] La variable {interrupteur_id_dht11} n'est pas définie dans Domoticz")
	return 512
else
	local dht11Values = readFromDHT11()
	local dht11temp=dht11Values[2] / 10
	local dht11hydro=dht11Values[3] / 10
	log("                    Humidite = " .. dht11hydro .. " %, Température = " .. dht11temp .. "°C")
	if(controlData(dht11hydro, dht11temp)) then
		-- commande de mise à jour vers Domoticz
		commandeTH=id_dht11 .. "|0|" .. dht11temp .. ";" .. dht11hydro .. ";1"
		commandArray['UpdateDevice']=commandeTH
	end
end
return commandArray