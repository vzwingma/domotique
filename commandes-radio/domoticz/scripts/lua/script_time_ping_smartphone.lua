commandArray = {}
print(" Debut ping Smartphone V ")
ping_success=os.execute('ping -c1 192.168.1.67')
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

