commandArray = {}
print(" Debut ping Smartphone V (" .. uservariables["IP_Smartphone_V"] .. ")")
ping_success=os.execute('ping -c1 ' .. uservariables["IP_Smartphone_V"])
if ping_success then
	print("ping Smartphone V success")
     if ( otherdevices['Smartphone V'] == 'Off') then
                  print("Smartphone V up")
                 commandArray['Smartphone V']='On'
    end
else
      if (otherdevices['Smartphone V'] == 'On') then
                print("ping Smartphone V fail")
               commandArray['Smartphone V']='Off'
      end
end
print(" fin ping Smartphone V ")
return commandArray

