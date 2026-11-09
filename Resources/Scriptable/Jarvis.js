// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: cyan; icon-glyph: magic;

/*
 * Jarvis · widget para o Scriptable
 * ----------------------------------
 * O Jarvis grava um resumo em "jarvis-widget.json" na pasta dele
 * (app Arquivos › No Meu iPhone › Jarvis). Este script lê esse arquivo e desenha o widget.
 *
 * Configuração (uma vez):
 *   Scriptable › Ajustes (engrenagem) › File Bookmarks › + › Pick Folder › escolha a pasta "Jarvis"
 *   e dê o nome  Jarvis  (exatamente assim).
 *
 * Fase 0: o widget mostra o texto de teste gravado em Ajustes e a hora da última atualização.
 * Os widgets definitivos (painel do dia, finanças, treino, nutrição, saúde) entram na fase 5,
 * escolhidos pelo campo Parameter do widget.
 *
 * Base: o Forja.js do app Forja (dados num arquivo, desenho por tamanho de widget e
 * atualização periódica pedida ao iOS).
 */

const VERSAO = 1
const BOOKMARK = "Jarvis"
const ARQUIVO = "jarvis-widget.json"

// Tokens visuais do Jarvis (modo escuro)
const COR = {
  fundo: new Color("#000000"),
  cartao: new Color("#1C1C1E"),
  interno: new Color("#2C2C2E"),
  destaque: new Color("#64D2FF"),
  texto: new Color("#F2F2F7"),
  secundario: new Color("#A1A1AA"),
  alerta: new Color("#FF9F0A"),
}

const familia = config.widgetFamily || "medium"
const acessorio = familia.startsWith("accessory")

// ---------- Dados ----------

function lerDados() {
  const fm = FileManager.local()
  if (!fm.bookmarkExists(BOOKMARK)) return { erro: "semPasta" }
  const caminho = fm.joinPath(fm.bookmarkedPath(BOOKMARK), ARQUIVO)
  if (!fm.fileExists(caminho)) return { erro: "semArquivo" }
  try {
    const d = JSON.parse(fm.readString(caminho))
    if (!d || typeof d.schemaVersion !== "number") return { erro: "ilegivel" }
    // Arquivo gravado por uma versão mais nova do app: o script precisa ser exportado de novo.
    if (d.schemaVersion > VERSAO) return { erro: "scriptAntigo" }
    return d
  } catch (e) {
    return { erro: "ilegivel" }
  }
}

/** "14:32" se foi hoje; "08/11 14:32" se foi em outro dia. */
function horaDaAtualizacao(iso) {
  const d = new Date(iso)
  if (isNaN(d.getTime())) return "–"
  const p = n => (n < 10 ? "0" : "") + n
  const hora = p(d.getHours()) + ":" + p(d.getMinutes())
  const hoje = new Date()
  const mesmoDia = d.getFullYear() === hoje.getFullYear() && d.getMonth() === hoje.getMonth() && d.getDate() === hoje.getDate()
  return mesmoDia ? hora : p(d.getDate()) + "/" + p(d.getMonth() + 1) + " " + hora
}

// ---------- Peças de desenho ----------

function texto(pilha, t, fonte, cor, linhas) {
  const e = pilha.addText(t)
  e.font = fonte
  e.textColor = cor
  if (linhas) e.lineLimit = linhas
  e.minimumScaleFactor = 0.7
  return e
}

function simbolo(pilha, nome, tamanho, cor) {
  const s = SFSymbol.named(nome)
  s.applyFont(Font.semiboldSystemFont(tamanho))
  const img = pilha.addImage(s.image)
  img.imageSize = new Size(tamanho, tamanho)
  img.tintColor = cor
  return img
}

/** Cabeçalho do widget: ícone e nome na cor de destaque, como no canvas. */
function sobretitulo(pilha, t) {
  const linha = pilha.addStack()
  linha.centerAlignContent()
  simbolo(linha, "sparkles", 13, COR.destaque)
  linha.addSpacer(4)
  texto(linha, t, Font.semiboldSystemFont(12), COR.destaque, 1)
}

/** Rodapé presente em todos os widgets: a hora da última atualização. */
function rodape(pilha, d) {
  const linha = pilha.addStack()
  linha.centerAlignContent()
  texto(linha, "Atualizado às " + horaDaAtualizacao(d.updatedAt), Font.systemFont(11), COR.secundario, 1)
}

// ---------- Widgets por tamanho ----------

