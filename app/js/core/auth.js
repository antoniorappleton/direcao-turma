// Login/logout — contas da escola são criadas na primeira entrada com a
// palavra-passe comum fornecida pela escola. O email tem de seguir
// nome.apelido@colegio-ramalhao.com.

const SCHOOL_EMAIL_PATTERN = /^[a-z]+(?:-[a-z]+)*\.[a-z]+(?:-[a-z]+)*@colegio-ramalhao\.com$/;
const SCHOOL_SHARED_PASSWORD = "P@ssword";

function nomeFromEmail(email) {
  return email.split("@")[0]
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
  const { data, error: selectError } = await window.supabase
    .from("professores")
    .select("id")
    .eq("email", email)
    .maybeSingle();
  if (selectError) {
    console.warn("Não foi possível verificar o registo do professor.", selectError);
    return;
  }
  if (data) return;

  const { error: insertError } = await window.supabase
    .from("professores")
    .insert([{ nome: nomeFromEmail(email), email }]);
  if (insertError) {
    console.warn("Não foi possível criar o registo do professor.", insertError);
  }
}

async function signIn(email, password) {
  if (window.supabaseReady) await window.supabaseReady;
  if (!window.supabase) {
    throw new Error("Não foi possível ligar ao serviço de autenticação. Atualiza a página e tenta novamente.");
  }
  const emailNormalizado = email.trim().toLowerCase();

  if (!SCHOOL_EMAIL_PATTERN.test(emailNormalizado)) {
    return {
      error: {
        message: "Usa o teu email do colégio (nome.apelido@colegio-ramalhao.com).",
      },
    };
  }

  let result = await window.supabase.auth.signInWithPassword({ email: emailNormalizado, password });

  if (result.error && /invalid login credentials/i.test(result.error.message || "")) {
    if (password !== SCHOOL_SHARED_PASSWORD) return result;
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
