// Camada de serviço — a interface nunca chama window.supabase diretamente.
// Reutiliza as tabelas `turmas`/`ciclos` já existentes no Supabase do Scriptorium.

// `turma_diretores` (ver db/add_turma_diretores.sql) guarda DT adicionais —
// dois professores podem ser DT da mesma turma em simultâneo (ver
// isDiretorDaTurma em permissions.js, que já lê turma.turma_diretores). O
// select tenta sempre incluir essa relação; se a tabela ainda não existir
// (migração por correr no Supabase), cai para a turma sem DT adicionais em
// vez de rebentar o dashboard todo.
function semTurmaDiretores(error) {
  return error?.code === "PGRST205" || /turma_diretores/.test(error?.message || "");
}

const TURMA_SELECT = "*, ciclos(*), turma_diretores(professor_id)";
const TURMA_SELECT_SEM_CODIRETORES = "*, ciclos(*)";

const TurmasService = {
  async getAll() {
    let { data, error } = await window.supabase.from("turmas").select(TURMA_SELECT).order("nome");
    if (error && semTurmaDiretores(error)) {
      ({ data, error } = await window.supabase.from("turmas").select(TURMA_SELECT_SEM_CODIRETORES).order("nome"));
    }
    if (error) throw error;
    return data || [];
  },

  async getById(turmaId) {
    let { data, error } = await window.supabase.from("turmas").select(TURMA_SELECT).eq("id", turmaId).maybeSingle();
    if (error && semTurmaDiretores(error)) {
      ({ data, error } = await window.supabase.from("turmas").select(TURMA_SELECT_SEM_CODIRETORES).eq("id", turmaId).maybeSingle());
    }
    if (error) throw error;
    return data;
  },

  // Turmas de que o professor é DT — principal (diretor_turma_id) ou
  // adicional (turma_diretores). Reaproveita getAll (já tenta trazer os DT
  // adicionais) para não duplicar a lógica de fallback.
  async getByDiretor(professorId) {
    const todas = await this.getAll();
    return todas.filter(
      (t) => t.diretor_turma_id === professorId || (t.turma_diretores || []).some((td) => td.professor_id === professorId),
    );
  },

  // Self-service "sou DT desta turma" (ver db/add_confirmar_sou_dt.sql,
  // usado em minhas-turmas.html) — o professor só consegue confirmar se o
  // nome dele constar do diretor_turma (texto) já registado na turma; caso
  // contrário o RPC recusa. Resolve no próprio onboarding o que hoje exigia
  // um admin corrigir diretor_turma_id à mão.
  async confirmarSouDT(turmaId) {
    const { error } = await window.supabase.rpc("confirmar_sou_dt", { p_turma_id: turmaId });
    if (error) throw error;
  },

  async retirarSouDT(turmaId) {
    const { error } = await window.supabase.rpc("retirar_me_dt", { p_turma_id: turmaId });
    if (error) throw error;
  },
};
