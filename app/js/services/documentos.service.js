// Camada de serviço — documentos (de aluno, turma ou professor), com
// upload/download via Supabase Storage (bucket privado, acesso só por
// signed URL).

const DOCUMENTOS_BUCKET = "documentos-dt";

// `documentos` tem duas FKs para `professores` (criado_por e professor_id,
// esta desde db/add_documentos_professor.sql) — o embed tem de indicar qual
// delas usar (professores!criado_por), senão o PostgREST recusa o pedido
// por ambiguidade (erro PGRST201).
const SELECT_COM_AUTOR = "*, professores!criado_por(nome)";

const DocumentosService = {
  async getByAluno(alunoId) {
    const { data, error } = await window.supabase
      .from("documentos")
      .select(SELECT_COM_AUTOR)
      .eq("aluno_id", alunoId)
      .order("criado_em", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  async getByTurma(turmaId) {
    const { data, error } = await window.supabase
      .from("documentos")
      .select(SELECT_COM_AUTOR)
      .eq("turma_id", turmaId)
      .order("criado_em", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  async getByProfessor(professorId) {
    const { data, error } = await window.supabase
      .from("documentos")
      .select(SELECT_COM_AUTOR)
      .eq("professor_id", professorId)
      .order("criado_em", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  async upload(file, path) {
    const { error } = await window.supabase.storage.from(DOCUMENTOS_BUCKET).upload(path, file);
    if (error) throw error;
    return path;
  },

  async create(documento) {
    const { data, error } = await window.supabase
      .from("documentos")
      .insert([documento])
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async getSignedUrl(path, expiresIn = 3600) {
    const { data, error } = await window.supabase.storage
      .from(DOCUMENTOS_BUCKET)
      .createSignedUrl(path, expiresIn);
    if (error) throw error;
    return data.signedUrl;
  },

  async delete(id, ficheiroPath) {
    if (ficheiroPath) {
      const { error: storageError } = await window.supabase.storage
        .from(DOCUMENTOS_BUCKET)
        .remove([ficheiroPath]);
      if (storageError) throw storageError;
    }
    const { error } = await window.supabase.from("documentos").delete().eq("id", id);
    if (error) throw error;
  },
};
