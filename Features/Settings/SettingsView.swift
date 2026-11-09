import SwiftUI
import UIKit

/// Ajustes e Diagnóstico. Aberta pelo botão de perfil da aba Hoje.
struct SettingsView: View {
    @EnvironmentObject private var lock: AppLock
    @AppStorage(SettingsKey.requireAuth) private var requireAuth = true
    @AppStorage(SettingsKey.lockDelay) private var lockDelay = LockDelay.immediately.rawValue
    @AppStorage(SettingsKey.shieldInSwitcher) private var shieldInSwitcher = true
    @AppStorage(SettingsKey.widgetShowValues) private var widgetShowValues = false
    @AppStorage(SettingsKey.widgetTestNote) private var testNote = ""

    @State private var report = WidgetBridge.lastReport
    @State private var justSaved = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Ajustes")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                section("Módulos") { modules }
                section("Privacidade") { privacy }
                section("Teste dos widgets") { widgetTest }
                section("Diagnóstico") { DiagnosticsCard(report: report) }
                section("Widgets pelo Scriptable") { ScriptableGuide() }
            }
            .padding(.horizontal, Theme.margin)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: widgetShowValues) { _, _ in report = WidgetBridge.refresh() }
        .onAppear { report = WidgetBridge.lastReport }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Overline(title)
            content()
        }
    }

    // MARK: Módulos

    private struct ModuleRow: Identifiable {
        let name: String
        let icon: String
        let color: Color
        let phase: Int
        var id: String { name }
    }

    private let moduleRows: [ModuleRow] = [
        .init(name: "Finanças", icon: "creditcard.fill", color: Theme.finance, phase: 1),
        .init(name: "Treino e Saúde", icon: "dumbbell.fill", color: Theme.training, phase: 2),
        .init(name: "Nutrição", icon: "fork.knife", color: Theme.nutrition, phase: 3),
        .init(name: "Agenda", icon: "calendar", color: Theme.calendar, phase: 5),
        .init(name: "E-mail", icon: "envelope.fill", color: Theme.mail, phase: 6),
        .init(name: "Briefing e Siri", icon: "sparkles", color: Theme.accent, phase: 7)
    ]

    private var modules: some View {
        VStack(spacing: 0) {
            ForEach(Array(moduleRows.enumerated()), id: \.element.id) { index, row in
                if index > 0 { Divider() }
                HStack(spacing: 12) {
                    Image(systemName: row.icon)
                        .foregroundStyle(row.color)
                        .frame(width: 28)
                        .accessibilityHidden(true)
                    Text(row.name)
                    Spacer()
                    // Status sempre com ícone e texto, nunca só a cor.
                    Label("Pendente · fase \(row.phase)", systemImage: "clock")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(minHeight: Theme.minTouch)
                .accessibilityElement(children: .combine)
            }
        }
        .jarvisCard(padding: 14)
    }

    // MARK: Privacidade

    private var privacy: some View {
        VStack(spacing: 0) {
            Toggle(isOn: loosening($requireAuth, reason: "Desligar o bloqueio do Jarvis")) {
                Label("\(lock.biometryName) ao abrir", systemImage: lock.biometryIcon)
            }
            .frame(minHeight: Theme.minTouch)

            Divider()

            Picker(selection: lockDelayBinding) {
                ForEach(LockDelay.allCases) { delay in
                    Text(delay.label).tag(delay.rawValue)
                }
            } label: {
                Label("Bloquear", systemImage: "timer")
            }
            .frame(minHeight: Theme.minTouch)
            .disabled(!requireAuth)

            Divider()

            Toggle(isOn: loosening($shieldInSwitcher, reason: "Mostrar o Jarvis no alternador de apps")) {
                Label("Proteger no alternador de apps", systemImage: "eye.slash")
            }
            .frame(minHeight: Theme.minTouch)

            Divider()

            // "Ocultar" ligado é o estado protegido: desligar (mostrar valores) pede Face ID.
            Toggle(isOn: loosening(hideWidgetValues, reason: "Mostrar valores nos widgets")) {
                Label("Ocultar valores no widget", systemImage: "lock.rectangle")
            }
            .frame(minHeight: Theme.minTouch)
        }
        .jarvisCard(padding: 14)
    }

    private var hideWidgetValues: Binding<Bool> {
        Binding(get: { !widgetShowValues }, set: { widgetShowValues = !$0 })
    }

    /// Envolve um Toggle de proteção: ligar é imediato; desligar pede Face ID. (Do Fluxo.)
    private func loosening(_ setting: Binding<Bool>, reason: String) -> Binding<Bool> {
        Binding(
            get: { setting.wrappedValue },
            set: { newValue in
                if newValue {
                    setting.wrappedValue = true
                } else {
                    Task { @MainActor in
                        if await lock.authenticate(reason: reason) {
                            setting.wrappedValue = false
                        }
                    }
                }
            }
        )
    }

    /// Diminuir o tempo até o bloqueio é livre; aumentar pede Face ID. (Do Fluxo.)
    private var lockDelayBinding: Binding<Int> {
        Binding(
            get: { lockDelay },
            set: { newValue in
                if newValue <= lockDelay {
                    lockDelay = newValue
                } else {
                    Task { @MainActor in
                        if await lock.authenticate(reason: "Aumentar o tempo até o bloqueio") {
                            lockDelay = newValue
                        }
                    }
                }
            }
        )
    }

    // MARK: Teste dos widgets (fase 0)

    private var widgetTest: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Escreva um texto e grave. Ele deve aparecer no widget do Scriptable (e no nativo, se o App Group existir).")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)

            TextField("Texto de teste", text: $testNote)
                .focused($noteFocused)
                .submitLabel(.done)
                .padding(.horizontal, 12)
                .frame(minHeight: Theme.minTouch)
                .background(Theme.cardInner, in: RoundedRectangle(cornerRadius: Theme.innerRadius, style: .continuous))

            Button {
                noteFocused = false
                report = WidgetBridge.refresh()
                justSaved = true
            } label: {
                Label(justSaved ? "Gravado" : "Gravar no widget", systemImage: justSaved ? "checkmark" : "square.and.arrow.down")
            }
            .buttonStyle(ModuleButtonStyle())
        }
        .jarvisCard(padding: 14)
        .onChange(of: testNote) { _, _ in justSaved = false }
        .sensoryFeedback(.success, trigger: justSaved) { _, new in new }
    }
}

