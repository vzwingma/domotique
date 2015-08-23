#!/usr/bin/lua
commandArray = {}

-- Variables
id_dht11=uservariables["interrupteur_id_dht11"]
APPLI_DIR="/home/pi/appli/receptionDHT11/receptionDHT11"


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
		local content = f:read("*line")
		f:close()
		return content
	end
end


-- Lecture depuis le DHT11
function readFromDHT11()
	local TMPDIR_DHT11 = "/tmp/dht11.tmp"
	log("Récupération des valeurs du DHT11")
	os.execute("sudo " .. APPLI_DIR .. " > " .. TMPDIR_DHT11)
	local readDHT11Values = readLine(TMPDIR_DHT11)
	log(">" .. readDHT11Values)
	
end



-- Boucle principale
if( id_dht11 == nil ) then
	error("[DHT11] La variable {interrupteur_id_dht11} n'est pas définie dans Domoticz")
	return 512
else
	readFromDHT11()
	
	dht11temp=12
	dht11hydro=123
	-- commande de mise à jour vers Domoticz
	commandeTH=id_dht11 .. "|0|" .. dht11temp .. ";" .. dht11hydro .. ";1"
	commandArray['UpdateDevice']=commandeTH
end
return commandArray