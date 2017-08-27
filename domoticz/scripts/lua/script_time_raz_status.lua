commandArray = {}

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'utils'
-- logStatut dans utils
-- envoiSMS dans utils

-- Script permettant de remettre à zéro les statuts des interrupteurs
-- ou de forcer l'activation de scénarios afin de revenir dans un statut normal
now=os.date("%H:%M")
logStatut("Mise à zéro des statuts à " .. now)
	-- En soirée et alarme activée => Arrêt de tous les interrupteurs ssi c'est nécessaire
if( otherdevices['Alarme'] == 'On' and now == '00:00' and 
	(commandArray['Lampe 1'] == 'On' or commandArray['Lampe 1'] == 'On' or commandArray['Interrupteur Salon'] == 'On' or commandArray['Livebox Player'] == 'On')) then
	logStatut("Alarme activée - Arrêt global")
	envoiSMS("Alarme activée - Arrêt global")
	commandArray['Lampe 1'] = 'Off'
	commandArray['Lampe 2'] = 'Off'
	commandArray['Interrupteur Salon'] = 'Off'
	commandArray['Livebox Player'] = 'Off'
end
return commandArray