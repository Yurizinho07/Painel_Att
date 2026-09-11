# Sinapsi — especificação inicial

Status: primeira implementação criada na pasta web, com testes locais de regras, Excel e políticas de banco. Integração externa em configuração; não liberar dados reais antes de validar contas, MFA e banco no projeto Supabase. Campos dos formulários conferidos nos prints enviados pelo usuário.

## Objetivo

Centralizar o trabalho da recepção do SINAPSI, clínica-escola de Psicologia da Atitus em Porto Alegre, em um sistema web responsivo nas cores branco, preto e verde.

## Premissas a confirmar

- Inicialmente haverá duas contas individuais: o proprietário como administrador e a recepcionista como operadora. Apenas o administrador poderá criar novos usuários, em tela adicional exclusiva. Duas contas é a situação inicial, não um limite permanente.
- O volume de dados é considerado pequeno, sem estimativa numérica ou limite de 150 registros.
- Dois pacientes ativos é a referência para sinalização, não um limite: alunos com 0 ou 1 ficam destacados como “Aguardando pacientes”; com 2 ou mais, o destaque desaparece. Novos vínculos continuam permitidos.
- Cadastros de pacientes e alunos não criam contas de acesso.
- A recepcionista poderá cadastrar pacientes e alunos manualmente ou importar as planilhas geradas pelas respostas aos formulários.
- Os formulários originais determinarão os campos finais; não solicitar dados desnecessários.

## Páginas

| Página | Funções |
| --- | --- |
| Visão geral | Agenda do dia, triagens pendentes, pessoas aguardando vaga e capacidade dos alunos |
| Triagem | Fila de inscrições, contato, agendamento, reagendamento, presença e resultado administrativo |
| Agenda | Visão diária e semanal, filtros por aluno, triagem e atendimento; identificação de conflitos |
| Pacientes | Cadastro, disponibilidade, responsável quando aplicável, situação e histórico de vínculos |
| Alunos | Cadastro, semestre de estágio, supervisão, disponibilidades, quantidade de pacientes ativos e destaque para quem tem menos de 2 |
| Alocação | Encontrar alunos com disponibilidade compatível, selecionar paciente e confirmar vínculo |
| Usuários (somente administrador) | Criar contas autorizadas; acesso e operações administrativos protegidos no servidor |

Todas as páginas operacionais devem oferecer importação e exportação de Excel. Na visão geral, exportação pode reunir as listas em abas; qualquer importação deve identificar explicitamente a entidade de destino.

## Fluxo de pacientes

Inscrito → aguardando contato → triagem agendada → triagem realizada → aguardando vaga → em atendimento → encerrado.

Prever também desistência, encaminhamento externo, ausência e reagendamento. Resultado da triagem é registrado por pessoa autorizada; o sistema não toma decisões clínicas.

Encerramento registra data e motivo administrativo e encerra o vínculo ativo, liberando a vaga do aluno. Preservar histórico de atendimentos e vínculos conforme política institucional de retenção. Novo ingresso abre novo episódio, sem duplicar automaticamente a pessoa.

## Regras informadas

- Atendimentos presenciais em Porto Alegre, por estagiários supervisionados por professores.
- Idade mínima de 7 anos.
- Renda familiar por pessoa de até R$ 2.000.
- Não podem possuir os vínculos informados: funcionário Atitus, estudante Atitus ou familiar de aluno de Psicologia da Atitus.
- Primeira consulta gratuita; demais sessões a R$ 20.
- Sinalizar critérios cadastrais para conferência da equipe, sem automatizar decisão clínica.
- Somente alunos da Atitus podem atender pacientes, no contexto de estágio de Psicologia supervisionado já definido. Registrar confirmação de vínculo institucional no cadastro do aluno; informação desconhecida fica pendente de conferência antes de permitir alocação.
- A quantidade de pacientes não bloqueia vínculos: 0 ou 1 gera destaque “Aguardando pacientes”; 2 ou mais remove o destaque, mantendo a quantidade real visível e a ação de adicionar disponível. Aplicar a mesma regra em cadastro manual e importação, sem impor teto de 2 ou 6.
- Impedir sobreposição de agenda do paciente e do aluno. Duração da sessão, salas, recorrência e horários de funcionamento precisam ser definidos.
- Considerar disponibilidade tanto do paciente quanto do aluno; seleção final é da equipe.

## Excel

- Formato .xlsx, com modelo de colunas por entidade.
- Prévia antes de gravar, mapeamento de colunas e validação de campos e referências.
- Informar erros por linha e possíveis duplicidades; nomes iguais não bastam para identificar a mesma pessoa.
- Atualizações de registros existentes devem ser explícitas, usando identificador estável.
- Importação deve obedecer às mesmas regras de autorização, capacidade e agenda do cadastro manual.
- Confirmação atômica do lote validado, sem gravações parciais silenciosas.
- Exportação respeita filtros escolhidos, informa escopo e grava texto como texto, evitando fórmulas originadas de campos livres.
- Registrar quem importou ou exportou e quando; não copiar conteúdo sensível para logs.

