#!/usr/bin/lua
commandArray = {}

-- LOG
function log(modul, message)
	print("[".. modul .."] " .. message)
end
function logTV(message)
	log("TV", message)
end
function logRadio(message)
	log("RADIO", message)
end
function logAlarme(message)
	log("ALARME", message)
end
function logDHT11(message)
	log("DHT11", message)
end
function logOrange(message)
	log("ORANGE", message)
end
function logStatut(message)
	log("STATUT", message)
end
function logReveil(message)
	log("REVEIL", message)
end

-- Variable
DEVICE_BOX='Livebox Player'
DEVICE_LAMPE1='Lampe 1'
DEVICE_LAMPE2='Lampe 2'
DEVICE_TELE='Interrupteur Salon'
DEVICE_ALARME='Alarme'
DEVICE_PIR='Capteur PIR'

SCENE_MATIN='Scene:Bon matin'
SCENE_NUIT='Scene:Bonne nuit'
SCENE_ALARME='Scene:Alarme On'
SCENE_TV='Scene:Télévision'

-- Pause
-- @param tempo : tempo d'après la commande en seconde
function pause(tempo)
	if( tempo > 0 ) then
		log("-", "  Tempo de " .. tempo .. " secondes")
		os.execute("sleep ".. tempo)
	end
end

-- #################################################
-- ## ENVOI DE SMS
-- #################################################
-- Fonction d'envoi de SMS via l'API Freebox mobile
function envoiSMS (message)

	local freeboxSMSUser = uservariables["free_sms_user"]
	local freeboxSMSPass = uservariables["free_sms_pass"]

	if( freeboxSMSUser == nil or freeboxSMSPass == nil) then
		error("[ALARME] ERREUR les variables [free_sms_user] [free_sms_pass] ne sont pas toutes définies dans Domoticz. Impossible d'envoyer de SMS")
		return 512
	else
		log("SMS", "Envoi du sms '" .. message .. "' avec le user " .. freeboxSMSUser)
		freeboxSMS_API_URL = "https://smsapi.free-mobile.fr/sendmsg?"
		local commandeSMS = freeboxSMS_API_URL .. "user=" .. freeboxSMSUser .. "&pass=" .. freeboxSMSPass .. "&msg=" .. message
		return apiCallGetReadRaw(commandeSMS)
	end
end


-- #################################################
-- ## COMMANDES d'API
-- #################################################
-- Appel d'API POST et Retour JSON
-- @url : URL d'appel
-- @json_body : Body en JSON
-- @return : Json
function apiCallPOSTReadJSON(url, json_body)
	local TMP_CALL = "/tmp/api_call.tmp"
	local fullcmd = "curl -H \"Content-Type: application/json\" -H 'Cache-Control: no-cache' -X POST -d '".. json_body .."' '".. url .."'";
	-- log("API", "Appel de [".. fullcmd .. "]")
	os.execute(fullcmd .. " > " .. TMP_CALL)
	local resultat = readAll(TMP_CALL)
	-- log("API", "> [".. resultat .. "]")
	return JSON:decode(resultat)
end

-- Appel d'API GET et Retour RAW
-- @url : URL d'appel
-- @return : réponse raw
function apiCallGetReadRaw(url)
	local TMP_CALL = "/tmp/api_get.tmp"
	local fullcmd = "curl -H \"Content-Type: application/json\" -X GET '".. url .."'";
	-- log("API", "Appel de [".. fullcmd .. "]")
	os.execute(fullcmd .. " > " .. TMP_CALL)
	local resultat = readAll(TMP_CALL)
	-- log("API", "> [".. resultat .. "]")
	return resultat
end
-- Appel d'API GET et Retour JSON
-- @url : URL d'appel
-- @return : réponse JSON
function apiCallGetReadJSON(url)
	return JSON:decode(apiCallGetReadRaw(url))
end


-- #################################################
-- ## UTILITAIRES FICHIER / STRING
-- #################################################

function convertStringUTCTimeToSeconds(dateString)
	local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)Z"
	local xyear, xmonth, xday, xhour, xminute, xseconds = dateString:match(pattern)
	-- Le parsing est en heure locale. AJout de la différence avec UTC
	local convertedTimestamp = os.time({year = xyear, month = xmonth, day = xday, hour = xhour, min = xminute, sec = xseconds})
	local tzInSec = get_timezone()
	-- log("DATE", "".. dateString.."->" ..convertedTimestamp.."s + " .. tzInSec .. "s")
	return convertedTimestamp + tzInSec
end

function get_timezone()
	local now = os.time()
	local utcdate   = os.date("!*t", now)
	local localdate = os.date("*t", now)
	localdate.isdst = false -- this is the trick
	return os.difftime(os.time(localdate), os.time(utcdate))
end

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
		-- logDHT11(" Split [" .. i .. "] " .. str)
		i = i + 1
	end
	return t
end


-- log("-", "Chargement de la librairie JSON")
JSON = (loadfile "/src/domoticz/scripts/lua/modules/JSON.lua")() -- one-time load of the routines
