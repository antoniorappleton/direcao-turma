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

// NOTA: turmas.diretor_turma é hoje texto livre (nome), não uma referência ao
// professor. Esta função funciona por nome enquanto isso não muda — quando
// `turmas.diretor_turma_id` (FK para professores) existir, trocar a
// comparação por turma.diretor_turma_id === professor.id.
//
// Propositadamente sem bypass de admin: representa só "é o diretor desta
// turma", usado para decidir "as minhas turmas" por defeito no dashboard.
// Para controlo de acesso (pode ver esta turma, mesmo não sendo o diretor)
// usar canAccessTurma.
function isDiretorDaTurma(professor, turma) {
  if (!professor || !turma) return false;
  return turma.diretor_turma === professor.nome;
}

// `minhasTurmaIds` é a seleção do próprio professor em professor_turmas
// (ver minhas-turmas.html) — as turmas que leciona, escolhidas por ele.
// Admins veem sempre tudo; os restantes só acedem ao que selecionaram,
// independentemente de serem ou não o DT (ver isDiretorDaTurma, que só
// serve para pré-marcar o checklist, não para controlar acesso).
function canAccessTurma(professor, turma, minhasTurmaIds = []) {
  return isAdmin(professor) || minhasTurmaIds.includes(turma.id);
}
