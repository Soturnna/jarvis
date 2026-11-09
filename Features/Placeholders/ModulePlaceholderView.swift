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
    let features: [String]

    static let finance = PendingModule(
        overline: "Fase 1", title: "Finanças", icon: "creditcard.fill", color: Theme.finance, phase: 1,
        source: "Vem do Fluxo",
        features: ["Open Finance pelo Meu Pluggy", "Cofre cifrado e categorias", "Orçamentos e fluxo de caixa",
                   "Cartão com faturas por ciclo", "Investimentos"])

    static let training = PendingModule(
        overline: "Fase 2", title: "Treino", icon: "dumbbell.fill", color: Theme.training, phase: 2,
        source: "Vem do Forja",
        features: ["Gerador de fichas por regras", "Execução com carga e repetições", "Progresso e Apple Watch",
                   "Academia e catálogo de exercícios", "Coach de saúde"])

    static let nutrition = PendingModule(
        overline: "Fase 3", title: "Nutrição", icon: "fork.knife", color: Theme.nutrition, phase: 3,
        source: "Vem do Forja",
        features: ["Diário com a tabela TACO", "Prato por foto", "Metas de calorias e proteína", "Dicas por regra"])

    static let assistant = PendingModule(
        overline: "Fases 1 e 2", title: "Assistente", icon: "sparkles", color: Theme.accent, phase: 1,
        source: "Agente do Fluxo e Coach do Forja",
        features: ["Seletor Finanças | Saúde", "Propostas aplicadas só após Confirmar",
                   "Registro auditável do que vai à IA"])
}

/// Aba vazia, já com o visual do Jarvis: título grande, cartão e a lista do que virá.
struct ModulePlaceholderView: View {
    let module: PendingModule

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Overline(module.overline)
                    Text(module.title)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: module.icon)
                            .font(.title2)
                            .foregroundStyle(module.color)
                            .frame(width: 44, height: 44)
                            .background(Theme.cardInner, in: RoundedRectangle(cornerRadius: Theme.innerRadius, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Módulo ainda não instalado")
                                .font(.headline)
                            Label("Pendente · \(module.source)", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(module.features.enumerated()), id: \.offset) { index, feature in
                            if index > 0 { Divider() }
                            Label(feature, systemImage: "circle.dashed")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, minHeight: Theme.minTouch, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 12)
                    .background(Theme.cardInner, in: RoundedRectangle(cornerRadius: Theme.innerRadius, style: .continuous))
                }
                .jarvisCard()

                Text("Esta aba recebe o conteúdo quando a fase \(module.phase) for entregue.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, Theme.margin)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
    }
}
