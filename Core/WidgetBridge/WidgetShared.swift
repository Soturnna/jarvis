import Foundation
import os

/// O contrato entre o app e os widgets: o arquivo, onde ele fica e como é lido.
/// Este arquivo é compilado no app E na extensão de widgets.
///
/// O mesmo resumo é gravado em dois lugares (ver WidgetBridge):
/// - na pasta do App Group, lida pelos widgets nativos (WidgetKit);
/// - em Documents, lida pelo Scriptable.
///
/// O App Group NUNCA é fixado no código. Quem assina o app decide o nome do grupo
/// (ou nem o concede, como o iOSGods App+), então a lista de candidatos é montada
/// em tempo de execução, juntando as duas técnicas já testadas:
/// - Fluxo (WidgetShared): "group.<identificador com que o app foi instalado>";
/// - Forja (GrupoApp): grupos listados no perfil de assinatura e em ALTAppGroups.
enum WidgetShared {
    static let baseBundleID = "com.soturnna.jarvis"
    static let fileName = "jarvis-widget.json"
    static let memoryFileName = "widget-memoria.json"
    static let schemaVersion = 1

    // MARK: Dados

    /// O que vai no arquivo. Na fase 0, só o cabeçalho e um texto de teste;
    /// o DailySummary completo entra aqui na fase 5.
    ///
    /// Regra de segurança: nada em reais e nenhum nome entra neste arquivo.
    /// Valores (com "Mostrar valores nos widgets") irão para um segundo arquivo,
    /// com proteção de dados completa, como o Fluxo já faz.
    struct Envelope: Codable, Equatable {
        var schemaVersion: Int
        var updatedAt: Date
        var showValues: Bool
        var note: String?
    }

    /// Memória livre medida dentro do widget (o iOS dá cerca de 30 MB à extensão).
    struct MemoryReport: Codable, Equatable {
        var availableBytes: Int
        var recordedAt: Date
        var family: String
    }

    // MARK: Grupo

    static var mainBundleID: String {
        mainBundleID(from: Bundle.main.bundleIdentifier ?? baseBundleID,
                     isExtension: Bundle.main.bundleURL.pathExtension == "appex")
    }

    /// A extensão tem um identificador com um pedaço a mais (….widgets); o do app é sem ele.
    static func mainBundleID(from id: String, isExtension: Bool) -> String {
        guard isExtension else { return id }
        return id.split(separator: ".").dropLast().joined(separator: ".")
    }

    /// Candidatos, em ordem de preferência, sem repetição.
    static var groupCandidates: [String] {
        var all = groupsFromProvisioningProfile()
        if let alt = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] { all += alt }
        all += groupCandidates(mainBundleID: mainBundleID)
        var seen = Set<String>()
        return all.filter { seen.insert($0).inserted }
    }

    static func groupCandidates(mainBundleID: String) -> [String] {
        let installed = "group.\(mainBundleID)"
        let original = "group.\(baseBundleID)"
        return installed == original ? [original] : [installed, original]
    }

    /// Primeira pasta de grupo que o iOS liberou para este app (nil = grupo não concedido).
    /// `containerURL` só devolve uma pasta para grupos que estão na assinatura.
    static func container() -> (group: String, url: URL)? {
        for group in groupCandidates {
            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
                return (group, url)
            }
        }
        return nil
    }

    /// Lê os grupos do perfil de assinatura (`embedded.mobileprovision`) que vai dentro do pacote.
    /// O arquivo é um envelope assinado (CMS), mas o plist vai dentro em texto puro.
    private static func groupsFromProvisioningProfile() -> [String] {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .isoLatin1),
              let start = text.range(of: "<?xml"),
              let end = text.range(of: "</plist>") else { return [] }
        let xml = Data(text[start.lowerBound..<end.upperBound].utf8)
        guard let plist = try? PropertyListSerialization.propertyList(from: xml, format: nil) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any],
              let groups = entitlements["com.apple.security.application-groups"] as? [String] else { return [] }
        // Os que citam "jarvis" primeiro.
        return groups.filter { $0.contains("jarvis") } + groups.filter { !$0.contains("jarvis") }
    }

    // MARK: Codificação (datas em ISO 8601, fáceis de ler em JavaScript)

    static func encode(_ envelope: Envelope) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(envelope)
    }

    static func decode(_ data: Data) -> Envelope? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Envelope.self, from: data)
    }

    // MARK: Caminho nativo (App Group)

    /// Grava o resumo na pasta do grupo. Devolve o grupo usado, ou nil se ele não existir.
    @discardableResult
    static func writeToGroup(_ envelope: Envelope) -> String? {
        guard let found = container(), let data = try? encode(envelope) else { return nil }
        do {
            // .atomic: grava num arquivo temporário e troca no fim; o widget nunca lê pela metade.
            // UntilFirstUserAuthentication: legível com o iPhone travado (tela de bloqueio),
            // o que é aceitável porque este arquivo não tem valores nem nomes.
            try data.write(to: found.url.appendingPathComponent(fileName),
                           options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return found.group
        } catch {
            return nil
        }
    }

    static func readFromGroup() -> Envelope? {
        guard let found = container(),
              let data = try? Data(contentsOf: found.url.appendingPathComponent(fileName)) else { return nil }
        return decode(data)
    }

    // MARK: Memória do widget (diagnóstico)

    /// Chamado de dentro do widget: registra quanta memória ainda está livre.
    static func recordWidgetMemory(family: String) {
        guard let found = container() else { return }
        let report = MemoryReport(availableBytes: Int(os_proc_available_memory()), recordedAt: Date(), family: family)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(report) else { return }
        try? data.write(to: found.url.appendingPathComponent(memoryFileName), options: .atomic)
    }

    static func readWidgetMemory() -> MemoryReport? {
        guard let found = container(),
              let data = try? Data(contentsOf: found.url.appendingPathComponent(memoryFileName)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(MemoryReport.self, from: data)
    }

    /// Apaga os arquivos do grupo (Apagar todos os dados).
    static func removeAll() {
        guard let found = container() else { return }
        for name in [fileName, memoryFileName] {
            try? FileManager.default.removeItem(at: found.url.appendingPathComponent(name))
        }
    }
}
