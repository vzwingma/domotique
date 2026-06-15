# Plan d'Action 005 — Alignement TLS HTTPD / Domoticz mobile

## Probleme

Le frontal HTTPD genere aujourd'hui un certificat auto-signe avec `CN=domoticz`, alors que le client mobile `domotique-mobile` espere un certificat lie au domaine public `domatique.freeboxos.fr` et charge un PEM bundle dans l'app. Le resultat est un ecart entre l'identite TLS servie et les verifications cote mobile.

## Approche

- verifier la cible TLS attendue par le mobile et la forme exacte de validation cote Java
- rendre le certificat HTTPD coherent avec cette cible (CN/SAN et eventuel parametre de build)
- aligner le bundle mobile sur le certificat effectivement servi par HTTPD
- verifier que la doc et les exemples d'export parlent du meme flux de confiance

## Taches

1. **Auditer le chemin TLS actuel**
   - confirmer le hostname attendu par `DomoticzSSLHelper.java`
   - confirmer le certificat effectivement genere par `_docker/build_httpd/Dockerfile`
   - identifier le point exact de rupture (CN, SAN, bundle PEM, hostname verifier)

2. **Aligner le certificat HTTPD**
   - generer un certificat dont l'identite correspond au domaine public utilise par le mobile
   - conserver un format simple et reproductible au build
   - si necessaire, ajouter SAN pour coller aux verifications modernes des clients TLS

3. **Aligner le cote mobile**
   - faire consommer au plugin le bon certificat PEM exporte depuis HTTPD
   - ajuster la logique de validation si le helper repose encore sur un fallback CN trop strict
   - garantir que l'URL configuree et l'identite TLS partagent le meme hostname

4. **Verifier et documenter**
   - tester le certificat servi par HTTPD et sa correspondance avec le bundle mobile
   - mettre a jour la documentation d'export / configuration si le flux change

## Notes

- Le depot courant contient surtout le cote HTTPD ; le code mobile est dans le repo `domotique-mobile`.
- Si la solution retenue implique un changement de strategie de confiance, elle devra rester coherente entre les deux depots.
