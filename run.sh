#!/usr/bin/env bash
set -Eeuo pipefail

# =========================
# Funções utilitárias
# =========================
die() { echo "❌ $*" >&2; exit 1; }
info(){ echo "ℹ️  $*"; }
ok()  { echo "✅ $*"; }
warn(){ echo "⚠️  $*"; }

# =========================
# Configuráveis (opcional)
# =========================
WEB_PORT="${WEB_PORT:-8080}"      # porta do webserver
API_PORT="${API_PORT:-8081}"      # porta do api-server
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
  die "Docker Compose não encontrado. Instale Docker Desktop ou docker-compose."
fi

# =========================
# Cria .env padrão (se não existir) e carrega variáveis
# =========================
if [[ ! -f .env ]]; then
  cat > .env <<EOF
AIRFLOW_IMAGE_NAME=apache/airflow:3.0.1
AIRFLOW_UID=$(id -u)
AIRFLOW_PROJ_DIR=.
_AIRFLOW_WWW_USER_USERNAME=airflow
_AIRFLOW_WWW_USER_PASSWORD=airflow
EOF
  ok "Criado .env com valores padrão."
fi

# Exporta variáveis do .env para o ambiente atual
set -a
source ./.env
set +a

# Caminhos de trabalho baseados no AIRFLOW_PROJ_DIR (padrão: .)
DAGS_DIR="${AIRFLOW_PROJ_DIR:-.}/dags"
LOGS_DIR="${AIRFLOW_PROJ_DIR:-.}/logs"
PLUGINS_DIR="${AIRFLOW_PROJ_DIR:-.}/plugins"
CONFIG_DIR="${AIRFLOW_PROJ_DIR:-.}/config"

# =========================
# (Opcional) Pré-checagem rápida de Postgres local via pg_isready
# =========================
info "Verificando acesso ao Postgres em ${PG_HOST_ALIAS}:${PG_PORT} ..."
docker run --rm --add-host "${PG_HOST_ALIAS}:host-gateway" postgres:16-alpine \
  pg_isready -h "${PG_HOST_ALIAS}" -p "${PG_PORT}" -t 5 || {
    warn "pg_isready não confirmou. Se estiver em macOS/Windows, ignore. No Linux puro, verifique extra_hosts."
}

# =========================
# Inicializa DB + usuário admin (serviço airflow-init)
# =========================
info "Rodando airflow-init ..."
${COMPOSE} up --pull always -d airflow-init

info "Aguardando término do airflow-init ..."
for i in {1..60}; do
  state="$(${COMPOSE} ps --format json airflow-init | sed -n 's/.*\"State\":\"\\([^\\\"]*\\)\".*/\\1/p')"
  if [[ -z "${state}" || "${state}" != "running" ]]; then
    break
  fi
  sleep 2
done

exit_code="$(${COMPOSE} ps --format json airflow-init | sed -n 's/.*\"ExitCode\":\\([0-9]*\\).*/\\1/p')"
if [[ -n "${exit_code}" && "${exit_code}" != "0" ]]; then
  ${COMPOSE} logs --no-log-prefix airflow-init || true
  die "airflow-init terminou com ExitCode=${exit_code}."
fi
ok "airflow-init concluído."

# =========================
# Aguarda diretório ./dags ser criado pelo Airflow (via volume)
# =========================
info "Aguardando diretório de DAGs criado pelo Airflow em: ${DAGS_DIR} ..."
for i in {1..30}; do
  [[ -d "${DAGS_DIR}" ]] && break
  sleep 1
done
if [[ ! -d "${DAGS_DIR}" ]]; then
  # Se por algum motivo não existir ainda, cria para não bloquear
  warn "Diretório ${DAGS_DIR} ainda não existe; criando localmente."
  mkdir -p "${DAGS_DIR}"
fi

# =========================
# Copia my_first_dag.py para ./dags depois que ela existir
# =========================
SEED_DAG_SRC="my_first_dag.py"
SEED_DAG_DST="${DAGS_DIR}/my_first_dag.py"
if [[ -f "${SEED_DAG_SRC}" ]]; then
  # cp -n: não sobrescreve se já existir no destino
  cp -n "${SEED_DAG_SRC}" "${SEED_DAG_DST}" && ok "DAG de exemplo copiada: ${SEED_DAG_SRC} -> ${SEED_DAG_DST}" || info "DAG já existe em ${SEED_DAG_DST}, mantendo arquivo atual."
else
  warn "Arquivo ${SEED_DAG_SRC} não encontrado na raiz; nenhuma DAG de exemplo foi copiada."
fi

# =========================
# Sobe os demais serviços
# =========================
info "Subindo serviços do Airflow ..."
${COMPOSE} up -d

cat <<MSG

🎉 Airflow no ar!
- Webserver: http://localhost:${WEB_PORT}
- API:       http://localhost:${API_PORT}/api/v2/version

Dicas:
- Logs em tempo real:  ${COMPOSE} logs -f
- Reiniciar tudo:      ${COMPOSE} restart
- Parar:               ${COMPOSE} down

MSG