function widgetAviso(erro) {
  const w = new ListWidget()
  w.backgroundColor = COR.cartao
  const msg = {
    semPasta: ["Conecte a pasta do Jarvis", "Scriptable › Ajustes › File Bookmarks › escolha a pasta Jarvis e dê o nome “Jarvis”."],
    semArquivo: ["Abra o Jarvis uma vez", "O resumo é gravado quando o app abre."],
    ilegivel: ["Resumo ilegível", "Abra o Jarvis para gravar o resumo de novo."],
    scriptAntigo: ["Atualize o script", "No Jarvis: Ajustes › Exportar script do Scriptable."],
  }[erro]
  if (acessorio) {
    texto(w, "Jarvis: " + msg[0], Font.semiboldSystemFont(12), Color.white(), 2)
    return w
  }
  sobretitulo(w, "Jarvis")
  w.addSpacer(6)
  texto(w, msg[0], Font.boldSystemFont(14), COR.texto, 2)
  w.addSpacer(4)
  texto(w, msg[1], Font.systemFont(11), COR.secundario, 5)
  return w
}

function widgetPainel(d, linhas, tamanhoFonte) {
  const w = new ListWidget()
  w.backgroundColor = COR.cartao
  w.setPadding(14, 16, 12, 16)
  w.url = "jarvis://hoje"
  sobretitulo(w, "Jarvis")
  w.addSpacer(6)
  if (d.note) {
    texto(w, d.note, Font.mediumSystemFont(tamanhoFonte), COR.texto, linhas)
  } else {
    texto(w, "Sem texto de teste. Grave um em Ajustes.", Font.systemFont(tamanhoFonte - 1), COR.secundario, linhas)
  }
  w.addSpacer()
  rodape(w, d)
  return w
}

// Tela de bloqueio: o iOS pinta tudo em uma cor só; o desenho usa branco e opacidade.
function widgetRetangular(d) {
  const w = new ListWidget()
  w.url = "jarvis://hoje"
  const t = w.addStack()
  t.centerAlignContent()
  simbolo(t, "sparkles", 12, Color.white())
  t.addSpacer(4)
  texto(t, "Jarvis", Font.boldSystemFont(14), Color.white(), 1)
  texto(w, d.note || "Sem texto de teste", Font.mediumSystemFont(12), new Color("#FFFFFF", 0.8), 1)
  texto(w, "Atualizado às " + horaDaAtualizacao(d.updatedAt), Font.mediumSystemFont(12), new Color("#FFFFFF", 0.8), 1)
  return w
}

function widgetCircular(d) {
  const w = new ListWidget()
  w.addAccessoryWidgetBackground = true
  w.url = "jarvis://hoje"
  const pilha = w.addStack()
  pilha.layoutVertically()
  pilha.centerAlignContent()
  const a = pilha.addStack(); a.addSpacer()
  simbolo(a, "sparkles", 16, Color.white())
  a.addSpacer()
  const b = pilha.addStack(); b.addSpacer()
  texto(b, horaDaAtualizacao(d.updatedAt).slice(-5), Font.mediumRoundedSystemFont(10), Color.white(), 1)
  b.addSpacer()
  return w
}

function widgetLinha(d) {
  const w = new ListWidget()
  const linha = w.addStack()
  simbolo(linha, "sparkles", 12, Color.white())
  linha.addSpacer(4)
  texto(linha, d.note || "Jarvis · " + horaDaAtualizacao(d.updatedAt), Font.mediumSystemFont(12), Color.white(), 1)
  return w
}

// ---------- Montagem ----------

const dados = lerDados()
let widget
if (dados.erro) widget = widgetAviso(dados.erro)
else if (familia === "small") widget = widgetPainel(dados, 5, 13)
else if (familia === "large") widget = widgetPainel(dados, 10, 17)
else if (familia === "accessoryCircular") widget = widgetCircular(dados)
else if (familia === "accessoryRectangular") widget = widgetRetangular(dados)
else if (familia === "accessoryInline") widget = widgetLinha(dados)
else widget = widgetPainel(dados, 3, 14)

// Pede ao iOS para redesenhar em ~15 min (ele decide o momento exato).
widget.refreshAfterDate = new Date(Date.now() + 15 * 60 * 1000)

if (config.runsInWidget) {
  Script.setWidget(widget)
} else {
  // Rodando dentro do Scriptable: mostra uma prévia.
  if (familia === "small") await widget.presentSmall()
  else if (familia === "large") await widget.presentLarge()
  else await widget.presentMedium()
}
Script.complete()
