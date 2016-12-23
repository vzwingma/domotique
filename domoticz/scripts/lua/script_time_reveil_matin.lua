commandArray = {}

heure_reveil = uservariables["reveil_heure"]

api_holidays = "http://holidayapi.com/v1/holidays?key=cae6007e-78f0-4ae1-8354-9b8b3db124e1&country=FR&year"
local TMPDIR_HOLIDAYS = "/tmp/holidays.tmp"
	
-- LOG
function log(message)
	print("[REVEIL] " .. message)
end

-- Fonction de lecture du contenu d'un fichier
-- @param : chemin vers le fichier
-- @return le contenu du fichier
function readAll(file)
    local f = io.open(file, "rb")
	if(f == nil) then
		return ""
	else
		local content = f:read("*all")
		f:close()
		return content
	end
end

-- Fonction de mise à jour de la liste des jours fériés
-- Appel de l'API http://holidayapi.com/ pour recevoir la liste et la stocker dans un fichier
-- SSI l'année change
function update_holidays_data()	
	annee_courante=os.date("%Y")

	-- Vérification de la date du fichier. Si l'année change : Appel de l'API pour mise à jour
	local TMPDIR_HOLIDAYS_DATE = "/tmp/holidays.date.tmp"
	os.execute("stat --printf='%y' " .. TMPDIR_HOLIDAYS .. " | cut -c1-4 > " .. TMPDIR_HOLIDAYS_DATE)
	local holidays_update = string.gsub(readAll(TMPDIR_HOLIDAYS_DATE), "\n", "")

	if( annee_courante ~= holidays_update) then 
		log("Mise à jour de la liste des jours fériés")
		local commande = "curl -s '" .. api_holidays .. "=" .. annee_courante .."' > " .. TMPDIR_HOLIDAYS
		log("Execution de la commande de mise à jour : " .. commande)
		os.execute(commande)
	-- else
	--	log("Pas de mise à jour ")
	end
end

-- # Lancement du réveil #
function lancementReveil()

	local jour_courant=os.date("%a")
	local date_courante=os.date("%Y-%m-%d")
	
	log(jour_courant .. " : Réveil à " .. heure_reveil)
	
	if( jour_courant == 'Sun' or jour_courant == 'Sat') then
		log("Annulation du réveil : C'est le week-end")
	elseif(otherdevices['Alarme'] == 'On') then
		log("Annulation du réveil : Personne n'est à la maison")
	elseif(otherdevices['Alarme'] == 'Off') then
		-- Vérification des jours fériés	
		local json_holidays = JSON:decode(readAll(TMPDIR_HOLIDAYS))
		for index, holiday_data in pairs(json_holidays.holidays) do
			-- log("H=".. index .. " >> " .. holiday_data[1].name)
			if(index == date_courante) then
				log("Annulation du réveil : C'est " .. holiday_data[1].name)
				return
			end
		end
	
		log("Déclenchement du réveil")
		commandArray['Scene:Bon matin'] = 'On'
	end
end


-- Vérification des paramètres du script
if( heure_reveil == nil) then
	error("[REVEIL] Les variables {reveil_heure} n'est pas définie dans Domoticz")
	return 512
else
	-- log("Chargement de la librairie JSON")
	JSON = (loadfile "/home/pi/appli/domoticz/scripts/lua/JSON.lua")() -- one-time load of the routines

	-- Mise à jour du fichier de la liste des jours fériés
	update_holidays_data()
	
	heure_courante=os.date("%H:%M")
	if(heure_courante == heure_reveil) then
		-- print("[REVEIL]             == " .. heure_courante .. " ? " .. tostring((heure_courante == heure_reveil)))
		-- Lancement des actions seulement la semaine et seulement si quelqu'un est là :
		lancementReveil()
	end
end
return commandArray