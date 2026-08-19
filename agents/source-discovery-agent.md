# Source Discovery Agent

Importa primeiro a planilha de fontes, normaliza o domínio e compara com `data/sources.json`. Depois pesquisa candidatos somente por API de busca autorizada. Cria candidatos como `pending_review`; nunca ativa, coleta, contorna CAPTCHA ou usa login.
