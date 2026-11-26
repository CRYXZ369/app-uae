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
  echo "Detén primero la terminal donde ejecutaste ./iniciar-presentacion.sh (con Ctrl + C) y vuelve a intentar."
  exit 1
fi

LAN_IP="${1:-}"
if [[ -z "$LAN_IP" ]]; then
  LAN_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1 || true)"
fi
if [[ -z "$LAN_IP" ]]; then
  LAN_IP="$(hostname -I 2>/dev/null | tr ' ' '\n' | grep -E '^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)' | head -n1 || true)"
fi
if [[ -z "$LAN_IP" ]]; then
  echo "No se pudo detectar una IP privada local. Pasa la IP manualmente: ./iniciar-stand.sh TU_IP"
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

export SERVER_ADDRESS="0.0.0.0"
export DEV_WEB_ORIGINS="http://$LAN_IP:8081,http://127.0.0.1:8081,http://localhost:8081"

API_PID=""
cleanup() {
  if [[ -n "$API_PID" ]] && kill -0 "$API_PID" 2>/dev/null; then
    echo ""
    echo "Deteniendo servidor del stand..."
    kill "$API_PID" 2>/dev/null || true
    wait "$API_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

echo "=========================================="
echo "  App Unificada UAE · Modo Stand (LAN)"
echo "  IP detectada: $LAN_IP"
echo "=========================================="
echo "1) Iniciando API Java en puerto 8080..."
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

echo "2) Compilando Flutter Web optimizado (carga rápida en teléfonos y PC)..."
cd "$ROOT_DIR/apps/mobile"
flutter build web --release \
  --dart-define="API_BASE_URL=http://$LAN_IP:8080" \
  --dart-define=LAN_DEMO_MODE=true

echo ""
echo "=========================================="
echo "  STAND LISTO PARA PROBAR EN VIVO"
echo "  Abre en la computadora y el teléfono:"
echo "    http://$LAN_IP:8081"
echo ""
echo "  Presiona Ctrl + C para detener ambos."
echo "=========================================="
echo ""

python3 -m http.server 8081 --bind 0.0.0.0 --directory "$ROOT_DIR/apps/mobile/build/web"
