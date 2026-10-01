// Login/logout — mesmo padrão do Scriptorium, com uma regra adicional:
// só entram emails nome.apelido@colegio-ramalhao.com (nome/apelido variam)
// com a palavra-passe partilhada pela escola. Na primeira tentativa válida,
// a conta Supabase Auth (e a linha em `professores`) são criadas na hora —
// não há registo manual prévio.

const SCHOOL_EMAIL_PATTERN = /^[a-z]+(?:-[a-z]+)*\.[a-z]+(?:-[a-z]+)*@colegio-ramalhao\.com$/;
const SCHOOL_SHARED_PASSWORD = "P@ssword";

function nomeFromEmail(email) {
  return email
    .split("@")[0]
    .split(".")
    .filter(Boolean)
    .map((parte) => parte.charAt(0).toUpperCase() + parte.slice(1))
    .join(" ");
}

// Garante que existe uma linha em `professores` para este email — primeira
// vez que a pessoa entra. Corre depois de autenticar, nunca antes (a
// política de RLS só permite a cada professor inserir a SUA PRÓPRIA linha,
// ver db/allow_self_register_professores.sql).
async function ensureProfessorRow(email) {
  try {
    const { data } = await window.supabase.from("professores").select("id").eq("email", email).maybeSingle();
    if (data) return;
    await window.supabase.from("professores").insert([{ nome: nomeFromEmail(email), email }]);
  } catch (e) {
    // Não bloqueia o login — uma corrida entre pedidos em paralelo pode
    // violar a unicidade do email, por exemplo, o que é inofensivo aqui.
    console.warn("ensureProfessorRow falhou (ignorado)", e);
  }
}

async function signIn(email, password) {
  if (window.supabaseReady) await window.supabaseReady;
  const emailNormalizado = email.trim().toLowerCase();

  if (!SCHOOL_EMAIL_PATTERN.test(emailNormalizado) || password !== SCHOOL_SHARED_PASSWORD) {
    return {
      error: {
        message: "Usa o teu email do colégio (nome.apelido@colegio-ramalhao.com) e a palavra-passe fornecida pela escola.",
      },
    };
  }

  let result = await window.supabase.auth.signInWithPassword({ email: emailNormalizado, password });

  if (result.error && /invalid login credentials/i.test(result.error.message || "")) {
    const signUpResult = await window.supabase.auth.signUp({ email: emailNormalizado, password });
    if (signUpResult.error) return signUpResult;
    result = await window.supabase.auth.signInWithPassword({ email: emailNormalizado, password });
  }

  if (!result.error) await ensureProfessorRow(emailNormalizado);

  return result;
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
    // replace() em vez de href: não deixa esta página autenticada no
    // histórico, para "retroceder" não voltar a mostrá-la.
    window.location.replace("https://antoniorappleton.github.io/");
  } catch (e) {
    console.error("signOut error", e);
    alert("Erro no logout");
  }
}
