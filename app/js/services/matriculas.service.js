// Camada de serviço — histórico de matrículas do aluno (tabela `matriculas`,
// ver db/schema.sql). A leitura (com join a turmas/anos_letivos) já existe
// em AlunosService.getHistoricoMatriculas; este ficheiro trata da escrita
// (criar/editar/apagar entradas) e da lista de anos letivos para o select.

const MatriculasService = {
  async getAnosLetivos() {
    const { data, error } = await window.supabase
      .from("anos_letivos")
      .select("*")
      .order("nome", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  async create(matricula) {
    const { data, error } = await window.supabase
      .from("matriculas")
      .insert([matricula])
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async update(id, changes) {
    const { error } = await window.supabase.from("matriculas").update(changes).eq("id", id);
    if (error) throw error;
  },

  async delete(id) {
    const { error } = await window.supabase.from("matriculas").delete().eq("id", id);
    if (error) throw error;
  },
};
