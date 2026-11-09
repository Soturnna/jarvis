import Foundation
import WidgetKit

/// Lado do app: grava o MESMO resumo nos dois caminhos de widget a cada atualização.
///
/// - Caminho nativo: pasta do App Group (só existe se quem assinou o app o concedeu).
/// - Caminho Scriptable: `jarvis-widget.json` em Documents, visível no app Arquivos.
///   Vem do `WidgetScriptable` do Forja e funciona com qualquer assinatura.
///
/// Os widgets nunca acessam as fontes de dados; eles só leem estes arquivos.
@MainActor
enum WidgetBridge {
    /// Resultado da última gravação, guardado para a tela de Diagnóstico.
    struct Report: Equatable {
        var date: Date
        /// Nome do grupo usado, ou nil se o App Group não foi concedido.
        var group: String?
        var scriptableWritten: Bool
    }

    private enum Key {
        static let date = "diag.lastWriteAt"
        static let group = "diag.lastGroup"
        static let scriptable = "diag.lastScriptableWritten"
    }

    static var showValues: Bool { UserDefaults.standard.bool(forKey: SettingsKey.widgetShowValues) }

    static var testNote: String {
        UserDefaults.standard.string(forKey: SettingsKey.widgetTestNote) ?? ""
    }

    private static var documentsURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    static var scriptableFileURL: URL? {
        documentsURL?.appendingPathComponent(WidgetShared.fileName)
    }

    /// Regrava os dois arquivos com o estado atual e pede ao iOS para redesenhar os widgets nativos.
    @discardableResult
    static func refresh(now: Date = Date()) -> Report {
        let note = testNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let envelope = WidgetShared.Envelope(
            schemaVersion: WidgetShared.schemaVersion,
            updatedAt: now,
            showValues: showValues,
            note: note.isEmpty ? nil : String(note.prefix(120))
        )

        let group = WidgetShared.writeToGroup(envelope)
        let scriptable = writeForScriptable(envelope)
        WidgetCenter.shared.reloadAllTimelines()

        let report = Report(date: now, group: group, scriptableWritten: scriptable)
        save(report)
        return report
    }

    private static func writeForScriptable(_ envelope: WidgetShared.Envelope) -> Bool {
        guard let url = scriptableFileURL, let data = try? WidgetShared.encode(envelope) else { return false }
        do {
            // Gravação atômica: o Scriptable nunca lê um arquivo pela metade.
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch {
            return false
        }
    }

    /// Apaga os arquivos de widget dos dois caminhos.
    static func clear() {
        WidgetShared.removeAll()
        if let url = scriptableFileURL { try? FileManager.default.removeItem(at: url) }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: Diagnóstico

    static var lastReport: Report? {
        let defaults = UserDefaults.standard
        let seconds = defaults.double(forKey: Key.date)
        guard seconds > 0 else { return nil }
        return Report(date: Date(timeIntervalSince1970: seconds),
                      group: defaults.string(forKey: Key.group),
                      scriptableWritten: defaults.bool(forKey: Key.scriptable))
    }

    private static func save(_ report: Report) {
        let defaults = UserDefaults.standard
        defaults.set(report.date.timeIntervalSince1970, forKey: Key.date)
        defaults.set(report.group, forKey: Key.group)
        defaults.set(report.scriptableWritten, forKey: Key.scriptable)
    }

    static var scriptableFileExists: Bool {
        scriptableFileURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }
}

/// O script do Scriptable empacotado no app (Resources/Scriptable/Jarvis.js).
/// Mesma técnica do Forja: copiar para uma pasta temporária com o nome "Jarvis.js",
/// porque é esse o nome que o Scriptable usa ao importar.
enum ScriptableScript {
    private static var bundled: URL? { Bundle.main.url(forResource: "Jarvis", withExtension: "js") }

    static func fileURL() -> URL? {
        guard let source = bundled else { return nil }
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent("Jarvis.js")
        try? FileManager.default.removeItem(at: destination)
        return (try? FileManager.default.copyItem(at: source, to: destination)).map { destination }
    }

    static func code() -> String? {
        bundled.flatMap { try? String(contentsOf: $0, encoding: .utf8) }
    }
}

/// Toque num widget: jarvis://hoje, jarvis://financas, jarvis://treino, jarvis://nutricao,
/// jarvis://assistente, jarvis://registrar.
/// Só navegação (o app continua bloqueado até o Face ID); qualquer outro endereço é ignorado.
enum DeepLink: String, Equatable {
    case today = "hoje"
    case finance = "financas"
    case training = "treino"
    case nutrition = "nutricao"
    case assistant = "assistente"
    case register = "registrar"

    init?(url: URL) {
        guard url.scheme?.lowercased() == "jarvis", let host = url.host?.lowercased(),
              url.path.isEmpty || url.path == "/", url.query == nil else { return nil }
        self.init(rawValue: host)
    }
}

@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()
    @Published var pending: DeepLink?
}
