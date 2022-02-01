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

            if(group.name == domoticz.helpers.GROUPE_LUMIERES_SALON) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Activation toutes lumières salon : " .. group.state, domoticz.LOG_INFO)
                return { domoticz.helpers.DEVICE_LAMPE_TV, domoticz.helpers.DEVICE_LAMPE_SALON , domoticz.helpers.DEVICE_LAMPE_CUISINE }
            elseif(group.name == domoticz.helpers.GROUPE_LUMIERES_TOUTES) then
                domoticz.log("[" .. domoticz.data.uuid .. "] Activation toutes lumières : " .. group.state, domoticz.LOG_INFO)
                return { domoticz.helpers.DEVICE_LAMPE_TV, domoticz.helpers.DEVICE_LAMPE_SALON , domoticz.helpers.DEVICE_LAMPE_CUISINE, domoticz.helpers.DEVICE_LAMPE_BEBE }
            else
                return {}
            end
        end
        -- Recheche du niveau de lumières suivant l'état du groupe 
        function getLevelFromGroupState(group)
            if(group.state == 'On') then
                -- Ouverture du groupe de lumières suivant la valeur du niveau
               return group.level
            else
               return 0
            end
        end


    -- ### Lancement du scénario du Groupe ###
        domoticz.data.uuid = domoticz.helpers.uuid()
        local lumieresName = getLumieresNameFromGroup(group)
        local levelSet = getLevelFromGroupState(group)
        for _, lumiereName in pairs(lumieresName) do 
            domoticz.log("[" .. domoticz.data.uuid .. "] Allumage de la lumière " .. lumiereName .. " à " .. levelSet .. "%", domoticz.LOG_INFO)
            domoticz.devices(lumiereName).setLevel(levelSet)
        end
    end       
}