## Formulário de alunos — campos conferidos nos prints

Todos os campos exibidos estão marcados como obrigatórios:

- Nome completo.
- Professora supervisora (seleção única): Mariana Ungaretti, Francielle Beria, Fernanda Cerutti, Vera Ramires ou Outro com texto livre.
- Semestre de estágio (seleção única): Clínico 1 ou Clínico 2.
- Quantidade de pacientes no momento (seleção única): 0 a 6.
- Disponibilidade de atendimento clínico presencial por dia (seleção múltipla): 08h, 09h, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h, 20h e 21h, ou “Não tenho disponibilidade neste dia”.

O print mostra segunda-feira; o usuário informou que as perguntas dos demais dias são iguais. Confirmar se o formulário inclui sábado e domingo antes de fechar o modelo de importação. Horários são opções de início; não comprovam duração de sessão de uma hora.

Interface proposta: grade semanal com seleção de múltiplos horários por dia. “Sem disponibilidade” deve ser incompatível com horários selecionados no mesmo dia. Na importação, combinação contraditória deve ser apresentada para correção.

Não acrescentar CPF, telefone, e-mail ou matrícula ao cadastro de alunos sem necessidade confirmada.

### Quantidade declarada e ocupação

Regra esclarecida pelo usuário: dois pacientes é uma referência de distribuição, sem bloqueio acima desse número. A escala de 0 a 6 é apenas o formato do formulário de origem, não um teto do sistema. Usar o rótulo “Aguardando pacientes” para 0 ou 1, evitando confusão com pendências cadastrais. Com 2 ou mais, mostrar a quantidade sem sinalização de falta de pacientes. Recalcular ao criar ou encerrar vínculos.

Guardar a quantidade declarada no formulário como informação de entrada, separada dos vínculos identificados no painel. Durante a migração, reconciliar os pacientes já atendidos antes de sinalizar falta de pacientes; não somar a declaração aos vínculos nem ignorar pacientes existentes. Quantidade acima de 2 não é erro nem exige aprovação adicional. Após a reconciliação, calcular ocupação pelos vínculos ativos.

## Formulário de pacientes — campos conferidos nos prints

| Campo | Formato observado | Obrigatório no Forms |
| --- | --- | --- |
| Nome completo do paciente | Texto | Sim |
| Idade | Resposta aberta | Sim |
| Nome do responsável, se menor de idade | Texto | Sem asterisco; condicional no enunciado |
| Principal motivo da busca por atendimento psicológico neste momento | Texto | Sim |
| Renda familiar total | Resposta aberta | Sim |
| Telefone | Texto | Sim |
| Contato de emergência: nome, vínculo e telefone | Um campo de texto conjunto | Sim |
| E-mail | Texto | Sim |
| Autoriza outro estagiário como observador na primeira conversa | Sim / Não | Sim |
| Vínculo próprio ou de familiar direto com a Atitus; se sim, qual | Texto | Sim |
| Beneficiário de Bolsa Família (com comprovação) | Sim / Não | Sim |
| Disponibilidade para atendimentos futuros | Múltiplos dias e turnos | Sim |
| Declara informações verdadeiras e garante entrega do comprovante de renda na data agendada | Sim / Não, uma declaração conjunta | Sim |

Disponibilidade: segunda a sexta, com manhã (08h–12h), tarde (13h–17h) e noite (18h–21h). Há 15 opções. Isso confirma os dias do formulário de pacientes, não necessariamente os dias do formulário de alunos.

### Cadastro manual, importação e proteção das informações

- Reproduzir os campos necessários no cadastro manual e mapear as respectivas colunas na importação; não acrescentar CPF, endereço ou data de nascimento sem necessidade confirmada.
- Preservar idade como idade declarada na inscrição, com data de referência quando conhecida. Não inventar data de nascimento nem apresentar idade antiga como atual.
- Contato de emergência pode ser dividido em nome, vínculo e telefone no cadastro manual. Na importação, preservar o texto original quando a separação não for segura e permitir revisão.
- Ausência de resposta não equivale a “Não”. Preservar respostas negativas e sinalizar campos ausentes para revisão.
- Registrar autorização do observador separadamente. Resposta “Não” deve ser respeitada na organização da triagem, sem impedir cadastro por esse motivo.
- A declaração final é conjunta: não inferir consentimento genérico de uso de dados, entrega efetiva de comprovante nem comprovação de renda a partir dela.
- A resposta sobre Bolsa Família não comprova recebimento de documento e não estabelece automaticamente isenção de sessão.
- Motivo da busca fica no detalhe protegido do cadastro/triagem, fora de cartões da agenda e listagens gerais. Exportação desse campo deve ter escopo explícito e respeitar autorização.
- Preservar o nome do responsável quando informado e sinalizar sua ausência em cadastro de menor para conferência da recepção.

