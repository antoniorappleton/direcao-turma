// Camada de serviço — alunos, com o histórico de matrículas por ano letivo.

const AlunosService = {
  async getByTurma(turmaId) {
    const { data, error } = await window.supabase
      .from("alunos")
      .select("*")
      .eq("turma_id", turmaId)
      .order("nome");
    if (error) throw error;
    return data || [];
  },

  async getByTurmas(turmaIds) {
    if (!turmaIds.length) return [];
    const { data, error } = await window.supabase
      .from("alunos")
      .select("*")
      .in("turma_id", turmaIds);
    if (error) throw error;
    return data || [];
  },

  async getEmailsEncarregadosByTurmas(turmaIds) {
    if (!turmaIds.length) return [];
    const { data, error } = await window.supabase
      .from("alunos")
      .select("aluno_encarregados(encarregados(email))")
      .in("turma_id", turmaIds);
    if (error) throw error;

    const emails = new Map();
    for (const aluno of data || []) {
      for (const ligacao of aluno.aluno_encarregados || []) {
        const email = ligacao.encarregados?.email?.trim();
        if (email && !emails.has(email.toLowerCase())) emails.set(email.toLowerCase(), email);
      }
    }
    return [...emails.values()];
  },

  async getById(alunoId) {
    const { data, error } = await window.supabase
      .from("alunos")
      .select("*, aluno_encarregados(*, encarregados(*))")
      .eq("id", alunoId)
      .maybeSingle();
    if (error) throw error;
    return data;
  },

  async getHistoricoMatriculas(alunoId) {
    const { data, error } = await window.supabase
      .from("matriculas")
      .select("*, turmas(*), anos_letivos(*)")
      .eq("aluno_id", alunoId)
      .order("data_inicio", { ascending: false });
    if (error) throw error;
    return data || [];
  },

  // Via RPC (não update direto): `alunos` só permite escrita a admins na
  // RLS de produção, esta função SECURITY DEFINER só altera numero_interno.
  async updateNumeroInterno(alunoId, numeroInterno) {
    const { error } = await window.supabase.rpc("atualizar_numero_interno_aluno", {
      p_aluno_id: alunoId,
      p_numero_interno: numeroInterno,
    });
    if (error) throw error;
  },

  // Muda o aluno de turma (ver db/add_mudar_turma_aluno.sql) — fecha a
  // matrícula ativa anterior sem a apagar (fica no histórico, ver
  // getHistoricoMatriculas), abre uma nova na turma de destino e atualiza
  // alunos.turma_id. O aluno mantém toda a ficha; só a turma muda, e com
  // ela o DT responsável, que passa a ser o(s) DT da turma nova.
  async mudarTurma(alunoId, novaTurmaId, motivo) {
    const { error } = await window.supabase.rpc("mudar_turma_aluno", {
      p_aluno_id: alunoId,
      p_nova_turma_id: novaTurmaId,
      p_motivo: motivo || null,
    });
    if (error) throw error;
  },
};
