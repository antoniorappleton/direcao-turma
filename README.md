# Direção de Turma — Comunidade CSJ Ramalhão

Segunda app da Comunidade CSJ Ramalhão, a seguir ao [Scriptorium](https://github.com/antoniorappleton/scriptorium).
Repositório independente (deploy próprio), mas **partilha o mesmo projeto Supabase**
do Scriptorium — mesmas tabelas `professores`, `alunos`, `turmas`, `ciclos`, e por
estarem ambas sob `antoniorappleton.github.io`, também partilham sessão de login
(SSO automático via `localStorage` da mesma origem).

## Funcionalidades previstas

- Dashboard do diretor de turma: turmas de que é responsável.
- Ficha do aluno: dados pessoais, encarregados de educação, contactos, observações, documentos.
- Histórico de matrículas por ano letivo (um aluno pode mudar de turma sem perder histórico).
- Horário, conselho de turma, documentos (atas, autorizações, modelos).

## Estrutura

```
app/
├── index.html, login.html
├── manifest.json, service-worker.js
├── css/styles.css              → copiado do Scriptorium (mesmo design system)
├── js/
│   ├── core/ (config.js, session.js, auth.js, permissions.js)
│   ├── services/ (turmas.service.js, alunos.service.js, encarregados.service.js)
│   └── utils/ (dates.js)
└── data/mock/                  → dados fictícios para desenhar UI antes de ligar tudo
db/
├── schema.sql                  → tabelas novas (aditivo, não mexe no que já existe)
└── rls_exemplo.sql             → exemplo de política de permissões (não ativado ainda)
```

## Passos para pôr a funcionar

1. **Correr `db/schema.sql`** no SQL Editor do mesmo projeto Supabase do Scriptorium
   (`pllmyptwuvxryxfeufcm`). É seguro — só cria tabelas novas, não altera nada existente.
2. **Criar o repositório no GitHub** (ex: `direcao-turma`) e fazer push deste código.
3. **Configurar GitHub Pages**: Settings → Pages → Source → branch `gh-pages` (criado
   automaticamente pelo workflow no primeiro push).
4. Testar login com uma conta já existente em `professores`.

## O que falta (próximos passos)

- Views de `turma.html`, `alunos.html`, `aluno.html`, `horario.html`, `documentos.html`
  (só o dashboard inicial e o login estão feitos).
- Decidir se `turmas.diretor_turma` passa de texto livre para `diretor_turma_id`
  (FK para `professores`) — necessário para os diretores de turma terem acesso
  restrito só à sua turma via RLS.
- Ativar RLS nas tabelas partilhadas (ver `db/rls_exemplo.sql`) — com cuidado para
  não quebrar o Scriptorium.
