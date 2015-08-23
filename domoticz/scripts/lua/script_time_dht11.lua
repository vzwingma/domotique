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
		log(content)
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



-- Boucle principale
if( id_dht11 == nil ) then
	error("[DHT11] La variable {interrupteur_id_dht11} n'est pas définie dans Domoticz")
	return 512
else
	local dht11Values = readFromDHT11()
	dht11temp=dht11Values[2] / 10
	dht11hydro=dht11Values[3] / 10
	-- commande de mise à jour vers Domoticz
	commandeTH=id_dht11 .. "|0|" .. dht11temp .. ";" .. dht11hydro .. ";1"
	commandArray['UpdateDevice']=commandeTH
end
return commandArray