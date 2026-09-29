// Login/logout — mesmo padrão do Scriptorium.

async function signIn(email, password) {
  if (window.supabaseReady) await window.supabaseReady;
  return window.supabase.auth.signInWithPassword({ email, password });
}

async function signOut() {
  try {
    if (window.supabaseReady) await window.supabaseReady;
    const { error } = await window.supabase.auth.signOut();
    if (error) {
      alert("Erro no logout: " + error.message);
      return;
    }
    // Volta ao hub da Comunidade (não à login.html desta app) — ver
    // https://antoniorappleton.github.io/, que lista todas as apps.
    window.location.href = "https://antoniorappleton.github.io/";
  } catch (e) {
    console.error("signOut error", e);
    alert("Erro no logout");
  }
}
