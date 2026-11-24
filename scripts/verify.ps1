param(
    [string]$BaseUrl = "http://127.0.0.1:8080",
    [switch]$HealthOnly
)
$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd('/')
Write-Host "Service : $BaseUrl"
$available = $false
for ($i = 0; $i -lt 30; $i++) {
    try { $health = Invoke-RestMethod "$BaseUrl/healthz" -TimeoutSec 3; $available = $true; break }
    catch { Start-Sleep -Seconds 2 }
}
if (-not $available) { throw "ERREUR : /healthz indisponible (60 secondes)" }
$health | ConvertTo-Json -Compress | Write-Host
if ($HealthOnly) { Write-Host "HEALTH_ONLY : pas de verification de DB (readyz non valide)."; return }
$available = $false
for ($i = 0; $i -lt 30; $i++) {
    try { $ready = Invoke-RestMethod "$BaseUrl/readyz" -TimeoutSec 3; $available = $true; break }
    catch { Start-Sleep -Seconds 2 }
}
if (-not $available) { throw "ERREUR : /readyz indisponible ; regarder les logs DB" }
Write-Host "GET /readyz : $($ready.status)"
$before = Invoke-RestMethod "$BaseUrl/players" -TimeoutSec 5
Write-Host "Joueurs avant : $(@($before.players).Count)"
$body = '{"name":"CastorDemo","score":10}'
$created = Invoke-RestMethod -Method Post -Uri "$BaseUrl/players" -ContentType 'application/json' -Body $body -TimeoutSec 5
Write-Host "POST /players : ID $($created.id)"
$after = Invoke-RestMethod "$BaseUrl/players" -TimeoutSec 5
if (-not (@($after.players) | Where-Object { $_.name -eq 'CastorDemo' })) { throw "ERREUR : CastorDemo introuvable" }
Write-Host "SUCCES : API, DB, ecriture puis lecture verifiees."
