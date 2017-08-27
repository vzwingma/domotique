#!/usr/bin/lua
commandArray = {}

-- Package complémentaires
package.path = package.path..";/src/domoticz/scripts/lua/modules/?.lua"
require 'utils'

local ip_livebox_tv="192.168.1.10"

-- Fonction d'appel à l'API du Orange Livebox Player
-- Pour lancer une commande : Curl
-- @param ip_livebox_tv : IP de la livebox
-- @param key : touche 
-- @param appuilong : appui long ? 

function callCommandeTV(key, appuilong)
	local baseurl="http://" .. ip_livebox_tv .. ":8080/remoteControl/cmd?operation=01&key=" .. key .. "&mode="
	-- Appui long
	if( appuilong == true ) then
		url=baseurl .. "1"
	else
		url=baseurl .. "0"
	end
	
	apiCallGetReadRaw(url)
	-- Relachement de l'appui long	
	if( appuilong == true ) then
		pause(0.5)
		url=baseurl .. "2"
		apiCallGetReadRaw(url)
	end
end

-- Fonction de statut de la Télé
-- @return booléen du statut
function getStatutTV()
	local baseurl="http://"..ip_livebox_tv..":8080/remoteControl/cmd?operation=10"
	local resultatStatutTV = apiCallGetReadJSON(baseurl)
	local statutTV = resultatStatutTV.result.data.activeStandbyState == "0"
	if(statutTV) then
		logOrange("Télévision active sur " .. resultatStatutTV.result.data.osdContext) 
	else
		logOrange("Télévision éteinte") 
	end
	return statutTV
end