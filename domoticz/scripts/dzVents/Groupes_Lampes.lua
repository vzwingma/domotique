-- ## Scripts de commande des groupes de Lumières
-- Script déclenché pour chaque groupe de lumières : lance les niveaux et statuts des lumières constituant le groupe (ou le groupe de groupe)
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
        level = domoticz.LOG_INFO,
        marker = "[Groupe Lumières] "
    },
    -- Activation du groupe de lumières
    execute = function(domoticz, group)
    -- ### Fonctions internes ###
        -- Recherche des volets du groupe
        function getLumieresNameFromGroup(group)

            -- Groupe lumières du salon
            if(group.name == domoticz.helpers.GROUPE_LUMIERES_SALON) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Activation toutes lumières salon : " .. group.state, domoticz.LOG_INFO)
                return { domoticz.helpers.DEVICE_LAMPE_TV, domoticz.helpers.DEVICE_LAMPE_SALON , domoticz.helpers.DEVICE_LAMPE_CUISINE }
            -- Groupe toutes les lumières
            elseif(group.name == domoticz.helpers.GROUPE_LUMIERES_TOUTES) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Activation toutes lumières : " .. group.state, domoticz.LOG_INFO)
                return { domoticz.helpers.DEVICE_LAMPE_TV, domoticz.helpers.DEVICE_LAMPE_SALON , domoticz.helpers.DEVICE_LAMPE_CUISINE, domoticz.helpers.DEVICE_LAMPE_BEBE, domoticz.helpers.DEVICE_LAMPE_NOUS }
            else
                return {}
            end
        end

    -- ### Lancement du scénario du Groupe ###
        domoticz.data.uuid = domoticz.helpers.uuid()
        local lumieresName = getLumieresNameFromGroup(group)
        local levelSet = domoticz.helpers.getLevelFromState(group)
        for _, lumiereName in pairs(lumieresName) do 
            domoticz.log("[" .. domoticz.data.uuid .. "] Allumage de la lumière " .. lumiereName .. " à " .. levelSet .. "%", domoticz.LOG_INFO)
            domoticz.devices(lumiereName).setLevel(levelSet)

            -- Cas particulier de la veilleuse de bébé à éteindre
            if(lumiereName == domoticz.helpers.DEVICE_LAMPE_VEILLEUSE_BEBE and levelSet == 0) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Extinction de la veilleuse de bébé", domoticz.LOG_INFO)
                domoticz.devices(domoticz.helpers.DEVICE_LAMPE_VEILLEUSE_BEBE).switchOff()
            end

        end
    end       
}