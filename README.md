# Apache Airflow em Docker (stack leve para desenvolvimento local)

Este repositório traz uma configuração do **Apache Airflow** pronta para rodar em ambiente local via **Docker Compose**, utilizando o **PostgreSQL 13** como backend de metadados.

A proposta é oferecer um ambiente **mínimo e funcional** para desenvolvimento e testes de DAGs, inspirado na [documentação oficial do Airflow](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html), mas simplificado e otimizado para rodar localmente.

---

## 🔎 O que está incluído?

- **Airflow Services**:  
  - `airflow-apiserver`  
  - `airflow-scheduler`  
  - `airflow-dag-processor`  
  - `airflow-triggerer`  
  - `airflow-init` (migração + criação de usuário admin)  
  - `airflow-cli` (opcional para debug)  

- **Banco de dados**:  
  - `postgres:13` rodando como serviço dentro do Compose.  

- **Volumes mapeados** para facilitar o desenvolvimento:  
  - `./dags` → DAGs  
  - `./logs` → Logs  
  - `./plugins` → Plugins customizados  
  - `./config` → Configurações  

---

## 🚀 Como rodar

1. Clone este repositório:
   ```bash
   git clone https://github.com/<sua-org>/<seu-repo>.git
   cd <seu-repo>
   ```

2. Dê permissão de execução ao script:
   ```bash
   chmod +x run.sh
   ```

3. Execute:
   ```bash
   ./run.sh
   ```

Esse script:
- Cria a pasta `airflow-docker` com a estrutura mínima (`dags`, `logs`, `plugins`, `config`).
- Gera um `.env` padrão (caso não exista).
- Executa `airflow-init` para preparar o banco de dados no Postgres 13 e criar o usuário admin.
- Sobe todos os contêineres do Airflow em segundo plano.
- Aguarda até que o **API Server** esteja saudável em:  
  👉 [http://localhost:8080/api/v2/version](http://localhost:8080/api/v2/version)

---

## 📂 Estrutura do projeto

```
.
├── docker-compose.yml   # Serviços Airflow + Postgres 13
├── run.sh               # Script automatizado para subir o ambiente
├── dags/                # Suas DAGs vão aqui
├── logs/                # Logs de execução
├── plugins/             # Plugins customizados
└── config/              # Configurações adicionais
```

---

## ⚙️ Variáveis de ambiente importantes

- `AIRFLOW_IMAGE_NAME` → Imagem base do Airflow (default: `apache/airflow:3.0.1`)  
- `AIRFLOW_UID` → UID do usuário host (garante permissões corretas nos volumes)  
- `AIRFLOW_PROJ_DIR` → Pasta base do projeto (default: `.`)  
- `_AIRFLOW_WWW_USER_USERNAME` → Usuário admin (default: `airflow`)  
- `_AIRFLOW_WWW_USER_PASSWORD` → Senha admin (default: `airflow`)  

> Todas podem ser ajustadas no arquivo `.env`.

---

## 🔧 Comandos úteis

```bash
# Subir os serviços manualmente
docker compose up -d

# Ver logs
docker compose logs -f

# Reiniciar
docker compose restart

# Derrubar (mantém volumes)
docker compose down
```

---

## 📊 Health Checks

- Scheduler: `http://localhost:8974/health`  
- API Server: `http://localhost:8080/api/v2/version`  

Esses checks são configurados no `docker-compose.yml` e seguem as recomendações da [documentação de health do Airflow](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/logging-monitoring/check-health.html).

---

## 👩‍💻 Exemplo de DAG mínima

Para validar que o ambiente está funcionando, crie o arquivo `dags/hello_world.py` com o seguinte conteúdo:

```python
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id="hello_world",
    start_date=datetime(2025, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    tags=["example"],
) as dag:
    hello = BashOperator(
        task_id="say_hello",
        bash_command="echo 'Hello, Airflow!'"
    )
```

Após salvar:
- Acesse a UI do Airflow em [http://localhost:8080](http://localhost:8080) (usuário/senha: `airflow/airflow`).  
- Procure a DAG `hello_world` e execute-a manualmente.  
- O log da tarefa mostrará a saída **Hello, Airflow!**.  

---

## ⚠️ Aviso sobre produção

Essa configuração é **apenas para desenvolvimento local**.  
Para rodar em produção, recomenda-se utilizar:
- [Helm Chart oficial do Airflow](https://airflow.apache.org/docs/helm-chart/stable/index.html)  
- Kubernetes ou outro orquestrador de contêineres  
- Configuração de alta disponibilidade, autoscaling e segurança adequadas.  

---

## 📚 Referências oficiais

- [Airflow — Docker Compose Quick Start](https://airflow.apache.org/docs/apache-airflow/stable/howto/docker-compose/index.html)  
- [Airflow — Health Checks](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/logging-monitoring/check-health.html)  
- [Airflow — Production Deployment](https://airflow.apache.org/docs/apache-airflow/stable/production-deployment.html)  

---

👉 Esse setup foi pensado para quem quer **subir rápido o Airflow localmente** e testar DAGs sem complexidade extra.  
