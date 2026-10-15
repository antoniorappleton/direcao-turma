// Camada de serviço — tarefas pessoais do professor ("As minhas tarefas" em
// app/perfil.html, ver db/add_tarefas.sql). Cada professor só vê as suas.

const TarefasService = {
  async getByProfessor(professorId) {
    const { data, error } = await window.supabase
      .from("tarefas")
      .select("*")
      .eq("professor_id", professorId)
      .order("criado_em", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  async create(tarefa) {
    const { data, error } = await window.supabase
      .from("tarefas")
      .insert([tarefa])
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async update(id, changes) {
    const { error } = await window.supabase.from("tarefas").update(changes).eq("id", id);
    if (error) throw error;
  },

  async delete(id) {
    const { error } = await window.supabase.from("tarefas").delete().eq("id", id);
    if (error) throw error;
  },
};
