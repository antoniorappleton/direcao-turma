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
    window.location.href = "login.html";
  } catch (e) {
    console.error("signOut error", e);
    alert("Erro no logout");
  }
}
