#!/usr/bin/lua
commandArray = {}

freeboxSMSUser = uservariables["free_sms_user"]
freeboxSMSPass = uservariables["free_sms_pass"]
scriptShDir = uservariables["script_sh_dir"]

-- Fonction d'envoi de SMS via l'API Freebox mobile
function envoiSMS (message)
	print("[ALARME] Envoi du sms '" .. message .. "' avec le user " .. freeboxSMSUser)
	datelog=os.date("%a")
	
	freeboxSMS_API_URL = "https://smsapi.free-mobile.fr/sendmsg?"
    os.execute("curl '".. freeboxSMS_API_URL .. "user=" .. freeboxSMSUser .. "&pass=" .. freeboxSMSPass .. "&msg=" .. message .. "' >> " .. scriptShDir .. "/../logs/script_device_alarme_" .. datelog .. ".log")
end



-- print("[ALARME] Vérification du statut de l'alarme")
-- Activation de l'alarme : Arrêt de la tv & lampe
if ( devicechanged['Alarme'] == 'On' ) then

	print("[ALARME] Activation de l'alarme")
	envoiSMS("Alarme activée")
	commandArray['Lampe Chambre'] = 'Off'
	commandArray['Scene:Arrêter télévision'] = 'On'

	-- Désactivation de l'alarme 
elseif ( devicechanged['Alarme'] == 'Off' ) then
	print("[ALARME] Désactivation de l'alarme")
	now=os.date("%H%M")
	-- En journée : Allumage de la télévision
	if( now <= "2230" ) then
		envoiSMS("Alarme désactivée - Bonjour")
		commandArray['Scene:Démarrer télévision'] = 'On'
	else
		-- En soirée : Bonne nuit
		envoiSMS("Alarme désactivée - Bonne nuit")
		commandArray['Scene:Bonne nuit'] = 'On'
	end
end
return commandArray