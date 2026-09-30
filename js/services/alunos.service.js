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

  async getByTurmas(turmaIds) {
    if (!turmaIds.length) return [];
    const { data, error } = await window.supabase
      .from("alunos")
      .select("*")
      .in("turma_id", turmaIds);
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

  // Via RPC (não update direto): `alunos` só permite escrita a admins na
  // RLS de produção, esta função SECURITY DEFINER só altera numero_interno.
  async updateNumeroInterno(alunoId, numeroInterno) {
    const { error } = await window.supabase.rpc("atualizar_numero_interno_aluno", {
      p_aluno_id: alunoId,
      p_numero_interno: numeroInterno,
    });
    if (error) throw error;
  },
};
