# dev_ngrok_flutter.sh
#!/usr/bin/env bash
set -Eeuo pipefail

PORT="${PORT:-8001}"                 # port où tourne ton backend local
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
DART_CONST="$APP_DIR/lib/constants/api_url.dart"
NGROK_LOG="$APP_DIR/ngrok.log"

command -v ngrok   >/dev/null || { echo "ngrok manquant"; exit 1; }
command -v flutter >/dev/null || { echo "flutter manquant"; exit 1; }

# Démarre ngrok
echo "🌍 Lancement ngrok sur http://${HOST:-127.0.0.1}:$PORT …"
pkill -f "ngrok http $PORT" || true
nohup ngrok http "$PORT" > "$NGROK_LOG" 2>&1 &

# Récupère l’URL publique
echo "⏳ Récupération URL ngrok…"
for i in {1..30}; do
  NGROK_URL="$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*' | head -n 1 || true)"
  [[ -n "$NGROK_URL" ]] && break
  sleep 1
done
[[ -z "${NGROK_URL:-}" ]] && { echo "❌ Impossible d'obtenir l'URL ngrok"; tail -n 80 "$NGROK_LOG" || true; exit 1; }

# Écrit la constante consommée par Env.apiBase
mkdir -p "$(dirname "$DART_CONST")"
cat > "$DART_CONST" <<EOF
// Fichier généré automatiquement
const String API_BASE_URL = '$NGROK_URL';
EOF
echo "✅ API_BASE_URL = $NGROK_URL (écrit dans $DART_CONST)"

# Lance Flutter
echo "🚀 flutter run"
flutter run
