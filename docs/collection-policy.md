# Política de coleta

O catálogo inicial veio da planilha de imobiliárias fornecida. Apenas a fonte de referência Chaves na Mão está configurada como `active`; as demais estão em `pending_review` e não recebem tráfego automático.

Cada execução verifica `robots.txt`, identifica-se com um agente próprio, tem timeout e limita o corpo retornado. Falha ao ler `robots.txt` bloqueia a coleta. A evidência HTML e o manifesto com hash, URL e horário são preservados localmente. A extração/publicação de anúncios será adicionada somente depois de testes por fonte e aprovação explícita.
