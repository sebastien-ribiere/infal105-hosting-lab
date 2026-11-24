$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
New-Item -ItemType Directory -Force -Path '.local' | Out-Null
$cid = (docker compose ps -q postgres).Trim()
if (-not $cid) { throw 'Lancer docker compose up -d --build avant TP08' }
if (-not (Test-Path '.env')) { throw 'Copier .env.example vers .env' }
docker compose exec -T postgres pg_isready -U guildops -d guildops
if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL indisponible' }
$exists = (docker compose exec -T postgres psql -X -A -t -U guildops -d postgres -c "SELECT 1 FROM pg_database WHERE datname = 'guildops_restore'").Trim()
if ($exists -eq '1') { throw 'guildops_restore existe deja. Ne pas ecraser une base.' }
Write-Host 'Sauvegarde .local/backup.sql...'
docker compose exec -T postgres pg_dump -U guildops -d guildops -f /tmp/guildops_lab_backup.sql
if ($LASTEXITCODE -ne 0) { throw 'Echec pg_dump' }
docker cp "${cid}:/tmp/guildops_lab_backup.sql" '.local/backup.sql'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path '.local/backup.sql')) { throw 'Echec copie du dump' }
Write-Host 'Restauration dans guildops_restore...'
docker compose exec -T postgres createdb -U guildops guildops_restore
if ($LASTEXITCODE -ne 0) { throw 'Echec creation base restore' }
docker cp '.local/backup.sql' "${cid}:/tmp/guildops_lab_restore.sql"
if ($LASTEXITCODE -ne 0) { throw 'Echec copie vers conteneur' }
docker compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U guildops -d guildops_restore -f /tmp/guildops_lab_restore.sql
if ($LASTEXITCODE -ne 0) { throw 'Echec psql restore' }
$source = (docker compose exec -T postgres psql -X -A -t -U guildops -d guildops -c 'SELECT COUNT(*) FROM players').Trim()
$restore = (docker compose exec -T postgres psql -X -A -t -U guildops -d guildops_restore -c 'SELECT COUNT(*) FROM players').Trim()
Write-Host "Source : $source ; restauree : $restore"
if ($source -ne $restore) { throw 'Difference de lignes' }
Write-Host 'SUCCES : guildops est conservee ; guildops_restore est une base distincte.'
