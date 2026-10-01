// Camada de serviço — leitura (só leitura) das ocorrências registadas no
// Scriptorium: mesma tabela `ocorrencias` do projeto Supabase partilhado
// (ver Scriptorium/db/schema.sql), ligada pelo mesmo `alunos.id`.

const ScriptoriumService = {
  async getOcorrenciasByAluno(alunoId) {
    const { data, error } = await window.supabase
      .from("ocorrencias")
      .select("*, professores(nome)")
      .eq("aluno_id", alunoId)
      .order("data", { ascending: false })
      .order("created_at", { ascending: false });
    if (error) throw error;
    return data || [];
  },
};
