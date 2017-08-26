#!/usr/bin/lua
commandArray = {}

-- LOG
function log(message)
	print("[RADIO] " .. message)
end

-- Paramètres du script
telecommande_1="17337810"
telecommande_2="16679162"
gpio_pin="0"


-- Fonction de lecture du contenu d'un fichier
-- @param : chemin vers le fichier
-- @return le contenu du fichier
function readAll(file)
    local f = io.open(file, "rb")
	if(f == nil) then
		return ""
	else
		local content = f:read("*all")
		f:close()
		return content
	end
end


-- Fonction d'appel à l'API du conteneur Docker Radio
-- Pour lancer une commande : Curl
-- @param parametre : paramètre à envoyer sur la radio

function callApiDockerRadio(parametre)
	local TMP_RADIO = "/tmp/radio.tmp"

	local url="http://radio:9000/cmd"
	local json_body = "{"
	json_body = json_body .. '\"commande\" : \"radioEmission\",'
	json_body = json_body .. '\"params\" : [ "'.. gpio_pin ..'\", '.. parametre .. ']'
	json_body = json_body .. "}"
	log("Appel de la commande : ".. json_body)
	
	local fullcmd = "curl -H \"Content-Type: application/json\" -X POST -d '".. json_body .."' '".. url .."'";
	os.execute(fullcmd .. " > " .. TMP_RADIO)
	local resultat = JSON:decode(readAll(TMP_RADIO))
	if(resultat.erreur ~= nil) then
		error("[RADIO] Erreur lors de la commande : " .. resultat.erreur)
	else
		log("Résultat : "..resultat.resultat.gpio )
	end
end

-- Pause
-- @param tempo : tempo d'après la commande en seconde
function pause(tempo)
	if( tempo > 0 ) then
		log("  Tempo de " .. tempo .. " secondes")
		os.execute("sleep ".. tempo)
	end
end



-- Fonction principale
-- Détection des événements sur les interrupteurs dans domoticZ
-- Préparation des paramètres
-- log("Chargement de la librairie JSON")
JSON = (loadfile "/src/domoticz/scripts/lua/JSON.lua")() -- one-time load of the routines

--
if ( devicechanged['Interrupteur Salon'] == 'On' ) then
	log("Démarrage de la télévision")
	callApiDockerRadio("\"".. telecommande_1 .."\", \"1\", \"on\"")
	
elseif ( devicechanged['Interrupteur Salon'] == 'Off' ) then
	log("Arrêt de la télévision")
	callApiDockerRadio("\"".. telecommande_1 .."\", \"1\", \"off\"")
	
elseif ( devicechanged['Lampe 1'] == 'On' ) then
	log("Allumage de la lampe 1")
	callApiDockerRadio("\"".. telecommande_2.."\", \"1\", \"on\"")
	
elseif ( devicechanged['Lampe 1'] == 'Off' ) then
	log("Extinction de la lampe 1")
		callApiDockerRadio("\"".. telecommande_2 .."\", \"1\", \"off\"")
		
elseif ( devicechanged['Lampe 2'] == 'On'  ) then
	log("Allumage de la lampe 2")
		callApiDockerRadio("\"".. telecommande_2 .."\", \"2\", \"on\"")
		
elseif ( devicechanged['Lampe 2'] == 'Off') then
	log("Extinction de la lampe 2")
	callApiDockerRadio("\"".. telecommande_2 .."\", \"2\", \"off\"")
end 
return commandArray