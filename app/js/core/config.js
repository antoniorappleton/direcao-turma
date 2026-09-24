// Mesmo projeto Supabase do Scriptorium — é isto que dá login partilhado (SSO)
// entre as apps da Comunidade CSJ Ramalhão, sem precisar de nenhum mecanismo
// extra: como ambas as apps ficam sob a mesma origem do GitHub Pages
// (antoniorappleton.github.io), o browser partilha a mesma sessão Supabase.
const SUPABASE_URL = "https://pllmyptwuvxryxfeufcm.supabase.co";
const SUPABASE_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsbG15cHR3dXZ4cnl4ZmV1ZmNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzOTA0NjgsImV4cCI6MjA5NTk2NjQ2OH0.xrZoCyXTHUi1jxjEuH_ymbAGZDVR6ZtVN1lN54EWJE0"; // chave pública (anon) — nunca a service_role

function loadSupabaseLib() {
  return new Promise((resolve, reject) => {
    if (window.supabase && typeof window.supabase.createClient === "function") {
      return resolve(window.supabase);
    }
    const s = document.createElement("script");
    s.src = "https://cdn.jsdelivr.net/npm/@supabase/supabase-js";
    s.onload = () => resolve(window.supabase);
    s.onerror = () => reject(new Error("Failed to load supabase lib"));
    document.head.appendChild(s);
  });
}

window.supabaseReady = loadSupabaseLib()
  .then((lib) => {
    const client = lib.createClient(SUPABASE_URL, SUPABASE_KEY);
    window.supabase = client;
    return client;
  })
  .catch((err) => {
    console.error("supabase init error", err);
  });
