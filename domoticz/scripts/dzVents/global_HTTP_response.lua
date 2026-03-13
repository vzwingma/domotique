-- ## Gestionnaire de réponses HTTP génériques
-- ## Rôle : journalisation enrichie, classification des erreurs, comptage des échecs consécutifs.
-- ## Note retry (T-B2) : ce handler reçoit principalement des callbacks POST/PUT (commandes non idempotentes)
-- ## et des GET terminaux. Le retry sur appels idempotents (GET) doit être géré par chaque script appelant.
-- ## Le compteur d'erreurs consécutives fournit le socle minimal de détection de dégradation.
return
{
    on =
    {
        httpResponses = { 'global_HTTP_response' }
    },
    data = {
        -- Compteur d'erreurs HTTP consécutives (remis à 0 au premier succès).
        -- Seuil d'alerte : dès que consecutiveErrors atteint HTTP_ERROR_THRESHOLD (3), un avertissement est émis.
        consecutiveErrors = { initial = 0 }
    },
    logging = {
        level = domoticz.LOG_INFO,
        marker = "[HTTP Response] "
    },
    execute = function(domoticz, item)

        -- Seuil à partir duquel une alerte de dégradation est émise
        local HTTP_ERROR_THRESHOLD = 3

        -- Extraction sécurisée du corrId (les headers peuvent être nil sur erreur réseau)
        local corrId = (item.headers and item.headers["X-CorrId"]) or "n/a"
        local callbackName = tostring(item.callback or "n/a")

        -- Classifie un code HTTP en catégorie lisible.
        -- Retourne : 'OK', 'TIMEOUT/CONNEXION', 'ERREUR_CLIENT', 'ERREUR_SERVEUR', ou 'INCONNU'.
        local function httpErrorClass(statusCode)
            local code = statusCode or 0
            if code >= 200 and code <= 299 then return 'OK'
            elseif code == 0                then return 'TIMEOUT/CONNEXION'
            elseif code >= 400 and code <= 499 then return 'ERREUR_CLIENT'
            elseif code >= 500              then return 'ERREUR_SERVEUR'
            else                            return 'INCONNU'
            end
        end

        if (item.isHTTPResponse) then
            local statusCode = item.statusCode or 0

            if (item.isOk or (statusCode >= 200 and statusCode <= 299)) then
                -- Succès : réinitialiser le compteur d'erreurs consécutives
                domoticz.data.consecutiveErrors = 0
                domoticz.log("[" .. corrId .. "][" .. callbackName .. "] "
                    .. statusCode .. " / " .. tostring(item.statusText)
                    .. " :: " .. tostring(item.data),
                    domoticz.LOG_DEBUG)
            else
                -- Échec : classifier, incrémenter le compteur, journaliser avec contexte
                local errorClass = httpErrorClass(statusCode)
                domoticz.data.consecutiveErrors = domoticz.data.consecutiveErrors + 1
                local count = domoticz.data.consecutiveErrors

                domoticz.log("[" .. corrId .. "][" .. callbackName .. "] "
                    .. errorClass .. " HTTP " .. statusCode
                    .. " / " .. tostring(item.statusText)
                    .. " :: " .. tostring(item.data)
                    .. " — erreurs consécutives : " .. count,
                    domoticz.LOG_ERROR)

                -- Alerte de dégradation si le seuil est atteint
                -- Note T-B2 : pas de retry ici ; ce callback couvre principalement des commandes
                -- non idempotentes (POST/PUT). Le retry sur GET idempotents est à la charge
                -- de chaque script appelant (Tydom_*, Freebox_*).
                if count >= HTTP_ERROR_THRESHOLD then
                    domoticz.log("[" .. corrId .. "][" .. callbackName .. "] "
                        .. "ALERTE : " .. count .. " erreurs HTTP consécutives. "
                        .. "Vérifier la disponibilité de l'intégration.",
                        domoticz.LOG_ERROR)
                end
            end
        end
    end
}