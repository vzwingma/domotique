commandArray = {}
if ( devicechanged['Freebox Player'] == 'On' ) then
	print("*	Démarrage de la télévision	*")
	-- Test de la variable
	freeboxCode = uservariables["freebox_code"]
	freeboxChannel = uservariables["freebox_channel"]
	if( freeboxCode == nil or freeboxChannel == nil ) then
		print("[TV][ERREUR] Les variables {freebox_code} et {freebox_channel} ne sont pas définies dans Domoticz")
		return 512
	else
		print("[TV] 	Appel du script  ~/appli/domoticz/scripts/bash/script_commandes_tv_start_itele.sh " .. freeboxCode .. " " .. freeboxChannel)
	end	
end 
return commandArray