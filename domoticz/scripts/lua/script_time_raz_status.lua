commandArray = {}

-- LOG
function log(message)
	print("[STATUS] " .. message)
end


-- Fonction d'envoi de SMS via l'API Freebox mobile
function envoiSMS (message)

	local freeboxSMSUser = uservariables["free_sms_user"]
	local freeboxSMSPass = uservariables["free_sms_pass"]

	if( freeboxSMSUser == nil or freeboxSMSPass == nil) then
		error("[STATUS] ERREUR les variables [free_sms_user] [free_sms_pass] ne sont pas toutes définies dans Domoticz. Impossible d'envoyer de SMS")
		return 512
	else
		log("Envoi du sms '" .. message .. "' avec le user " .. freeboxSMSUser)
		datelog=os.date("%a")
		
		freeboxSMS_API_URL = "https://smsapi.free-mobile.fr/sendmsg?"
		os.execute("curl '".. freeboxSMS_API_URL .. "user=" .. freeboxSMSUser .. "&pass=" .. freeboxSMSPass .. "&msg=" .. message .. "'")
	end
end



-- Script permettant de remettre à zéro les statuts des interrupteurs
-- ou de forcer l'activation de scénarios afin de revenir dans un statut normal
now=os.date("%H:%M")
log("Mise à zéro des statuts à " .. now)
	-- En soirée et alarme activée => Arrêt de tous les interrupteurs ssi c'est nécessaire
if( otherdevices['Alarme'] == 'On' and now == '00:00' and 
	(commandArray['Lampe 1'] == 'On' or commandArray['Lampe 1'] == 'On' or commandArray['Interrupteur Salon'] == 'On' or commandArray['Livebox Player'] == 'On')) then
	log("Alarme activée - Arrêt global")
	envoiSMS("Alarme activée - Arrêt global")
	commandArray['Lampe 1'] = 'Off'
	commandArray['Lampe 2'] = 'Off'
	commandArray['Lampe 2'] = 'Off'
	commandArray['Livebox Player'] = 'Off'
end
return commandArray