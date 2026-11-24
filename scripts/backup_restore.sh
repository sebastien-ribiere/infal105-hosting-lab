#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .local
cid="$(docker compose ps -q postgres)"
if [[ -z "$cid" ]]; then echo 'ERREUR : lancer docker compose up -d --build avant le TP08' >&2; exit 1; fi
if [[ ! -f .env ]]; then echo 'ERREUR : .env absent ; copier .env.example' >&2; exit 1; fi
if ! docker compose exec -T postgres pg_isready -U guildops -d guildops >/dev/null; then
    echo 'ERREUR : PostgreSQL indisponible' >&2; exit 1
fi
exists="$(docker compose exec -T postgres psql -X -A -t -U guildops -d postgres -c "SELECT 1 FROM pg_database WHERE datname = 'guildops_restore'" | tr -d '\r\n')"
if [[ "$exists" == "1" ]]; then
    echo 'ERREUR : guildops_restore existe deja. Ne pas ecraser une base existante.' >&2
    exit 1
fi
printf 'Sauvegarde vers .local/backup.sql...\n'
docker compose exec -T postgres pg_dump -U guildops -d guildops -f /tmp/guildops_lab_backup.sql
docker cp "${cid}:/tmp/guildops_lab_backup.sql" .local/backup.sql
test -s .local/backup.sql || { echo 'ERREUR : dump vide' >&2; exit 1; }
printf 'Creation et restauration dans guildops_restore (source conservee)...\n'
docker compose exec -T postgres createdb -U guildops guildops_restore
docker cp .local/backup.sql "${cid}:/tmp/guildops_lab_restore.sql"
docker compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U guildops -d guildops_restore -f /tmp/guildops_lab_restore.sql >/dev/null
source_count="$(docker compose exec -T postgres psql -X -A -t -U guildops -d guildops -c 'SELECT COUNT(*) FROM players' | tr -d '\r\n')"
restored_count="$(docker compose exec -T postgres psql -X -A -t -U guildops -d guildops_restore -c 'SELECT COUNT(*) FROM players' | tr -d '\r\n')"
printf 'Lignes source : %s ; lignes restaurees : %s\n' "$source_count" "$restored_count"
[[ "$source_count" == "$restored_count" ]] || { echo 'ERREUR : difference de lignes' >&2; exit 1; }
printf 'SUCCES : restauration controlee. La DB source guildops est preservee.\n'
printf 'La mesure des durees et le controle du contenu des donnees restent a renseigner.\n'
