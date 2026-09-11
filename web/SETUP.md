# Sinapsi — configuração do ambiente real

O painel abre em demonstração com dados fictícios enquanto as duas variáveis públicas não estiverem configuradas. Alterações da demonstração ficam apenas em memória. A presença das variáveis desativa a demonstração e exige autenticação e autorização reais.

## Supabase

1. Criar um projeto Supabase. Copiar a URL e a chave publishable para `.env.local`, usando `.env.example`. Nunca usar chave secret/service_role no frontend.
2. Executar `supabase/migrations/001_initial.sql` uma única vez no SQL Editor de um projeto novo. Não executar em banco com tabelas homônimas sem revisar a migração.
3. Em Authentication, desabilitar inscrições públicas. Habilitar TOTP para MFA. Configurar URL do site e redirect URLs exatas, sem curingas, para o ambiente usado.
4. Criar manualmente a primeira conta do proprietário em Authentication. Usar o UUID real da conta para autorizar o administrador no SQL Editor:

```sql
insert into public.operators (id, name, role, active)
values ('UUID-REAL-DO-PROPRIETARIO', 'Seu nome', 'admin', true);
```

5. Instalar/configurar Supabase CLI ou usar o editor de Edge Functions para publicar `supabase/functions/manage-users/index.ts`. Configurar a função com `verify_jwt=false`: a própria função valida o JWT com `auth.getUser` e verifica administrador ativo por RLS, exigindo MFA. Definir o segredo `APP_ORIGIN` com a origem exata do painel (exemplo local: `http://localhost:5173`). A função usa as variáveis internas do Supabase para acesso administrativo; nenhuma delas vai para a aplicação web.
6. Configurar envio de e-mail do Supabase/SMTP para os convites. O administrador cria a conta da recepcionista pela página Usuários. Novos convites sempre recebem perfil operator.
7. No primeiro acesso, cadastrar o autenticador e confirmar o código. Sem MFA confirmado, o banco não retorna dados. A sessão fica em memória; recarregar a página exige novo login, e 30 minutos de inatividade encerram a sessão no cliente.

Para desativar acesso imediatamente, o administrador do projeto pode executar `update public.operators set active=false where id='UUID';`. RLS consulta o estado atual a cada operação; não depende de um papel armazenado no token. A interface desta primeira versão oferece criação/listagem de usuários; desativação fica no projeto Supabase.

## Desenvolvimento

Node >=22.13. `npm ci`, `npm run dev`. Prévia em `http://localhost:5173`. `npm run build` gera o Worker. Este projeto foi criado com o starter Sites/Vinext, React e TypeScript. O arquivo `app.py` na pasta superior não participa do painel.

## Excel

Importar .xlsx, até 2 MB e 500 linhas por aba. Selecionar aba, entidade e correspondência de colunas; validar e confirmar. Um erro invalida o lote inteiro. Fórmulas são rejeitadas na importação. Registros com o mesmo nome pedem conferência, não são mesclados automaticamente. Atualizações exigem IDs estáveis e autorização explícita na janela de importação. Exportação gera valores de texto, não fórmulas. Motivo da busca fica fora por padrão; marcar a opção na tela para incluí-lo. Vínculos e agenda referenciam IDs dos cadastros; exporte os cadastros primeiro.

## Regras implementadas

- 0 ou 1 paciente ativo destaca aluno como “Aguardando pacientes”; 2 ou mais não bloqueia vínculo adicional.
- Dados importados de alunos precisam de conferência do vínculo Atitus e reconciliação dos pacientes existentes antes de apresentar a sinalização de distribuição.
- Paciente precisa ter idade mínima de 7 anos e impedimentos institucionais conferidos para alocação. Renda por pessoa é exibida para conferência humana, sem decisão clínica automática.
- Disponibilidade inicial usa segunda a sexta. Estagiários: 08h a 21h; pacientes: turnos do Forms. Horários nos limites dos turnos não são sugeridos automaticamente.
- Agenda por dia ou semana, filtro por aluno e lista cronológica. Início/fim são explícitos, sem presumir duração institucional. Sobreposição de paciente, aluno ou sala é bloqueada também por constraints do banco.
- Encerramento preserva vínculo e motivo, atualiza paciente e cancela sessões futuras agendadas para o mesmo vínculo.

## Antes de cadastrar pessoas reais

Validar a migração em projeto de teste, os dois perfis, MFA, convites e importação contra o projeto real. Definir política institucional de backups e retenção e testar restauração. As políticas e constraints estão implementadas no código SQL, mas só estarão ativas quando a migração for aplicada. Testes locais não certificam a configuração externa.
