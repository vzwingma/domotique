-- ## Scripts de commande des groupes de Lumières
-- Script déclenché pour chaque groupe de lumières : applique le niveau aux lumières du groupe
return
{
    on =
    {
        devices = { '[Grp] Lumières Salon', '[Grp] Toutes lumières' },
    },
    data = {
        uuid = { initial = "" }
    },
    logging = {
        level = domoticz.LOG_DEBUG,
        marker = "[Groupe Lumières] "
    },
    -- Activation du groupe de lumières
    execute = function(domoticz, group)
    -- ### Fonctions internes ###
        -- Retourne la liste des lumières à commander pour un groupe donné
        local function getLumieresNameFromGroup(groupName)
            if(groupName == domoticz.helpers.GROUPE_LUMIERES_SALON) then
                return { domoticz.helpers.DEVICE_LAMPE_TV, domoticz.helpers.DEVICE_LAMPE_TV_2, domoticz.helpers.DEVICE_LAMPE_SALON, domoticz.helpers.DEVICE_LAMPE_CUISINE }
            elseif(groupName == domoticz.helpers.GROUPE_LUMIERES_TOUTES) then
                return { domoticz.helpers.DEVICE_LAMPE_TV, domoticz.helpers.DEVICE_LAMPE_TV_2, domoticz.helpers.DEVICE_LAMPE_SALON, domoticz.helpers.DEVICE_LAMPE_CUISINE, domoticz.helpers.DEVICE_LAMPE_BEBE, domoticz.helpers.DEVICE_LAMPE_NOUS }
            else
                return {}
            end
        end

    -- ### Lancement du scénario du Groupe ###
        domoticz.data.uuid = domoticz.helpers.uuid()
        local uuid       = domoticz.data.uuid
        local lumieresName = getLumieresNameFromGroup(group.name)
        local levelSet     = domoticz.helpers.getLevelFromState(group)
        domoticz.log("[" .. uuid .. "] Groupe [" .. group.name .. "] -> " .. group.state .. " : " .. levelSet .. "%", domoticz.LOG_INFO)
        for _, lumiereName in pairs(lumieresName) do
            -- Cas particulier : veilleuse bébé à éteindre
            if(lumiereName == domoticz.helpers.DEVICE_LAMPE_BEBE and levelSet == 0) then
                domoticz.log("[" .. uuid .. "] Extinction veilleuse bébé", domoticz.LOG_INFO)
                domoticz.devices(domoticz.helpers.DEVICE_LAMPE_VEILLEUSE_BEBE).switchOff()
            -- Cas particulier : prise TV
            else if(lumiereName == domoticz.helpers.DEVICE_LAMPE_TV) then
                domoticz.log("[" .. uuid .. "] Activation prise TV", domoticz.LOG_INFO)
                if(levelSet == 0) then
                    domoticz.devices(domoticz.helpers.DEVICE_LAMPE_TV).switchOff()
                else
                    domoticz.devices(domoticz.helpers.DEVICE_LAMPE_TV).switchOn()
                end
            -- Cas général : lampe à commander
            else
                domoticz.log("[" .. uuid .. "] Lumière [" .. lumiereName .. "] -> " .. levelSet .. "%", domoticz.LOG_INFO)
                domoticz.devices(lumiereName).setLevel(levelSet)
            end
        end
    end
}
