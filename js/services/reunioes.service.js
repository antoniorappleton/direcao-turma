// Camada de serviço — reuniões com EE por aluno (pedida/agendada/realizada).

const ReunioesService = {
  async getByAluno(alunoId) {
    const { data, error } = await window.supabase
      .from("reunioes_aluno")
      .select("*")
      .eq("aluno_id", alunoId)
      .order("data_agendada", { ascending: true, nullsFirst: false })
      .order("data_pedida", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  // Para o calendário do dashboard: reuniões já com data marcada, de todos
  // os alunos das turmas do DT.
  async getAgendadasByAlunos(alunoIds) {
    if (!alunoIds.length) return [];
    const { data, error } = await window.supabase
      .from("reunioes_aluno")
      .select("*, alunos(nome)")
      .in("aluno_id", alunoIds)
      .in("estado", ["agendada", "confirmada"])
      .not("data_agendada", "is", null);
    if (error) throw error;
    return data || [];
  },

  async create(reuniao) {
    const { data, error } = await window.supabase
      .from("reunioes_aluno")
      .insert([reuniao])
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async update(id, campos) {
    const { data, error } = await window.supabase
      .from("reunioes_aluno")
      .update(campos)
      .eq("id", id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async delete(id) {
    const { error } = await window.supabase.from("reunioes_aluno").delete().eq("id", id);
    if (error) throw error;
  },
};
