// Login/logout — mesmo padrão do Scriptorium, com regras adicionais:
// só entram emails nome.apelido@colegio-ramalhao.com (nome/apelido variam);
// a password por omissão de qualquer professor é "[apelido],csj2026" (ver
// defaultPasswordFor) — serve só para a primeira entrada. Depois disso o
// professor é obrigado a definir a sua própria (ver mudar-password.html e
// professores.deve_mudar_password, db/add_deve_mudar_password.sql).
// Na primeira entrada válida com essa password, a conta Supabase Auth (e a
// linha em `professores`) são criadas na hora — não há registo manual prévio.

const SCHOOL_EMAIL_PATTERN = /^[a-z]+(?:-[a-z]+)*\.[a-z]+(?:-[a-z]+)*@colegio-ramalhao\.com$/;

function nomeFromEmail(email) {
  return email
    .split("@")[0]
    .split(".")
    .filter(Boolean)
    .map((parte) => parte.charAt(0).toUpperCase() + parte.slice(1))
    .join(" ");
}

// Apelido = parte depois do primeiro ponto, antes do @ (nome.apelido@...) —
// ver SCHOOL_EMAIL_PATTERN, que só aceita exatamente estas duas partes.
function apelidoFromEmail(email) {
  return email.split("@")[0].split(".")[1] || "";
}

// Password por omissão de QUALQUER professor @colegio-ramalhao.com — igual
// para todos exceto na parte do apelido. Só funciona na primeira entrada
// (signUp) ou enquanto o professor ainda não a mudou — ver
// professores.deve_mudar_password.
function defaultPasswordFor(email) {
  return `${apelidoFromEmail(email)},csj2026`;
}

// Garante que existe uma linha em `professores` para este email — primeira
// vez que a pessoa entra. Corre depois de autenticar, nunca antes (a
// política de RLS só permite a cada professor inserir a SUA PRÓPRIA linha,
// ver db/allow_self_register_professores.sql). deve_mudar_password fica a
// true por omissão da coluna (db/add_deve_mudar_password.sql).
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

  if (!SCHOOL_EMAIL_PATTERN.test(emailNormalizado)) {
    return {
      error: { message: "Usa o teu email do colégio (nome.apelido@colegio-ramalhao.com)." },
    };
  }

  let result = await window.supabase.auth.signInWithPassword({ email: emailNormalizado, password });

  if (result.error && /invalid login credentials/i.test(result.error.message || "")) {
    // Só tenta criar conta nova se a password usada for a de omissão desta
    // escola — caso contrário seria só um professor já registado que
    // escreveu mal a SUA password, e criar conta aqui seria o passo errado.
    if (password === defaultPasswordFor(emailNormalizado)) {
      const signUpResult = await window.supabase.auth.signUp({ email: emailNormalizado, password });
      if (signUpResult.error) return signUpResult;
      result = await window.supabase.auth.signInWithPassword({ email: emailNormalizado, password });
    } else {
      return {
        error: {
          message: "Password incorreta. Se é a tua primeira vez a entrar, usa a password por omissão fornecida pela escola.",
        },
      };
    }
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
