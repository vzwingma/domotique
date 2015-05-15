commandArray = {}
print("Tests de présence des smartphones (" .. uservariables["IP_Smartphone_V"] .. ") & (" .. uservariables["IP_Smartphone_S"] .. ")")
ping_success=os.execute('ping -c1 ' .. uservariables["IP_Smartphone_V"])
if ping_success then
	print("  ping Smartphone V OK")
	if ( otherdevices['Smartphone V'] == 'Off') then
		print("	Le smartphone V est présent")
		commandArray['Smartphone V']='On'
    end
else
	if (otherdevices['Smartphone V'] == 'On') then
		print("	Le smartphone V est absent")
		commandArray['Smartphone V']='Off'
	end
end

ping_success=os.execute('ping -c1 ' .. uservariables["IP_Smartphone_S"])
if ping_success then
	print("  ping Smartphone S OK")
	if ( otherdevices['Smartphone S'] == 'Off') then
		print("	Le smartphone S est présent")
		commandArray['Smartphone V']='On'
	end
else
	if (otherdevices['Smartphone S'] == 'On') then
		print("	Le smartphone S est absent")
		commandArray['Smartphone S']='Off'
	end
end
return commandArray

