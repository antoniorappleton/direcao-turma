// Gestão de sessão — mesma conta "professores" partilhada com o Scriptorium.

// Depois de "Sair", o browser pode restaurar esta página a partir da cache
// (bfcache) ao premir "retroceder", sem voltar a correr o requireSession()
// abaixo. Forçar reload garante que o guard corre sempre e expulsa para
// login.html se já não houver sessão.
window.addEventListener("pageshow", (event) => {
  if (event.persisted) {
    window.location.reload();
  }
});

async function getCurrentSession() {
  if (window.supabaseReady) await window.supabaseReady;
  const { data } = await window.supabase.auth.getSession();
  return data?.session || null;
}

async function requireSession(redirectTo = "login.html") {
  const session = await getCurrentSession();
  if (!session) {
    window.location.href = redirectTo;
    return null;
  }
  return session;
}

async function getCurrentProfessor() {
  const session = await getCurrentSession();
  if (!session) return null;
  const email = session.user.email;
  const { data, error } = await window.supabase
    .from("professores")
    .select("*")
    .eq("email", email)
    .maybeSingle();
  if (error) {
    console.error("getCurrentProfessor error", error);
    return null;
  }
  return data;
}
