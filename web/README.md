# Sinapsi — aplicação web

Interface React/TypeScript com Supabase Auth e PostgreSQL. Consulte [SETUP.md](SETUP.md) para preparar o banco, as contas e as variáveis locais.

- `npm ci`: instalar dependências.
- `npm run dev`: abrir a prévia local em http://localhost:5173.
- `npm run build`: compilar para hospedagem.
- `node tests/database.mjs`: testar a migração e as políticas no PostgreSQL local em memória.
- `node tests/domain-excel.mjs`: testar regras e exportação Excel.

O projeto usa o starter Sites/Vinext. `.env.local`, dados de pacientes, dependências e arquivos gerados não devem entrar no Git.
