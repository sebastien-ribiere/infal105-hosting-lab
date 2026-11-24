#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
HEALTH_ONLY="${HEALTH_ONLY:-0}"

printf 'Service: %s\n' "$BASE_URL"
# Do not treat a started process as a ready database. Wait up to 60 seconds.
for attempt in $(seq 1 30); do
  if curl --fail --silent --output /dev/null "${BASE_URL}/healthz"; then break; fi
  if (( attempt == 30 )); then echo 'ERREUR : /healthz indisponible apres 60 s' >&2; exit 1; fi
  sleep 2
done
curl --fail-with-body --silent --show-error "${BASE_URL}/healthz"
printf '\n'
if [[ "$HEALTH_ONLY" == "1" ]]; then
  printf 'HEALTH_ONLY=1 : aucun test de connexion PostgreSQL. /readyz non valide.\n'
  exit 0
fi
for attempt in $(seq 1 30); do
  if curl --fail --silent --output /dev/null "${BASE_URL}/readyz"; then break; fi
  if (( attempt == 30 )); then echo 'ERREUR : /readyz reste indisponible apres 60 s, verifier DB et logs' >&2; exit 1; fi
  sleep 2
done
printf '\nGET /readyz\n'
curl --fail-with-body --silent --show-error "${BASE_URL}/readyz"
printf '\nGET /players (avant)\n'
curl --fail-with-body --silent --show-error "${BASE_URL}/players"
printf '\nPOST /players\n'
curl --fail-with-body --silent --show-error -X POST "${BASE_URL}/players" \
  -H 'Content-Type: application/json' -d '{"name":"CastorDemo","score":10}'
printf '\nGET /players (apres)\n'
response="$(curl --fail-with-body --silent --show-error "${BASE_URL}/players")"
printf '%s\n' "$response"
if [[ "$response" != *'"name": "CastorDemo"'* && "$response" != *'"name":"CastorDemo"'* ]]; then
  echo 'ERREUR : CastorDemo absent de la liste retournee' >&2
  exit 1
fi
printf 'SUCCES : API, DB, ecriture puis lecture verifiees.\n'
