commandArray = {}
-- print("[FREEBOX] Statuts des périphériques réseau Freebox")

freebox_apptoken=uservariables["freebox_apptoken"]
freebox_apptoken=freebox_apptoken:gsub("index.html", "")

freebox_appid=uservariables["freebox_appid"]
freebox_id_Smartphone_V=uservariables["freebox_id_Smartphone_V"]
freebox_id_Smartphone_S=uservariables["freebox_id_Smartphone_S"]

-- URL des API
apiFreeboxv3="http://mafreebox.freebox.fr/api/v3"
apiDomoticz="http://localhost:8080/json.htm?"
-- Session Token
session_token=""

-- LOG
function log(message)
	print("[FREEBOX] " .. message)
end

function logAlarme(message)
	print("[ALARME] " .. message)
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


-- Fonction de la connexion à la Freebox
-- Authentification pour récupérer le tokenDeSession
function connectToFreebox()
	-- log ("Connexion à la Freebox")
	local TMPDIR_CHALLENGE = "/tmp/challenge.tmp"
	local TMPDIR_APPTOKEN =  "/tmp/apptoken.tmp"
	local TMPDIR_SESSIONTOKEN =  "/tmp/sessiontoken.tmp"
	
	-- CHALLENGE : Appel de login pour charger le challenge
	os.execute("curl -s " .. apiFreeboxv3 .. "/login > " .. TMPDIR_CHALLENGE)
	local json_challenge = JSON:decode(readAll(TMPDIR_CHALLENGE))
	local challenge = json_challenge.result.challenge
	-- log("  Challenge : " .. challenge)

	-- APP  TOKEN : Calcul du mot de passe
	-- log("Calcul HMAC SHA1")
	-- log("  AppToken : " .. freebox_apptoken)
	os.execute("echo -n " .. challenge .. " | openssl dgst -sha1 -hmac " .. freebox_apptoken .. " | cut -c10-200 > " .. TMPDIR_APPTOKEN)
	local password = readAll(TMPDIR_APPTOKEN)
	password=password:gsub("\n", "")
	-- log("  Password : " .. password)
	
	-- CONNEXION Session Connect
	local table_app_session = {}
	table_app_session["app_id"]=freebox_appid
	table_app_session["password"]=password
	local json_app_session = JSON:encode_pretty(table_app_session)
	--	connexion à la session
	os.execute("curl -s -H \"Content-Type: application/json\" -X POST -d '" .. json_app_session .. "' " .. apiFreeboxv3 .. "/login/session/ > " .. TMPDIR_SESSIONTOKEN)
	local json_session_token = JSON:decode(readAll(TMPDIR_SESSIONTOKEN))
	session_token=json_session_token.result.session_token
	-- log("  Session Token : " .. session_token)
end

-- Fonction de la deconnexion à la Freebox
function disconnectToFreebox()
	local TMPDIR_DISCONNECT = "/tmp/challenge.tmp"
	os.execute("curl -s -H \"X-Fbx-App-Auth: " .. session_token .. "\" -X POST " .. apiFreeboxv3 .. "/login/logout > " .. TMPDIR_DISCONNECT)
	local disconnect = readAll(TMPDIR_DISCONNECT)
	log("  Deconnexion Freebox API : " .. disconnect)
end
-- Fonction de recherche des périphériques connectés
-- Connexion à lan/browser/pub/ pour lister les périphériques
-- @param session_token : token de session Freebox
-- @param : freebox_id_Smartphone_V : id du smartphone dans la freebox
-- @param : freebox_id_Smartphone_S : id du smartphone dans la freebox
-- @return périphériques connectés ?
function getPeripheriquesConnectes() 

	local TMP_PERIPHERIQUES = "/tmp/peripheriques.tmp"

	--  Appel sur la liste des périphériques
	log("Recherche des périphériques connus de la Freebox")
	local commandeurl="curl -s -H \"Content-Type: application/json\" -H \"X-Fbx-App-Auth: " .. session_token .. "\" -X GET " .. apiFreeboxv3 .. "/lan/browser/pub/"
	os.execute(commandeurl .. " > " .. TMP_PERIPHERIQUES)
	local json_peripheriques = JSON:decode(readAll(TMP_PERIPHERIQUES))
	-- Liste des périphériques
	for index, peripherique in pairs(json_peripheriques.result) do
	
		if(freebox_id_Smartphone_V == peripherique.id or freebox_id_Smartphone_S == peripherique.id)
		then
			log("Calcul du statut du périphérique " .. peripherique.id)
			log("   Actif   : " .. tostring(peripherique.active) .. ", Présent : " .. tostring(peripherique.reachable))
			if(peripherique.active and peripherique.reachable) then
				etatSmartphone = true
			end
		end
	end
	return etatSmartphone
end



-- Mise à jour de l'alarme suivant le statut des périphériques
-- @param : état des périphériques
function updateAlarmeStatus(etat_peripheriques)
	local etatActuelAlarme=otherdevices['Alarme']
	local SEUIL_ALARME = 5
	local TMPDIR_COMPTEUR_OUT = "/tmp/compteur_smartphone_out.tmp"
	-- Activation de l'alarme au bout de 5 min

	if(not etat_peripheriques and etatActuelAlarme == "Off") then
		compteurOff=readAll(TMPDIR_COMPTEUR_OUT)
		if(compteurOff == "") then
			compteurOff = 0
		end
		compteurOff = compteurOff + 1
		logAlarme("  > Compteur de mise en alarme = " .. compteurOff .. " / " .. SEUIL_ALARME)
		if(compteurOff >= SEUIL_ALARME) then
			logAlarme("Activation de l'alarme")
			commandArray['Alarme']="On"
			compteurOff = 0
		end
		os.execute("echo " .. compteurOff .. " > " .. TMPDIR_COMPTEUR_OUT)
	elseif(etat_peripheriques and etatActuelAlarme == "On") then
		-- Désactivation immédiate
		logAlarme("Désactivation de l'alarme")
		commandArray['Alarme']="Off"
		os.execute("echo 0 > " .. TMPDIR_COMPTEUR_OUT)
	end
	
	if(etat_peripheriques) then
		-- logAlarme("Remise à zéro du compte de l'alarme")
		os.execute("echo 0 > " .. TMPDIR_COMPTEUR_OUT)
	end	
end



-- Boucle principale
if( freebox_apptoken == nil or freebox_appid == nil or freebox_id_Smartphone_V == nil or freebox_id_Smartphone_S == nil ) then
	error("[FREEBOX] Les variables {freebox_apptoken}, {freebox_appid}, {freebox_id_Smartphone_V}, {freebox_id_Smartphone_S} ne sont pas définies dans Domoticz")
	return 512
else
	log("Test de présence des smartphones (" .. uservariables["freebox_id_Smartphone_V"] .. ") & (" .. uservariables["freebox_id_Smartphone_S"] .. ")")

	-- log("Chargement de la librairie JSON")
	JSON = (loadfile "/home/pi/appli/domoticz/scripts/lua/JSON.lua")() -- one-time load of the routines

	-- Connexion à la Freebox
	connectToFreebox()
	-- Recherche des périphériques connectés
	peripheriques_up = getPeripheriquesConnectes()
	-- Mise à jour de l'alarme
	updateAlarmeStatus(peripheriques_up)
	-- Déconnexion à la Freebox
	disconnectToFreebox()
end

return commandArray