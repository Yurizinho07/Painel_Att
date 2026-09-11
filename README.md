# Sinapsi

Painel web para a recepção da clínica-escola de Psicologia SINAPSI/Atitus.

A aplicação está na pasta `web`. A especificação está em `REQUISITOS.md` e as instruções de banco, autenticação e execução estão em `web/SETUP.md`.

```sh
cd web
npm ci
npm run dev
```

Copie `web/.env.example` para `web/.env.local` e preencha as configurações públicas do seu projeto Supabase. Sem configuração, a interface usa somente dados fictícios em memória. Com configuração, exige conta autorizada e MFA.

Funcionalidades: pacientes, alunos, triagem, agenda por dia/semana, alocação, encerramento com histórico, importação/exportação .xlsx e convites de usuários restritos ao administrador.

Os scripts SQL precisam ser aplicados e as configurações externas verificadas antes de usar dados reais. Nunca versionar senhas, chaves secret/service_role ou planilhas de pacientes.

Testes locais (na pasta `web`):

```sh
node tests/database.mjs
node tests/domain-excel.mjs
npx tsc --noEmit
```
