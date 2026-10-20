// Permissões — v1 simples, baseada no `role` que já existe em `professores`
// (o mesmo usado pelo Scriptorium: 'admin' | 'user').
//
// Planeado para evoluir para tabelas `permissoes` / `role_permissoes` quando
// houver mais do que 2 papéis (professor / diretor de turma / coordenação /
// direção / secretaria) — nessa altura os checks abaixo passam a consultar
// essas tabelas em vez de comparar strings.

function isAdmin(professor) {
  return professor?.role === "admin";
}

// turmas.diretor_turma_id é FK para professores (ver
// db/add_diretor_turma_id.sql) — turmas.diretor_turma (texto livre) só
// serve hoje para apresentação/denormalização no Scriptorium, já não é
// usado para permissões.
//
// Propositadamente sem bypass de admin: representa só "é o diretor desta
// turma", usado para decidir "as minhas turmas" por defeito no dashboard.
// Para controlo de acesso (pode ver esta turma, mesmo não sendo o diretor)
// usar canAccessTurma.
function isDiretorDaTurma(professor, turma) {
  if (!professor || !turma) return false;
  return turma.diretor_turma_id === professor.id;
}

// `minhasTurmaIds` é a seleção do próprio professor em professor_turmas
// (ver minhas-turmas.html) — as turmas que leciona, escolhidas por ele.
// Admins veem sempre tudo; os restantes acedem ao que selecionaram OU às
// turmas de que são mesmo o DT (turmas.diretor_turma_id), mesmo que nunca
// as tenham adicionado à sua seleção de "Turmas que leciono" — sem este
// bypass, o Painel DT (que lista sempre as turmas por diretor_turma_id,
// não pela seleção) podia mostrar uma turma em que depois se batia em
// "Não tens acesso a esta turma". Reflete no cliente a mesma regra
// aplicada a sério no RLS em db/add_dt_acesso_avaliacoes.sql.
function canAccessTurma(professor, turma, minhasTurmaIds = []) {
  return isAdmin(professor) || minhasTurmaIds.includes(turma.id) || isDiretorDaTurma(professor, turma);
}

// Quem vê tudo sobre o aluno (encarregados, acompanhamento, reuniões,
// documentos, ocorrências, histórico) — admin ou o DT desta turma. Um
// professor só de uma disciplina (não-DT) continua a aceder à turma/aluno
// (canAccessTurma), mas só vê Avaliações — ver turma.html/aluno.html, que
// escondem o resto quando isto dá false. Reflete no cliente a mesma regra
// aplicada a sério no RLS em db/add_acesso_dt_vs_professor.sql
// (is_current_user_dt_da_turma / is_current_user_dt_do_aluno).
function isDTouAdmin(professor, turma) {
  return isAdmin(professor) || isDiretorDaTurma(professor, turma);
}
