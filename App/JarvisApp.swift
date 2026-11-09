import SwiftUI
import UIKit

@main
struct JarvisApp: App {
    @StateObject private var lock = AppLock()

    init() {
        SettingsDefaults.register()
        FirstLaunch.purgeLeftoverSecretsIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            AppRoot()
                .environmentObject(lock)
                .tint(Theme.accent)
        }
    }
}

/// Liga o ciclo de vida do app às regras de segurança. Portado do Fluxo.
///
/// - Antes do primeiro desbloqueio da sessão, nenhuma tela com dados é montada.
/// - Bloquear cobre o app com uma janela própria; o que estava aberto continua.
/// - Uma sessão nova (após 5 min fora) recria todas as telas do zero,
///   descartando da memória tudo o que estava carregado.
struct AppRoot: View {
    @EnvironmentObject private var lock: AppLock
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKey.shieldInSwitcher) private var shieldInSwitcher = true
    @State private var shield = ShieldWindowController()
    @State private var lockWindow = LockWindowController()

    var body: some View {
        ZStack {
            if lock.sessionStarted {
                RootView()
                    .id(lock.sessionID)                   // sessão nova = telas novas
                    .accessibilityHidden(lock.isLocked)   // VoiceOver não lê o que está por baixo
            } else {
                Theme.background.ignoresSafeArea()
            }
        }
        // Toque num widget: o destino fica guardado até o app ser desbloqueado.
        .onOpenURL { url in
            if let link = DeepLink(url: url) {
                DeepLinkRouter.shared.pending = link
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase != .active { Self.dismissKeyboard() }
            lock.handleScenePhase(phase)
            if phase == .active {
                shield.hide()
            } else if shieldInSwitcher {
                shield.show()
            }
            // Ao sair do app, o resumo é gravado de novo: o widget passa a refletir
            // o que acabou de ser feito (um gasto, um treino concluído).
            if phase == .background && lock.sessionStarted { WidgetBridge.refresh() }
        }
        .onChange(of: lock.isLocked, initial: true) { _, locked in
            if locked {
                lockWindow.show(lock: lock)
            } else {
                lockWindow.hide()
            }
        }
    }

    /// Fecha o teclado ao sair do app. Assim o iOS não "esquece" o espaço
    /// reservado para ele, que empurraria a barra de abas para o meio da tela.
    private static func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
