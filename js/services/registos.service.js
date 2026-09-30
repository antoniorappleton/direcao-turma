// Camada de serviço — registos de acompanhamento do aluno (timeline do DT).

const RegistosService = {
  async getByAluno(alunoId) {
    const { data, error } = await window.supabase
      .from("registos_aluno")
      .select("*, professores(nome)")
      .eq("aluno_id", alunoId)
      .order("data", { ascending: false })
      .order("criado_em", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  // Para o calendário do dashboard: seguimentos ainda por fazer, de todos os
  // alunos das turmas do DT.
  async getSeguimentosPendentesByAlunos(alunoIds) {
    if (!alunoIds.length) return [];
    const { data, error } = await window.supabase
      .from("registos_aluno")
      .select("*, alunos(nome)")
      .in("aluno_id", alunoIds)
      .eq("seguimento_necessario", true)
      .eq("seguimento_concluido", false)
      .not("data_seguimento", "is", null);
    if (error) throw error;
    return data || [];
  },

  async create(registo) {
    const { data, error } = await window.supabase
      .from("registos_aluno")
      .insert([registo])
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async marcarSeguimentoConcluido(id) {
    const { error } = await window.supabase
      .from("registos_aluno")
      .update({ seguimento_concluido: true })
      .eq("id", id);
    if (error) throw error;
  },

  async delete(id) {
    const { error } = await window.supabase.from("registos_aluno").delete().eq("id", id);
    if (error) throw error;
  },
};
