#!/usr/bin/env bash
set -Eeuo pipefail

# =========================
# Configuráveis (opcional)
# =========================
APP_DIR="${APP_DIR:-airflow-docker}"
API_PORT="${API_PORT:-8080}"               # porta do api-server exposta no compose
PG_HOST_ALIAS="${PG_HOST_ALIAS:-host.docker.internal}"
PG_PORT="${PG_PORT:-5432}"

# =========================
# Detecta docker compose v2/v1
# =========================
if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif docker-compose version >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  echo "❌ Docker Compose não encontrado. Instale o Docker Desktop (ou docker-compose)." >&2
  exit 1
fi

# =========================
# Cria estrutura de pastas
# =========================
mkdir -p "${APP_DIR}"
cd "${APP_DIR}"

mkdir -p ./dags ./logs ./plugins ./config

# =========================
# Cria .env padrão (se não existir)
# =========================
if [[ ! -f .env ]]; then
  cat > .env <<EOF
AIRFLOW_IMAGE_NAME=apache/airflow:3.0.1
AIRFLOW_UID=$(id -u)
AIRFLOW_PROJ_DIR=.
_AIRFLOW_WWW_USER_USERNAME=airflow
_AIRFLOW_WWW_USER_PASSWORD=airflow
EOF
  echo "📝 Criado .env com valores padrão."
fi

# =========================
# Pré-checagem: Postgres local acessível do Docker
# (usa container efêmero com alias host-gateway p/ Linux puro)
# =========================
echo "🔎 Verificando acesso ao Postgres em ${PG_HOST_ALIAS}:${PG_PORT} ..."
docker run --rm --add-host "${PG_HOST_ALIAS}:host-gateway" postgres:16-alpine \
  pg_isready -h "${PG_HOST_ALIAS}" -p "${PG_PORT}" -t 5 || {
    echo "⚠️  Aviso: pg_isready não confirmou. Se você estiver no macOS/Windows, ignore este aviso."
    echo "   Se estiver em Linux puro, verifique se o compose tem: extra_hosts: ['host.docker.internal:host-gateway']"
}

# =========================
# Inicializa DB + usuário admin (serviço airflow-init)
# =========================
echo "🚀 Rodando airflow-init ..."
${COMPOSE} up --pull always -d airflow-init

# espera o airflow-init finalizar (exit 0)
echo "⏳ Aguardando término do airflow-init ..."
# loop simples: sai quando container não estiver mais 'running'
for i in {1..60}; do
  state="$(${COMPOSE} ps --format json airflow-init | sed -n 's/.*"State":"\([^"]*\)".*/\1/p')"
  [[ "${state:-}" != "running" ]] && break
  sleep 2
done

# checa exit code do airflow-init
exit_code="$(${COMPOSE} ps --format json airflow-init | sed -n 's/.*"ExitCode":\([0-9]*\).*/\1/p')"
if [[ -n "${exit_code}" && "${exit_code}" != "0" ]]; then
  echo "❌ airflow-init terminou com ExitCode=${exit_code}. Veja os logs:"
  ${COMPOSE} logs --no-log-prefix airflow-init
  exit 1
fi
echo "✅ airflow-init concluído."

# =========================
# Sobe os demais serviços
# =========================
echo "🚀 Subindo serviços do Airflow em segundo plano ..."
${COMPOSE} up -d

# =========================
# Espera healthcheck do API Server (porta ${API_PORT})
# =========================
echo "⏳ Aguardando API Server saudável em http://localhost:${API_PORT}/api/v2/version ..."
for i in {1..60}; do
  if curl -fsS "http://localhost:${API_PORT}/api/v2/version" >/dev/null; then
    echo "✅ API Server OK."
    break
  fi
  sleep 2
done

echo "🎉 Airflow no ar!
- Compose: ${COMPOSE}
- Pasta:   $(pwd)
- API:     http://localhost:${API_PORT}/api/v2/version

Dicas:
- Logs em tempo real:  ${COMPOSE} logs -f
- Reiniciar tudo:      ${COMPOSE} restart
- Parar:               ${COMPOSE} down
"
