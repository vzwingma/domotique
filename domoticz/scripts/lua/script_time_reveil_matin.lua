commandArray = {}

heure_reveil = uservariables["reveil_heure"]

-- LOG
function log(message)
	print("[REVEIL] " .. message)
end

-- # Lancement du réveil #
function lancementReveil()
	jour_courant=os.date("%a")
	heure_courante=os.date("%H:%M")
	if(heure_courante == heure_reveil) then
		log(jour_courant .. " : Réveil à " .. heure_reveil)
		-- print("[REVEIL]             == " .. heure_courante .. " ? " .. tostring((heure_courante == heure_reveil)))
		
		if( jour_courant == 'Sun' or jour_courant == 'Sat') then
			log("Annulation du réveil : C'est le week-end")
		elseif(otherdevices['Alarme'] == 'On') then
			log("Annulation du réveil : Personne n'est à la maison")
		elseif(otherdevices['Alarme'] == 'Off') then
			log("Déclenchement du réveil")
			commandArray['Scene:Bon matin'] = 'On'
		end
	end
end


-- Vérification des paramètres du script
if( heure_reveil == nil) then
	error("[REVEIL] Les variables {reveil_heure} n'est pas définie dans Domoticz")
	return 512
else
	-- Lancement des actions seulement la semaine et seulement si quelqu'un est là :
	lancementReveil()
end
return commandArray