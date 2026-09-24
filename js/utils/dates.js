// Formatação de datas — DD/MM/AAAA, consistente com o Scriptorium.

function formatDate(isoDate) {
  if (!isoDate) return "";
  return isoDate.slice(0, 10).split("-").reverse().join("/");
}

function todayIso() {
  return new Date().toISOString().slice(0, 10);
}
