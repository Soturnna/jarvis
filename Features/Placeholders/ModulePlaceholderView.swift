import SwiftUI

/// Descrição de uma aba que ainda não recebeu seu módulo.
/// Cada fase troca um destes pela tela de verdade.
struct PendingModule {
    let overline: String
    let title: String
    let icon: String
    let color: Color
    let phase: Int
    let source: String
    let summary: String
    let features: [String]

    static let finance = PendingModule(
        overline: "Vem do Fluxo", title: "Finanças", icon: "creditcard.fill", color: Theme.finance, phase: 1,
        source: "Fluxo",
        summary: "Saldo estimado, quanto pode gastar por dia, fatura do cartão e transações.",
        features: ["Open Finance pelo Meu Pluggy", "Cofre cifrado e categorias", "Orçamentos e fluxo de caixa",
                   "Cartão com faturas por ciclo", "Investimentos"])

    static let training = PendingModule(
        overline: "Vem do Forja", title: "Treino", icon: "dumbbell.fill", color: Theme.training, phase: 2,
        source: "Forja",
        summary: "A semana em 7 círculos, o treino do dia com cargas e a sugestão de progressão.",
        features: ["Gerador de fichas por regras", "Execução com carga e repetições", "Progresso e Apple Watch",
                   "Academia e catálogo de exercícios"])

    static let nutrition = PendingModule(
        overline: "Vem do Forja", title: "Nutrição", icon: "fork.knife", color: Theme.nutrition, phase: 3,
        source: "Forja",
        summary: "Anel de calorias restantes, proteína, carboidratos e gorduras, e as refeições do dia.",
        features: ["Diário com a tabela TACO", "Prato por foto", "Metas de calorias e proteína", "Dicas por regra"])

    static let assistant = PendingModule(
        overline: "Fluxo e Forja", title: "Assistente", icon: "bubble.left.fill", color: Theme.accent, phase: 1,
        source: "agente do Fluxo e Coach do Forja",
        summary: "Uma conversa com seletor Finanças | Saúde. Cada lado mantém as suas travas.",
        features: ["Propostas aplicadas só após Confirmar", "Registro auditável do que vai à IA",
                   "Coach restrito a treino, alimentação, sono e recuperação"])
}

/// Aba vazia, já com o visual do Jarvis: cabeçalho, cartão de destaque e o que virá.
struct ModulePlaceholderView: View {
    let module: PendingModule

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Overline(module.overline)
                    Text(module.title)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)

                // Destaque: o que esta aba vai mostrar.
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        IconChip(systemName: module.icon, color: module.color, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fase \(module.phase)")
                                .font(.caption.weight(.bold))
                                .tracking(0.3)
                                .textCase(.uppercase)
                                .foregroundStyle(module.color)
                            Text("Ainda não instalado")
                                .font(.title3.bold())
                        }
                    }
                    Text(module.summary)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    ProgressTrack(fraction: nil, color: module.color, height: 8)
                }
                .jarvisCard()

                // O que vem junto, em linhas separadas por fios, como as listas do canvas.
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(module.features.enumerated()), id: \.offset) { index, feature in
                        if index > 0 { RowDivider() }
                        HStack(spacing: 12) {
                            Circle()
                                .fill(module.color)
                                .frame(width: 8, height: 8)
                                .accessibilityHidden(true)
                            Text(feature)
                                .font(.subheadline)
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: Theme.minTouch)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .jarvisListCard()

                Text("O código vem do \(module.source), já testado, e é adaptado ao Jarvis.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, Theme.margin)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
    }
}
