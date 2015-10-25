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
-- Arrêt de lampe chambre à 00:00 et 06:00 
if( otherdevices['Lampe Chambre'] == 'On'  and (now == '00:00' or now == '06:00')) then
	log("Forçage OFF de la lampe chambre")
	envoiSMS("Forçage OFF de la lampe chambre")
	commandArray['Lampe Chambre'] = 'Off'
end
-- Arrêt de lampe chambre à 00:00 et 06:00 
if( otherdevices['Interrupteur Cuisine'] == 'On'  and (now == '00:00' or now == '06:00')) then
	log("Forçage OFF de l'interrupteur cuisine")
	envoiSMS("Forçage OFF de l'interrupteur cuisine")
	commandArray['Interrupteur Cuisine'] = 'Off'
end
	-- En soirée et alarme activée => Arrêt de tous les interrupteurs ssi c'est nécessaire
if( otherdevices['Alarme'] == 'On' and now == '00:00' and 
	(commandArray['Lampe Chambre'] == 'On' or commandArray['Interrupteur Cuisine'] == 'On' or commandArray['Interrupteur Salon'] == 'On')) then
	log("Alarme activée - Arrêt global")
	envoiSMS("Alarme activée - Arrêt global")
	commandArray['Lampe Chambre'] = 'Off'
	commandArray['Interrupteur Cuisine'] = 'Off'
	commandArray['Interrupteur Salon'] = 'Off'
end
return commandArray