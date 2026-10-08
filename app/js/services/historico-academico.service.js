// Camada de serviço — histórico académico de anos letivos anteriores, por
// aluno/disciplina (ver db/add_historico_disciplinas.sql). Só leitura por
// agora: a importação/edição deste histórico é feita via SQL, não pela UI.

const HistoricoAcademicoService = {
  async getByAluno(alunoId) {
    const { data, error } = await window.supabase
      .from("historico_disciplinas")
      .select("*")
      .eq("aluno_id", alunoId)
      .order("ano_letivo", { ascending: false });
    if (error) throw error;
    return data || [];
  },
};
