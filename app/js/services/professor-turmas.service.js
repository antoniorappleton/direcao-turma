// Camada de serviço — turmas que cada professor leciona ("as minhas
// turmas"), escolhidas pelo próprio; definem o acesso no painel DT.

const ProfessorTurmasService = {
  async getIdsByProfessor(professorId) {
    const { data, error } = await window.supabase
      .from("professor_turmas")
      .select("turma_id")
      .eq("professor_id", professorId);
    if (error) throw error;
    return (data || []).map((r) => r.turma_id);
  },

  // Substitui a seleção completa (apaga a anterior e grava a nova) — mais
  // simples do que calcular diffs, e esta tabela só guarda uma escolha por
  // professor, não histórico.
  async setTurmas(professorId, turmaIds) {
    const { error: deleteError } = await window.supabase
      .from("professor_turmas")
      .delete()
      .eq("professor_id", professorId);
    if (deleteError) throw deleteError;

    if (!turmaIds.length) return;

    const { error: insertError } = await window.supabase.from("professor_turmas").insert(
      turmaIds.map((turmaId) => ({ professor_id: professorId, turma_id: turmaId })),
    );
    if (insertError) throw insertError;
  },
};
