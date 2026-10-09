// Camada de serviço — a interface nunca chama window.supabase diretamente.
// Reutiliza as tabelas `turmas`/`ciclos` já existentes no Supabase do Scriptorium.

const TurmasService = {
  async getAll() {
    const { data, error } = await window.supabase
      .from("turmas")
      .select("*, ciclos(*)")
      .order("nome");
    if (error) throw error;
    return data || [];
  },

  async getById(turmaId) {
    const { data, error } = await window.supabase
      .from("turmas")
      .select("*, ciclos(*)")
      .eq("id", turmaId)
      .maybeSingle();
    if (error) throw error;
    return data;
  },

  async getByDiretor(professorId) {
    const { data, error } = await window.supabase
      .from("turmas")
      .select("*, ciclos(*)")
      .eq("diretor_turma_id", professorId);
    if (error) throw error;
    return data || [];
  },
};