### Compatibilidade de horários

Cruzar turnos declarados pelo paciente com horários do aluno para sugerir possibilidades. Confirmar horário específico com o paciente antes de agendar. A sessão completa precisa caber no intervalo disponível; confirmar duração e interpretação dos limites antes de automatizar sugestões nas bordas dos turnos. Não presumir disponibilidade no intervalo de 12h a 13h ou de 17h a 18h.

### Divergências e lacunas do formulário

- Renda: acrescentar ao cadastro e ao modelo Excel a coluna “Quantidade de integrantes da família”, incluindo o paciente, conforme autorização do usuário para completar campos faltantes. Aceitar inteiro positivo e calcular renda por pessoa = renda familiar total / integrantes. A renda por pessoa é derivada, não precisa de digitação. Planilhas antigas sem a coluna continuam importáveis; deixar valor desconhecido e renda por pessoa como “A conferir”, sem inventar denominador nem rejeitar pelo total. O campo adicional não constava no Forms original.
- Vínculos: esclarecido pelo usuário que nenhum estudante da Atitus pode ser paciente, independentemente do curso. Esta regra prevalece sobre a introdução do Forms. Preservar também os impedimentos já informados para funcionários e familiares de alunos de Psicologia. Manter resposta original e conferência estruturada de vínculo; respostas ambíguas ficam pendentes, sem inferir elegibilidade. Somente alunos da Atitus podem ser vinculados como responsáveis pelos atendimentos, conforme contexto de estágio supervisionado.
- A introdução menciona atendimentos individuais, de casal e de família, mas não há pergunta de modalidade nos prints. Confirmar necessidade de suportar grupos e como esses atendimentos entram na contagem de pacientes do aluno antes de modelar essa extensão.

## Arquitetura proposta

Aplicação web com interface responsiva e Supabase para PostgreSQL e autenticação. A escolha do framework permanece aberta; o arquivo app.py vazio não estabelece uma arquitetura existente.

Entidades propostas: operadores autorizados, pacientes, alunos, disponibilidades, episódios de atendimento, triagens, vínculos paciente-aluno, agendamentos e eventos de auditoria.

Paciente, episódio, vínculo e agendamento são separados para permitir encerramento, retorno e mudança de aluno sem perder o histórico.

## Segurança a implementar e verificar

- Inicialmente duas contas individuais, sem inscrição pública. Somente o proprietário administrador pode criar novos usuários; a restrição deve valer no servidor, além de ocultar a tela da recepcionista.
- Lista de operadores autorizados, conferida no banco; autenticar não basta para obter acesso.
- MFA obrigatório, com autorização exigindo segundo fator também nas políticas de acesso.
- Row Level Security em todas as tabelas acessíveis pela aplicação.
- Segredos administrativos somente no servidor; nunca na interface ou em arquivos versionados.
- HTTPS, gestão de sessão, recuperação de acesso e bloqueio efetivo de operador removido.
- Auditoria de alterações e exportações, acesso restrito e ausência de dados clínicos em logs.
- Não persistir dados de pacientes em localStorage.
- Definir backups, testar restauração e estabelecer retenção com a instituição antes do uso real.
- Manter a primeira versão restrita à organização administrativa; prontuário clínico exige escopo próprio.

Poucos registros não eliminam a necessidade de controle de acesso e proteção dos dados. As políticas SQL foram implementadas e testadas localmente; aplicação e validação no Supabase real ainda são etapas de configuração.

## Pendências

1. Formulários de pacientes e alunos recebidos em prints; mapeamento inicial registrado neste documento.
2. Perfis de acesso confirmados: proprietário administrador e recepcionista operadora; volume pequeno sem número definido.
3. Definir duração das sessões, recorrência, salas e se vínculos exclusivamente de triagem entram na contagem de pacientes do aluno.
4. Receber exemplos das planilhas com dados fictícios para mapear importação.
5. Configurar projeto de banco e autenticação antes da integração e validar fluxos com dados fictícios.
6. Confirmar quais dias da semana são contemplados no formulário dos alunos; quantidade de pacientes já esclarecida como sinalização sem teto.
7. Confirmar necessidade de atendimentos de casal/família. Renda por pessoa será calculada com coluna adicional de integrantes; impedimento para todos os estudantes Atitus confirmado.

## Referências técnicas consultadas

- https://supabase.com/pricing — plano gratuito informa 500 MB de banco; capacidade não substitui avaliação operacional.
- https://supabase.com/docs/guides/auth — autenticação e integração com RLS.
- https://supabase.com/docs/guides/auth/auth-mfa — MFA e níveis de autenticação.
- https://supabase.com/docs/guides/auth/general-configuration — configuração de cadastro e acesso.
