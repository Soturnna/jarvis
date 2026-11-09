import SwiftUI

/// Aba Hoje. O layout segue o canvas "Jarvis — Aparência do app e widgets".
/// Na fase 0 os cartões já têm a forma final, mas sem dados: cada valor aparece
/// como "—" e diz em que fase chega. Nenhum número é inventado.
struct TodayView: View {
    /// Troca de aba (os cartões da grade abrem a aba do seu módulo).
    let open: (AppTab) -> Void

    @AppStorage(SettingsKey.profileName) private var profileName = "Marcos"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSettings = false
    @State private var lastReport = WidgetBridge.lastReport
    @State private var refreshCount = 0

    private var dateLine: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "pt_BR")))
    }

    private var initial: String {
        profileName.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "J"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    summaryCard
                    agendaCard

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                        tile("Pode gastar hoje", icon: "creditcard.fill", color: Theme.finance,
                             caption: "Chega na fase 1", tab: .finance)
                        tile("Treino de hoje", icon: "dumbbell.fill", color: Theme.training,
                             caption: "Chega na fase 2", tab: .training)
                        tile("Nutrição", icon: "fork.knife", color: Theme.nutrition,
                             caption: "Chega na fase 3", showsTrack: true, tab: .nutrition)
                        tile("Passos", icon: "figure.walk", color: Theme.health,
                             caption: "Chega na fase 2", showsTrack: true, tab: .training)
                    }

                    mailRow
                }
                .padding(.horizontal, Theme.margin)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            // O cabeçalho (data, título e botões) faz parte do conteúdo, como no canvas.
            // O nome fica aqui só para o botão Voltar de Ajustes dizer "Hoje".
            .navigationTitle("Hoje")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .onAppear { lastReport = WidgetBridge.lastReport }
            .sensoryFeedback(.impact(weight: .light), trigger: refreshCount)
        }
    }

    // MARK: Cabeçalho

    private var header: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Overline(dateLine)
                Text("Hoje")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: 8)

            // Controles: a única camada da tela que usa vidro.
            Button {
                lastReport = WidgetBridge.refresh()
                refreshCount += 1
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .rotationEffect(.degrees(reduceMotion ? 0 : Double(refreshCount) * 360))
                    .animation(.easeInOut(duration: 0.5), value: refreshCount)
                    .frame(width: Theme.minTouch, height: Theme.minTouch)
                    .jarvisGlass(in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Atualizar painel")

            Button {
                showSettings = true
            } label: {
                Text(initial)
                    .font(.body.weight(.bold))
                    .frame(width: Theme.minTouch, height: Theme.minTouch)
                    .background(Theme.cardInner, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ajustes")
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    // MARK: Cartões

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardHeader(icon: "sparkles", title: "Resumo do dia", color: Theme.accent, tintedTitle: true) {
                if let report = lastReport {
                    Text("atualizado às \(report.date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Text("A fundação está pronta: bloqueio por Face ID, cofre cifrado e a ponte dos widgets. O briefing com IA aparece aqui na fase 7.")
                .font(.callout)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .jarvisCard()
    }

    private var agendaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardHeader(icon: "calendar", title: "Agenda", color: Theme.calendar) {
                StatusLabel(kind: .pending, text: "Fase 5")
            }
            HStack(spacing: 12) {
                Capsule()
                    .fill(Theme.calendar)
                    .frame(width: 4, height: 34)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Próximos compromissos")
                        .font(.subheadline.weight(.semibold))
                    Text("Os dois próximos eventos, com o tempo que falta")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .jarvisCard(padding: 14)
    }

    private func tile(_ title: String, icon: String, color: Color, caption: String,
                      showsTrack: Bool = false, tab: AppTab) -> some View {
        Button {
            open(tab)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .accessibilityHidden(true)
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.caption.weight(.semibold))

                // Sem dado ainda: travessão no lugar do valor.
                Text("—")
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityLabel("Sem dados")

                if showsTrack {
                    ProgressTrack(fraction: nil, color: color)
                        .padding(.vertical, 3)
                }
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .topLeading)
            .jarvisCard(padding: 14)
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Abre a aba do módulo")
    }

    private var mailRow: some View {
        HStack(spacing: 12) {
            IconChip(systemName: "envelope.fill", color: Theme.mail)
            VStack(alignment: .leading, spacing: 2) {
                Text("E-mail")
                    .font(.subheadline.weight(.semibold))
                Text("Não lidos e remetentes importantes")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 8)
            StatusLabel(kind: .pending, text: "Fase 6")
        }
        .jarvisCard(padding: 14)
        .accessibilityElement(children: .combine)
    }
}