// MARK: - Diagnóstico

/// Mostra o que o app conseguiu de verdade neste aparelho: grupo, caminho de widget,
/// última gravação e memória medida dentro do widget.
private struct DiagnosticsCard: View {
    let report: WidgetBridge.Report?

    private var container: (group: String, url: URL)? { WidgetShared.container() }

    var body: some View {
        VStack(spacing: 0) {
            row("App Group",
                value: container != nil ? "Ativo" : "Não concedido",
                detail: container?.group ?? "Quem assinou o app não entregou o grupo. Use o Scriptable.",
                ok: container != nil)
            Divider()
            row("Caminho de widget ativo",
                value: container != nil ? "Nativo e Scriptable" : "Scriptable",
                detail: container != nil ? "Os dois arquivos são gravados." : "Os widgets nativos não aparecem sem o App Group.",
                ok: true)
            Divider()
            row("Última gravação",
                value: report.map { $0.date.formatted(date: .abbreviated, time: .standard) } ?? "Nenhuma",
                detail: writeDetail,
                ok: report?.scriptableWritten ?? false)
            Divider()
            row("Arquivo do Scriptable",
                value: WidgetBridge.scriptableFileExists ? "Gravado" : "Ausente",
                detail: "Arquivos › No Meu iPhone › Jarvis › \(WidgetShared.fileName)",
                ok: WidgetBridge.scriptableFileExists)
            Divider()
            row("Memória do widget",
                value: memoryValue,
                detail: memoryDetail,
                ok: WidgetShared.readWidgetMemory() != nil)
            Divider()
            row("Identificador instalado",
                value: Bundle.main.bundleIdentifier ?? "desconhecido",
                detail: "Grupos procurados: " + WidgetShared.groupCandidates.joined(separator: ", "),
                ok: true)
        }
        .jarvisCard(padding: 14)
    }

    private var writeDetail: String {
        guard let report else { return "Abra a aba Hoje ou grave um texto de teste." }
        let native = report.group != nil ? "nativo: sim" : "nativo: não"
        let scriptable = report.scriptableWritten ? "Scriptable: sim" : "Scriptable: falhou"
        return "\(native) · \(scriptable)"
    }

    private var memoryValue: String {
        guard let memory = WidgetShared.readWidgetMemory() else { return "Sem medição" }
        return ByteCountFormatter.string(fromByteCount: Int64(memory.availableBytes), countStyle: .memory) + " livres"
    }

    private var memoryDetail: String {
        if let memory = WidgetShared.readWidgetMemory() {
            return "Medido no widget \(memory.family) em \(memory.recordedAt.formatted(date: .abbreviated, time: .shortened))."
        }
        return container == nil
            ? "A medição é feita dentro do widget nativo, que precisa do App Group."
            : "Adicione o widget nativo do Jarvis à tela de início para medir."
    }

    private func row(_ title: String, value: String, detail: String, ok: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(ok ? Theme.finance : Theme.training)
                .accessibilityLabel(ok ? "Certo" : "Atenção")
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Scriptable

/// Exporta o script Jarvis.js e explica a configuração (uma vez só). Vem do Forja.
private struct ScriptableGuide: View {
    @Environment(\.openURL) private var openURL
    @State private var copied = false

    private let scriptURL = ScriptableScript.fileURL()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("O Scriptable (gratuito na App Store) desenha os widgets lendo o arquivo que o Jarvis grava. Funciona mesmo sem o App Group.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)

            if let scriptURL {
                ShareLink(item: scriptURL) {
                    Label("Exportar script do Scriptable", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(ModuleButtonStyle())
            }

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = ScriptableScript.code()
                    copied = true
                } label: {
                    Label(copied ? "Copiado" : "Copiar código", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity, minHeight: Theme.minTouch)
                }
                Button {
                    if let url = URL(string: "https://apps.apple.com/app/scriptable/id1405459188") { openURL(url) }
                } label: {
                    Label("App Store", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity, minHeight: Theme.minTouch)
                }
            }
            .font(.subheadline.weight(.semibold))
            .buttonStyle(.bordered)

            VStack(alignment: .leading, spacing: 8) {
                step(1, "Instale o Scriptable pela App Store.")
                step(2, "Toque em Exportar e escolha Scriptable. Se ele não aparecer, copie o código, crie um script novo (+), cole e dê o nome Jarvis.")
                step(3, "No Scriptable: engrenagem › File Bookmarks › + › Pick Folder › No Meu iPhone › Jarvis › nome: Jarvis (exatamente assim).")
                step(4, "Segure a tela de início › + › Scriptable › escolha o tamanho. Depois toque no widget › Script: Jarvis.")
            }
            Label("Se apagar e reinstalar o Jarvis, refaça o passo 3 (a pasta muda).", systemImage: "folder.badge.questionmark")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .jarvisCard(padding: 14)
        .sensoryFeedback(.success, trigger: copied) { _, new in new }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Theme.onModule)
                .frame(width: 24, height: 24)
                .background(Theme.accent, in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Passo \(number): \(text)")
    }
}
