#!/usr/bin/lua
commandArray = {}

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'utils'
-- LOG dans utils
-- envoiSMS dans utils

now=os.date("%H%M")
if ( devicechanged['Alarme'] == 'On' ) then

	logAlarme("Activation de l'alarme")
	envoiSMS("Alarme activée")
	commandArray['Scene:Alarme On'] = 'On'

	-- Désactivation de l'alarme 
elseif ( devicechanged['Alarme'] == 'Off' ) then
	logAlarme("Désactivation de l'alarme")
	-- En journée : Allumage de la télévision et la lampe 1
	if( now <= "2230" and now >= "0700" ) then
		envoiSMS("Alarme désactivée - Bonjour")
		commandArray['Scene:Télévision'] = 'On'
		commandArray['Lampe 1'] = 'On'
	else
		-- En soirée : Bonne nuit
		envoiSMS("Alarme désactivée - Bonne nuit")
		commandArray['Scene:Bonne nuit'] = 'On'
	end
end

if ( devicechanged['Alarme'] or devicechanged['Capteur PIR'] ) then
	logAlarme("Statut de l'alarme		" .. otherdevices['Alarme'])
	logAlarme("Statut du détecteur de présence	" .. otherdevices['Capteur PIR'])
	
	if( otherdevices['Alarme'] == 'On' and otherdevices['Capteur PIR'] == 'On' ) then
		logAlarme("[ALERTE] Présence de quelqu'un alors que l'alarme est activée")
		envoiSMS("ALERTE INTRUSION")
	end
end

return commandArray