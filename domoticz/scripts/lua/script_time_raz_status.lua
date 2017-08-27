#!/usr/bin/lua
commandArray = {}

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'utils'
require 'livebox_tele'
-- logStatut dans utils
-- envoiSMS dans utils
-- getStatutTV dans utils

-- Mise à jour du statut de la TV
function updateStatutTV()
	-- Calcul Statut
	local statutTV = getStatutTV()
	if(statutTV and otherdevices[DEVICE_BOX] == 'Off') then
		logStatut("Mise à jour du statut de la TV à " .. statutTV)
		-- commandArray[DEVICE_BOX] = 'On'
	elseif(!statutTV and otherdevices[DEVICE_BOX] == 'On') then
		logStatut("Mise à jour du statut de la TV à " .. statutTV)
		-- commandArray[DEVICE_BOX] = 'Off'
	end
end

-- Rmettre à zéro les statuts des interrupteurs
-- ou de forcer l'activation de scénarios afin de revenir dans un statut normal
function updateStatutAlarme()
	-- En soirée et alarme activée => Arrêt de tous les interrupteurs ssi c'est nécessaire
	if( otherdevices[DEVICE_ALARME] == 'On' and now == '00:00' and 
		(commandArray[DEVICE_LAMPE1] == 'On' or commandArray[DEVICE_LAMPE1] == 'On' or commandArray[DEVICE_TELE] == 'On' or commandArray[DEVICE_BOX] == 'On')) then
		logStatut("Alarme activée - Arrêt global")
		envoiSMS("Alarme activée - Arrêt global")
		commandArray[DEVICE_LAMPE1] = 'Off'
		commandArray[DEVICE_LAMPE2] = 'Off'
		commandArray[DEVICE_TELE] = 'Off'
		commandArray[DEVICE_BOX] = 'Off'
	end
end 



-- Boucle principale
now=os.date("%H:%M")
logStatut("Mise à zéro des statuts à " .. now)
-- Statut TV
updateStatutTV
-- Statut Alarme
updateStatutAlarme

return commandArray