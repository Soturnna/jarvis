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
            VStack(alignment: .leading, spacing: 10) {
                Text("Ajustes")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)

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
        .toolbar(.visible, for: .navigationBar)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: widgetShowValues) { _, _ in report = WidgetBridge.refresh() }
        .onAppear { report = WidgetBridge.lastReport }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title)
            content()
        }
        .padding(.top, 6)
    }

    // MARK: Módulos

    private struct ModuleRow: Identifiable {
        let name: String
        let phase: Int
        var id: String { name }
    }

    private let moduleRows: [ModuleRow] = [
        .init(name: "Finanças", phase: 1),
        .init(name: "Treino e Saúde", phase: 2),
        .init(name: "Nutrição", phase: 3),
        .init(name: "Migração do Fluxo e do Forja", phase: 4),
        .init(name: "Agenda", phase: 5),
        .init(name: "E-mail", phase: 6),
        .init(name: "Briefing e Siri", phase: 7)
    ]

    private var modules: some View {
        VStack(spacing: 0) {
            ForEach(Array(moduleRows.enumerated()), id: \.element.id) { index, row in
                if index > 0 { RowDivider() }
                HStack(spacing: 12) {
                    Text(row.name)
                        .font(.subheadline)
                    Spacer(minLength: 8)
                    // Status sempre com ícone e texto, nunca só a cor.
                    StatusLabel(kind: .pending, text: "Pendente · fase \(row.phase)")
                }
                .padding(.horizontal, 16)
                .frame(minHeight: Theme.minTouch)
                .accessibilityElement(children: .combine)
            }
        }
        .jarvisListCard()
    }

    // MARK: Privacidade

    private var privacy: some View {
        VStack(spacing: 0) {
            // "Ocultar" ligado é o estado protegido: desligar (mostrar valores) pede Face ID.
            Toggle("Ocultar valores no widget", isOn: loosening(hideWidgetValues, reason: "Mostrar valores nos widgets"))
                .modifier(SettingRow())
            RowDivider()
            Toggle("\(lock.biometryName) ao abrir", isOn: loosening($requireAuth, reason: "Desligar o bloqueio do Jarvis"))
                .modifier(SettingRow())
            RowDivider()
            Picker("Bloquear", selection: lockDelayBinding) {
                ForEach(LockDelay.allCases) { delay in
                    Text(delay.label).tag(delay.rawValue)
                }
            }
            .modifier(SettingRow())
            .tint(Theme.textSecondary)
            .disabled(!requireAuth)
            RowDivider()
            Toggle("Proteger no alternador de apps", isOn: loosening($shieldInSwitcher, reason: "Mostrar o Jarvis no alternador de apps"))
                .modifier(SettingRow())
        }
        .tint(Theme.finance)   // interruptores verdes, como no canvas
        .jarvisListCard()
    }

    /// Linha de ajuste: mesma margem e altura mínima de toque em todas.
    private struct SettingRow: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.subheadline)
                .padding(.horizontal, 16)
                .frame(minHeight: 48)
        }
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
        .jarvisCard()
        .onChange(of: testNote) { _, _ in justSaved = false }
        .sensoryFeedback(.success, trigger: justSaved) { _, new in new }
    }
}

// MARK: - Diagnóstico

/// Mostra o que o app conseguiu de verdade neste aparelho: grupo, caminho de widget,
/// última gravação e memória medida dentro do widget. Rótulo à esquerda e valor à
/// direita, como no canvas; valores técnicos em fonte monoespaçada.
private struct DiagnosticsCard: View {
    let report: WidgetBridge.Report?

    private var container: (group: String, url: URL)? { WidgetShared.container() }

    var body: some View {
        VStack(spacing: 0) {
            stacked("App Group ativo",
                    value: container?.group ?? "não concedido pelo instalador",
                    ok: container != nil)
            RowDivider()
            inline("Widgets",
                   value: container != nil ? "Nativo e Scriptable" : "Scriptable (sem App Group)",
                   color: container != nil ? Theme.finance : Theme.training,
                   icon: container != nil ? "checkmark" : "exclamationmark.triangle.fill")
            RowDivider()
            inline("Última gravação do resumo",
                   value: report.map { $0.date.formatted(date: .omitted, time: .standard) } ?? "nenhuma",
                   color: Theme.textSecondary, icon: nil)
            RowDivider()
            inline("Arquivo do Scriptable",
                   value: WidgetBridge.scriptableFileExists ? "Gravado" : "Ausente",
                   color: WidgetBridge.scriptableFileExists ? Theme.finance : Theme.training,
                   icon: WidgetBridge.scriptableFileExists ? "checkmark" : "exclamationmark.triangle.fill")
            RowDivider()
            inline("Memória do widget", value: memoryValue, color: Theme.textSecondary, icon: nil)
            RowDivider()
            stacked("Identificador instalado",
                    value: Bundle.main.bundleIdentifier ?? "desconhecido",
                    ok: nil)
        }
        .jarvisListCard()
    }

    private var memoryValue: String {
        guard let memory = WidgetShared.readWidgetMemory() else {
            return container == nil ? "exige o App Group" : "adicione o widget nativo"
        }
        return ByteCountFormatter.string(fromByteCount: Int64(memory.availableBytes), countStyle: .memory) + " livres"
    }

    /// Rótulo em cima e valor técnico embaixo (nomes longos não cabem lado a lado).
    private func stacked(_ title: String, value: String, ok: Bool?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 6) {
                if let ok {
                    Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(ok ? Theme.finance : Theme.training)
                        .accessibilityLabel(ok ? "Certo" : "Atenção")
                }
                Text(value)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func inline(_ title: String, value: String, color: Color, icon: String?) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
            Spacer(minLength: 8)
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            }
            Text(value)
                .font(.subheadline)
                .foregroundStyle(color)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: Theme.minTouch)
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
            .buttonBorderShape(.capsule)
            .tint(Theme.accent)

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
        .jarvisCard()
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
