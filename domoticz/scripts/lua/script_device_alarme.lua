#!/usr/bin/lua
commandArray = {}

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'utils'
-- LOG dans utils
-- envoiNotifSlack dans utils

now=os.date("%H%M")
if ( devicechanged[DEVICE_ALARME] == 'On' ) then

	logAlarme("Activation de l'alarme")
	envoiNotifSlack("Alarme activée")
	commandArray[SCENE_ALARME] = 'On'

	-- Désactivation de l'alarme 
elseif ( devicechanged[DEVICE_ALARME] == 'Off' ) then
	logAlarme("Désactivation de l'alarme")
	-- En journée : Allumage de la télévision et la lampe 1
	if( now <= "2230" and now >= "0700" ) then
		envoiNotifSlack("Alarme désactivée - Bonjour")
		commandArray[SCENE_TV] = 'On'
	else
		-- En soirée : Bonne nuit
		envoiNotifSlack("Alarme désactivée - Bonne nuit")
		commandArray[SCENE_NUIT] = 'On'
	end
end

if ( devicechanged[DEVICE_ALARME] or devicechanged[DEVICE_PIR] ) then
	logAlarme("Statut de l'alarme		" .. otherdevices[DEVICE_ALARME])
	logAlarme("Statut du détecteur de présence	" .. otherdevices[DEVICE_PIR])
	
	if( otherdevices[DEVICE_ALARME] == 'On' and otherdevices[DEVICE_PIR] == 'On' ) then
		logAlarme("[ALERTE] Présence de quelqu'un alors que l'alarme est activée")
		envoiNotifSlack("ALERTE INTRUSION")
	end
end

return commandArray