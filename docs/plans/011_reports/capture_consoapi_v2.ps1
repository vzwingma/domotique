<#
  Plan 011 — T0.2 : capture des réponses Conso API (Enedis Mesure synchrone V2).
  - Le jeton est saisi masqué, jamais écrit sur disque ni affiché.
  - Le PRM est remplacé par 00000000000000 dans tous les fichiers produits.
  - 1 lancement = ~8 requêtes (quota : 5 req/s, 10 000 req/h) ; ne pas boucler.
  Usage (PowerShell 7+) :
    pwsh .\capture_consoapi_v2.ps1 -Prm 12345678901234 -Jours 3 -Sortie $env:TEMP\consoapi_v2
  Puis relire les fichiers avant de les partager (aucun jeton, PRM masqué).
#>
param(
  [Parameter(Mandatory)][ValidatePattern('^\d{14}$')][string]$Prm,
  [ValidateRange(2,7)][int]$Jours = 3,
  [string]$Sortie = (Join-Path $env:TEMP 'consoapi_v2'),
  [string]$TokenFile,  # optionnel : fichier local contenant le jeton (exécution non interactive)
  [switch]$Complement  # 2e passe : seulement la période max de puissance_conso_max_quotidienne (R6b)
)

$ErrorActionPreference = 'Stop'
$base   = 'https://conso.boris.sh/api'
$ua     = 'DomoticzLinkyPlugin/3.0.0-dev (+https://github.com/vzwingma/DomoticzLinky)'
$masque = '00000000000000'
if ($TokenFile) {
  $token = (Get-Content -Raw -LiteralPath $TokenFile).Trim()
} else {
  $tokenSec = Read-Host 'Jeton Conso API' -AsSecureString
  $token = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenSec))
}

New-Item -ItemType Directory -Force -Path $Sortie | Out-Null
$fin   = (Get-Date).Date.AddDays(-1)            # J-1 : données de J dispo vers 8 h à J+1
$debut = $fin.AddDays(-$Jours)
$d = $debut.ToString('yyyy-MM-dd'); $f = $fin.ToString('yyyy-MM-dd')

function Capture([string]$nom, [string]$url, [string]$jeton) {
  $headers = @{ 'User-Agent' = $ua }
  if ($jeton) { $headers['Authorization'] = "Bearer $jeton" }
  $resp = Invoke-WebRequest -Uri $url -Headers $headers -SkipHttpErrorCheck
  $entetes = ($resp.Headers.GetEnumerator() |
    ForEach-Object { "$($_.Key): $($_.Value -join ', ')" }) -join "`n"
  $corps = ("$($resp.Content)" -replace $Prm, $masque).Replace($token, '<JETON>')
  $urlMasquee = $url -replace $Prm, $masque
  @"
# $nom
URL     : $urlMasquee
Statut  : $($resp.StatusCode)
--- En-têtes ---
$entetes
--- Corps ---
$corps
"@ | Set-Content -Encoding utf8 (Join-Path $Sortie "$nom.txt")
  Write-Host ("{0,-40} -> {1}" -f $nom, $resp.StatusCode)
  Start-Sleep -Milliseconds 400
}

$q = "pointId=$Prm&dateDebut=$d&dateFin=$f"
if ($Complement) {
  foreach ($n in 365, 1095) {
    $dn = $fin.AddDays(-$n).ToString('yyyy-MM-dd')
    Capture "periode_${n}j_puissance_max" "$base/puissance_conso_max_quotidienne?pointId=$Prm&dateDebut=$dn&dateFin=$f" $token
  }
  $token = $null; Remove-Variable tokenSec -ErrorAction SilentlyContinue
  Write-Host "Fichiers : $Sortie"; return
}
# Réponses nominales (même période pour les 3 types)
Capture '200_courbe_de_charge_consommation'   "$base/courbe_de_charge_consommation?$q"   $token
Capture '200_puissance_conso_max_quotidienne' "$base/puissance_conso_max_quotidienne?$q" $token
Capture '200_consommation_quotidienne'        "$base/consommation_quotidienne?$q"        $token
# Limite de période (courbe sur 8 jours, puis 31 jours)
$d8  = $fin.AddDays(-8).ToString('yyyy-MM-dd')
$d31 = $fin.AddDays(-31).ToString('yyyy-MM-dd')
Capture 'periode_8j_courbe'  "$base/courbe_de_charge_consommation?pointId=$Prm&dateDebut=$d8&dateFin=$f"  $token
Capture 'periode_31j_courbe' "$base/courbe_de_charge_consommation?pointId=$Prm&dateDebut=$d31&dateFin=$f" $token
# Erreurs
Capture 'err_400_periode_inversee' "$base/courbe_de_charge_consommation?pointId=$Prm&dateDebut=$f&dateFin=$d" $token
Capture 'err_401_jeton_invalide'   "$base/courbe_de_charge_consommation?$q" 'jeton.invalide.test'
Capture 'err_type_inconnu'         "$base/type_inexistant?$q" $token

$token = $null; Remove-Variable tokenSec -ErrorAction SilentlyContinue
Write-Host "Fichiers : $Sortie (vérifier l'absence de jeton/PRM avant partage)"
