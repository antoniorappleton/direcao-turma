// Importação em massa de avaliações intercalares a partir de uma tabela
// estilo Excel (colada ou carregada em .xlsx/.csv) — ver turma.html,
// separador Avaliações, botão "Importar avaliações".
//
// Formato esperado (ver testeAvaliações.xlsx na raiz do projeto): uma linha
// de cabeçalho, coluna A com "<número> <nome do aluno>" por linha, seguida
// de um bloco de 5 colunas por disciplina, sempre pela mesma ordem: Saber
// Ser, Saber Fazer, Saber Saber, Nota Final, Comentário. O ficheiro não diz
// qual é a disciplina de cada bloco — isso é indicado pelo DT no ecrã de
// importação (ver mapearBlocos em turma.html).
//
// Tudo aqui é puro (sem Supabase nem DOM) para ser fácil de testar.

const ImportarAvaliacoes = {
  COLUNAS_POR_BLOCO: 5,

  contarBlocos(linhas) {
    const maxColunas = linhas.reduce((max, l) => Math.max(max, l.length), 0);
    return Math.max(0, Math.floor((maxColunas - 1) / this.COLUNAS_POR_BLOCO));
  },

  // Tolerante a ponto ou vírgula decimal (cópias do Excel em PT-PT usam vírgula).
  parseNumero(valor) {
    if (typeof valor === "number") return Number.isFinite(valor) ? valor : null;
    if (valor === null || valor === undefined) return null;
    const texto = String(valor).trim().replace(",", ".");
    if (!texto) return null;
    const n = Number(texto);
    return Number.isFinite(n) ? n : null;
  },

  parseTexto(valor) {
    const texto = String(valor ?? "").trim();
    return texto || null;
  },

  normalizarTexto(texto) {
    return String(texto ?? "")
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "")
      .toLowerCase()
      .replace(/\s+/g, " ")
      .trim();
  },

  // "604 Bartolomeu Miranda..." -> { numero: "604", nome: "Bartolomeu Miranda..." }
  // Sem número à frente, assume que a célula inteira é o nome.
  extrairAlunoRef(celula) {
    const texto = String(celula ?? "").trim();
    const match = texto.match(/^(\d+)\s*[-–—]?\s*(.*)$/);
    if (match && match[2]) return { numero: match[1], nome: match[2].trim() };
    return { numero: null, nome: texto };
  },

  encontrarAluno(alunos, ref) {
    if (ref.numero) {
      const porNumero = alunos.find((a) => a.numero_interno && String(a.numero_interno).trim() === ref.numero);
      if (porNumero) return porNumero;
    }
    const nomeNormalizado = this.normalizarTexto(ref.nome);
    if (!nomeNormalizado) return null;
    return alunos.find((a) => this.normalizarTexto(a.nome) === nomeNormalizado) || null;
  },

  // Parse de texto colado (TSV, tal como copiado do Excel) em linhas/colunas.
  parseTextoColado(texto) {
    return String(texto ?? "")
      .replace(/\r\n/g, "\n")
      .split("\n")
      .filter((linha) => linha.trim() !== "")
      .map((linha) => linha.split("\t"));
  },

  // Linhas de dados (sem o cabeçalho) + mapa bloco->disciplina + alunos da
  // turma -> { registos, linhasIgnoradas } prontos para AvaliacoesService.createMany.
  construirRegistos({ linhasDados, disciplinasPorBloco, alunos, turmaId, periodo, data, criadoPor }) {
    const registos = [];
    const linhasIgnoradas = [];

    linhasDados.forEach((linha, indiceLinha) => {
      const ref = this.extrairAlunoRef(linha[0]);
      const aluno = this.encontrarAluno(alunos, ref);
      if (!aluno) {
        linhasIgnoradas.push({ linha: indiceLinha, texto: String(linha[0] ?? ""), motivo: "Aluno não encontrado" });
        return;
      }

      disciplinasPorBloco.forEach((disciplina, indiceBloco) => {
        if (!disciplina) return;
        const base = 1 + indiceBloco * this.COLUNAS_POR_BLOCO;
        const saberSer = this.parseNumero(linha[base]);
        const saberFazer = this.parseNumero(linha[base + 1]);
        const saberSaber = this.parseNumero(linha[base + 2]);
        const notaFinal = this.parseNumero(linha[base + 3]);
        const comentario = this.parseTexto(linha[base + 4]);

        const temDados = [saberSer, saberFazer, saberSaber, notaFinal, comentario].some((v) => v !== null);
        if (!temDados) return;

        registos.push({
          aluno_id: aluno.id,
          aluno_nome: aluno.nome,
          turma_id: turmaId,
          disciplina,
          periodo: Number(periodo),
          tipo: "intercalar",
          titulo: "Avaliação Intercalar",
          data,
          nota: notaFinal,
          escala: "0-20",
          saber_ser: saberSer,
          saber_fazer: saberFazer,
          saber_saber: saberSaber,
          observacao: comentario,
          criado_por: criadoPor,
        });
      });
    });

    return { registos, linhasIgnoradas };
  },

  // Permite importar o mesmo período em vários ficheiros sucessivos, cada
  // um mais completo que o anterior, sem duplicar avaliações: casa cada
  // registo novo com uma avaliação já existente (mesmo aluno/disciplina/
  // período/tipo) e, se encontrar, marca-o para UPDATE em vez de INSERT —
  // os campos que o novo ficheiro traz preenchidos substituem os antigos,
  // os que traz em branco mantêm o valor que já estava gravado.
  prepararParaGravar(registos, avaliacoesExistentes) {
    const CAMPOS_MESCLAVEIS = ["nota", "saber_ser", "saber_fazer", "saber_saber", "observacao"];
    return registos.map((registo) => {
      const existente = avaliacoesExistentes.find(
        (e) =>
          e.aluno_id === registo.aluno_id &&
          e.disciplina === registo.disciplina &&
          Number(e.periodo) === Number(registo.periodo) &&
          e.tipo === registo.tipo,
      );
      if (!existente) return { ...registo, _acao: "nova" };
      const mesclado = { ...registo };
      CAMPOS_MESCLAVEIS.forEach((campo) => {
        if (mesclado[campo] === null || mesclado[campo] === undefined) mesclado[campo] = existente[campo] ?? null;
      });
      return { ...mesclado, _acao: "atualiza", _id: existente.id };
    });
  },
};
