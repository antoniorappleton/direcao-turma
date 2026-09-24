// Camada de serviço — alunos, com o histórico de matrículas por ano letivo.

const AlunosService = {
  async getByTurma(turmaId) {
    const { data, error } = await window.supabase
      .from("alunos")
      .select("*")
      .eq("turma_id", turmaId)
      .order("nome");
    if (error) throw error;
    return data || [];
  },

  async getById(alunoId) {
    const { data, error } = await window.supabase
      .from("alunos")
      .select("*, aluno_encarregados(*, encarregados(*))")
      .eq("id", alunoId)
      .maybeSingle();
    if (error) throw error;
    return data;
  },

  async getHistoricoMatriculas(alunoId) {
    const { data, error } = await window.supabase
      .from("matriculas")
      .select("*, turmas(*), anos_letivos(*)")
      .eq("aluno_id", alunoId)
      .order("data_inicio", { ascending: false });
    if (error) throw error;
    return data || [];
  },
};
