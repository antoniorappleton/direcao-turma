// Camada de serviço — encarregados de educação.

const EncarregadosService = {
  async getByAluno(alunoId) {
    const { data, error } = await window.supabase
      .from("aluno_encarregados")
      .select("*, encarregados(*)")
      .eq("aluno_id", alunoId);
    if (error) throw error;
    return data || [];
  },

  async create(encarregado) {
    const { data, error } = await window.supabase
      .from("encarregados")
      .insert([encarregado])
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async update(id, encarregado) {
    const { error } = await window.supabase
      .from("encarregados")
      .update(encarregado)
      .eq("id", id);
    if (error) throw error;
  },

  async linkToAluno(alunoId, encarregadoId, { principal = false, responsavelLegal = false } = {}) {
    const { error } = await window.supabase.from("aluno_encarregados").insert([
      {
        aluno_id: alunoId,
        encarregado_id: encarregadoId,
        principal,
        responsavel_legal: responsavelLegal,
      },
    ]);
    if (error) throw error;
  },
};
