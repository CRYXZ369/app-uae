#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/services/api-java/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Falta $ENV_FILE. Copia services/api-java/.env.example y configura tu base de datos."
  exit 1
fi

if ss -ltn 2>/dev/null | grep -qE ':(8080|8081)\b'; then
  echo "Los puertos 8080 u 8081 ya están en uso por otra sesión."
  echo "Detén primero la sesión anterior con Ctrl + C y vuelve a intentar."
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

export DEV_WEB_ORIGINS="${DEV_WEB_ORIGINS:-http://127.0.0.1:8081,http://localhost:8081}"

API_PID=""
cleanup() {
  if [[ -n "$API_PID" ]] && kill -0 "$API_PID" 2>/dev/null; then
    echo ""
    echo "Deteniendo API Java..."
    kill "$API_PID" 2>/dev/null || true
    wait "$API_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

echo "Iniciando API Java en http://127.0.0.1:8080..."
(
  cd "$ROOT_DIR/services/api-java"
  exec mvn -q spring-boot:run
) &
API_PID=$!

for _ in $(seq 1 45); do
  if curl -s -o /dev/null "http://127.0.0.1:8080/api/v1/sessions/current"; then
    break
  fi
  if ! kill -0 "$API_PID" 2>/dev/null; then
    echo "La API Java terminó inesperadamente."
    exit 1
  fi
  sleep 1
done

echo "API lista en http://127.0.0.1:8080"
echo "Iniciando Flutter Web en http://127.0.0.1:8081..."
cd "$ROOT_DIR/apps/mobile"
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8081 --dart-define=API_BASE_URL=http://127.0.0.1:8080
