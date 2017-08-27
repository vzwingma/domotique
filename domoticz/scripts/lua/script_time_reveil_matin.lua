commandArray = {}

heure_reveil = uservariables["reveil_heure"]

api_holidays = "https://api.tuxx.co.uk/2.0/holidays/holidays.php"
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
	local holidays_update = readAll(TMPDIR_HOLIDAYS_DATE)
	-- log("Année courante [".. annee_courante .. "] vs année chargée : [".. holidays_update.."]")
	if( annee_courante ~= holidays_update) then 
		log("Mise à jour de la liste des jours fériés")
		local commande = "curl -v  -X GET '".. api_holidays .."?date_start="..annee_courante.."-01-01&date_end="..annee_courante.."-12-31&regions=France&lang=fr' > " .. TMPDIR_HOLIDAYS
		-- log("Execution de la commande de mise à jour : " .. commande)
		os.execute(commande)
		os.execute("printf " .. annee_courante .. " > " .. TMPDIR_HOLIDAYS_DATE)
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
		for index, holiday_data in pairs(json_holidays) do
			-- log("H=".. index .. " >> " .. holiday_data.holiday)
			if(holiday_data.date_start == date_courante and holiday_data.type == "holiday") then
				log("Annulation du réveil : C'est " .. holiday_data.holiday)
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
	JSON = (loadfile "/src/domoticz/scripts/lua/JSON.lua")() -- one-time load of the routines

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