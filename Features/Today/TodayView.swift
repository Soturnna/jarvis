import SwiftUI

/// Aba Hoje. Na fase 0 ela mostra a estrutura visual e o estado da fundação;
/// os dados de verdade (briefing, agenda, resumos) chegam na fase 5.
struct TodayView: View {
    /// Troca de aba (os cartões da grade abrem a aba do seu módulo).
    let open: (AppTab) -> Void

    @State private var showSettings = false
    @State private var lastReport = WidgetBridge.lastReport

    private var dateLine: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "pt_BR")))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Overline(dateLine)
                        Text("Hoje")
                            .font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)
                    }

                    summaryCard
                    agendaCard

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                        tile("Pode gastar hoje", icon: "creditcard.fill", color: Theme.finance, phase: 1, tab: .finance)
                        tile("Treino de hoje", icon: "dumbbell.fill", color: Theme.training, phase: 2, tab: .training)
                        tile("Nutrição", icon: "fork.knife", color: Theme.nutrition, phase: 3, tab: .nutrition)
                        tile("Passos", icon: "figure.walk", color: Theme.health, phase: 2, tab: .training)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Theme.mail)
                            .accessibilityHidden(true)
                        Text("E-mail")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Label("Fase 6", systemImage: "clock")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .jarvisCard()
                }
                .padding(.horizontal, Theme.margin)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            // O título fica no conteúdo (data + "Hoje"); a barra só leva os botões.
            // O nome continua aqui para o botão Voltar da tela de Ajustes dizer "Hoje".
            .navigationTitle("Hoje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { Text("").accessibilityHidden(true) }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        lastReport = WidgetBridge.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Atualizar")

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .accessibilityLabel("Ajustes")
                }
            }
            .navigationDestination(isPresented: $showSettings) { SettingsView() }
            .onAppear { lastReport = WidgetBridge.lastReport }
        }
    }

    // MARK: Cartões

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Resumo do dia")
                    .font(.headline)
                Spacer()
                if let report = lastReport {
                    Text(report.date, style: .time)
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .accessibilityLabel("Atualizado às \(report.date.formatted(date: .omitted, time: .shortened))")
                }
            }
            Text("A fundação do Jarvis está instalada: bloqueio por Face ID, cofre e a ponte dos widgets.")
            Text("Os módulos entram um por fase. O briefing com IA chega na fase 7.")
                .foregroundStyle(Theme.textSecondary)
            Text("Para testar os widgets, toque no botão de perfil e abra Ajustes.")
                .foregroundStyle(Theme.textSecondary)
        }
        .font(.subheadline)
        .jarvisCard()
    }

    private var agendaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(Theme.calendar)
                    .accessibilityHidden(true)
                Text("Agenda")
                    .font(.headline)
                Spacer()
                Label("Fase 5", systemImage: "clock")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.calendar)
                    .frame(width: 4, height: 36)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Seus próximos compromissos")
                        .font(.subheadline.weight(.semibold))
                    Text("Aparecem aqui quando o módulo Agenda for entregue.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .jarvisCard()
    }

    private func tile(_ title: String, icon: String, color: Color, phase: Int, tab: AppTab) -> some View {
        Button {
            open(tab)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Label("Fase \(phase)", systemImage: "clock")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .jarvisCard(padding: 14)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Abre a aba do módulo")
    }
}
