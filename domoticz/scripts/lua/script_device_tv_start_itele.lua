#!/usr/bin/lua
commandArray = {}
if ( devicechanged['Freebox Player'] == 'On' ) then
	print("[TV] 	Démarrage de la télévision")
	-- Test de la variable
	freeboxCode = uservariables["freebox_code"]
	freeboxChannel = uservariables["freebox_channel"]
	scriptShDir = uservariables["script_sh_dir"]
	if( freeboxCode == nil or freeboxChannel == nil or scriptShDir == nil ) then
		print("[TV][ERREUR] Les variables {freebox_code} et {freebox_channel} ou {scriptShDir} ne sont pas définies dans Domoticz")
		return 512
	else
		scriptName = "script_commandes_tv_start_itele.sh"
		datelog=os.date("%a")
		print("[TV] 	Appel du script  " .. scriptShDir .. "/" .. scriptName .. " " .. freeboxCode .. " " .. freeboxChannel)
		os.execute("nohup sh " .. scriptShDir .. "/" .. scriptName .. " " .. freeboxCode .. " " .. freeboxChannel .. " >> " .. scriptShDir .. "/../logs/script_commandes_tv_start_itele_" .. datelog .. ".log &")
		print("[TV] Les logs sont dans logs/script_commandes_tv_start_itele_" .. datelog .. ".log")
	end	
end 
return commandArray