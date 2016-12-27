#!/usr/bin/lua
commandArray = {}

-- LOG
function log(message)
	print("[ALARME] " .. message)
end

-- Fonction d'envoi de SMS via l'API Freebox mobile
function envoiSMS (message)

	local freeboxSMSUser = uservariables["free_sms_user"]
	local freeboxSMSPass = uservariables["free_sms_pass"]

	if( freeboxSMSUser == nil or freeboxSMSPass == nil) then
		error("[ALARME] ERREUR les variables [free_sms_user] [free_sms_pass] ne sont pas toutes définies dans Domoticz. Impossible d'envoyer de SMS")
		return 512
	else
		log("Envoi du sms '" .. message .. "' avec le user " .. freeboxSMSUser)
		datelog=os.date("%a")
		
		freeboxSMS_API_URL = "https://smsapi.free-mobile.fr/sendmsg?"
		local commandeSMS = "curl '".. freeboxSMS_API_URL .. "user=" .. freeboxSMSUser .. "&pass=" .. freeboxSMSPass .. "&msg=" .. message .. "'"
		log(""..commandeSMS)
		os.execute(commandeSMS)
	end
end



-- print("[ALARME] Vérification du statut de l'alarme")
now=os.date("%H%M")
if ( devicechanged['Alarme'] == 'On' ) then

	log("Activation de l'alarme")
	envoiSMS("Alarme activée")
	commandArray['Lampe 1'] = 'Off'
	commandArray['Lampe 2'] = 'Off'
	commandArray['Scene:Arrêter télévision'] = 'On'

	-- Désactivation de l'alarme 
elseif ( devicechanged['Alarme'] == 'Off' ) then
	log("Désactivation de l'alarme")
	-- En journée : Allumage de la télévision et la lampe 1
	if( now <= "2230" and now >= "0700" ) then
		envoiSMS("Alarme désactivée - Bonjour")
		commandArray['Scene:Démarrer télévision'] = 'On'
		commandArray['Lampe 1'] = 'On'
	else
		-- En soirée : Bonne nuit
		envoiSMS("Alarme désactivée - Bonne nuit")
		commandArray['Scene:Bonne nuit'] = 'On'
	end
end

if ( devicechanged['Alarme'] or devicechanged['Capteur PIR'] ) then
	log("Statut de l'alarme		" .. otherdevices['Alarme'])
	log("Statut du détecteur de présence	" .. otherdevices['Capteur PIR'])
	
	if( otherdevices['Alarme'] == 'On' and otherdevices['Capteur PIR'] == 'On' ) then
		log("[ALERTE] Présence de quelqu'un alors que l'alarme est activée")
		envoiSMS("ALERTE INTRUSION")
	end
end

return commandArray