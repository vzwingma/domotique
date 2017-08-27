#!/usr/bin/lua
commandArray = {}

-- LOG
function log(modul, message)
	print("[".. modul .."] " .. message)
end
function logTV(message)
	log("TV", message)
end

-- Pause
-- @param tempo : tempo d'après la commande en seconde
function pause(tempo)
	if( tempo > 0 ) then
		log("  Tempo de " .. tempo .. " secondes")
		os.execute("sleep ".. tempo)
	end
end