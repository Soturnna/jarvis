import SwiftUI

enum AppTab: Hashable {
    case today, finance, training, nutrition, assistant
}

/// Estrutura do app desbloqueado: as cinco abas.
///
/// A barra é o TabView nativo. Compilado com o SDK do iOS 26, ele já desenha a
/// cápsula flutuante de Liquid Glass; no iOS 17 e 18, vira a barra padrão.
/// A aba ativa usa a cor de destaque (o `tint` aplicado no JarvisApp).
struct RootView: View {
    @State private var tab: AppTab = .today
    @EnvironmentObject private var lock: AppLock
    @ObservedObject private var deepLinks = DeepLinkRouter.shared

    var body: some View {
        TabView(selection: $tab) {
            TodayView(open: { tab = $0 })
                .tabItem { Label("Hoje", systemImage: "sun.max.fill") }
                .tag(AppTab.today)

            ModulePlaceholderView(module: .finance)
                .tabItem { Label("Finanças", systemImage: "creditcard.fill") }
                .tag(AppTab.finance)

            ModulePlaceholderView(module: .training)
                .tabItem { Label("Treino", systemImage: "dumbbell.fill") }
                .tag(AppTab.training)

            ModulePlaceholderView(module: .nutrition)
                .tabItem { Label("Nutrição", systemImage: "fork.knife") }
                .tag(AppTab.nutrition)

            ModulePlaceholderView(module: .assistant)
                .tabItem { Label("Assistente", systemImage: "sparkles") }
                .tag(AppTab.assistant)
        }
        // Ao abrir a sessão, grava os arquivos de widget: assim a pasta do Jarvis
        // já aparece no app Arquivos para o Scriptable.
        .task { WidgetBridge.refresh() }
        // Destino vindo de um widget: só é seguido com o app desbloqueado.
        .onChange(of: deepLinks.pending, initial: true) { _, _ in followDeepLink() }
        .onChange(of: lock.isLocked) { _, _ in followDeepLink() }
    }

    private func followDeepLink() {
        guard !lock.isLocked, let link = deepLinks.pending else { return }
        deepLinks.pending = nil
        switch link {
        case .today: tab = .today
        case .finance, .register: tab = .finance   // "registrar" abre a folha de gasto na fase 1
        case .training: tab = .training
        case .nutrition: tab = .nutrition
        case .assistant: tab = .assistant
        }
    }
}
