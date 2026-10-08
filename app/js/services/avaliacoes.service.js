// Camada de serviço — avaliações dos alunos por disciplina/período (ver
// db/add_avaliacoes.sql). Toda a agregação (médias, contagens, agrupamento
// por período/disciplina/aluno) é feita no cliente sobre os dados já
// carregados — não há necessidade de SQL de agregação para o volume
// esperado por turma/ano.

const AvaliacoesService = {
  async getByTurma(turmaId) {
    const { data, error } = await window.supabase
      .from("avaliacoes")
      .select("*, alunos(nome)")
      .eq("turma_id", turmaId)
      .order("data", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  async getByAluno(alunoId) {
    const { data, error } = await window.supabase
      .from("avaliacoes")
      .select("*")
      .eq("aluno_id", alunoId)
      .order("data", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  // Junta o plano curricular da turma (db/add_disciplinas.sql, quando
  // existir) com as disciplinas já usadas em avaliações registadas — assim
  // uma disciplina escrita à mão que não esteja no catálogo continua a
  // aparecer nas sugestões seguintes.
  async getDisciplinasDaTurma(turmaId) {
    const [catalogo, usadas] = await Promise.all([
      // db/add_disciplinas.sql é opcional — se ainda não tiver corrido
      // nesta base de dados, a tabela não existe; não deve impedir o resto
      // de funcionar, só perde-se a pré-sugestão do plano curricular.
      window.supabase.from("turma_disciplinas").select("disciplinas(nome)").eq("turma_id", turmaId).then(
        (res) => res,
        (err) => ({ data: [], error: err }),
      ),
      window.supabase.from("avaliacoes").select("disciplina").eq("turma_id", turmaId),
    ]);
    if (catalogo.error) console.warn("Catálogo de disciplinas indisponível (ver db/add_disciplinas.sql)", catalogo.error);
    if (usadas.error) throw usadas.error;
    const disciplinas = new Set([
      ...(catalogo.data || []).map((td) => td.disciplinas?.nome).filter(Boolean),
      ...(usadas.data || []).map((a) => a.disciplina).filter(Boolean),
    ]);
    return Array.from(disciplinas).sort((a, b) => a.localeCompare(b, "pt"));
  },

  async create(avaliacao) {
    const { data, error } = await window.supabase
      .from("avaliacoes")
      .insert([avaliacao])
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async update(id, changes) {
    const { error } = await window.supabase.from("avaliacoes").update(changes).eq("id", id);
    if (error) throw error;
  },

  async delete(id) {
    const { error } = await window.supabase.from("avaliacoes").delete().eq("id", id);
    if (error) throw error;
  },
};
