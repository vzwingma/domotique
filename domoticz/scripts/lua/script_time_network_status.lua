commandArray = {}
print("[FREEBOX] Statuts des périphériques réseau Freebox")

scriptShDir = uservariables["script_sh_dir"]

freebox_apptoken=uservariables["freebox_apptoken"]
freebox_appid=uservariables["freebox_appid"]
freebox_id_Smartphone_V=uservariables["freebox_id_Smartphone_V"]
freebox_id_Smartphone_S=uservariables["freebox_id_Smartphone_S"]
interrupteur_id_alarme=uservariables["interrupteur_id_alarme"]
domoticz_basic_auth=uservariables["domoticz_basic_auth"]

if( freebox_apptoken == nil or freebox_appid == nil or freebox_id_Smartphone_V == nil or freebox_id_Smartphone_S == nil or interrupteur_id_alarme == nil or domoticz_basic_auth == nil) then
	print("[TV][ERREUR] Les variables {domoticz_basic_auth}, {freebox_apptoken}, {freebox_appid}, {freebox_id_Smartphone_V}, {freebox_id_Smartphone_S}, {interrupteur_id_alarme} ne sont pas définies dans Domoticz")
	return 512
else
	print("[FREEBOX] Test de présence des smartphones (" .. uservariables["freebox_id_Smartphone_V"] .. ") & (" .. uservariables["freebox_id_Smartphone_S"] .. ")")

	scriptName="script_commandes_freebox_network_status.sh"
	print("[FREEBOX] Appel du script " .. scriptName .. " \"" .. freebox_appid .. "\" \"###APPTOKEN###\" " .. freebox_id_Smartphone_V .. " " .. freebox_id_Smartphone_S .. " " .. interrupteur_id_alarme .. " ###BasicAuthentication###")
	datelog=os.date("%a")
	
	os.execute("nohup " .. scriptShDir .. "/" .. scriptName .. " \"" .. freebox_appid .. "\" \"" .. freebox_apptoken .. "\" " .. freebox_id_Smartphone_V .. " " .. freebox_id_Smartphone_S .. " " .. interrupteur_id_alarme .. " \"" .. domoticz_basic_auth.. "\" >> " .. scriptShDir .. "/../logs/script_commandes_freebox_network_status_" .. datelog .. ".log &")
	print("[FREEBOX] Les logs sont dans logs/script_commandes_freebox_network_status_" .. datelog .. ".log")
end

return commandArray

