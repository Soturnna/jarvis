import SwiftUI

/// Tela de bloqueio, exibida numa janela própria por cima do app. Portada do Fluxo,
/// com o visual do Jarvis.
struct LockView: View {
    @EnvironmentObject private var lock: AppLock

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                AppMark(size: 80)
                Text("Jarvis")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 18)
                Text("Seu dia em um só lugar.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Label("Bloqueado", systemImage: "lock.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)

                Spacer()

                if let message = lock.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 14)
                }

                Button {
                    Task { await lock.unlock() }
                } label: {
                    Label("Desbloquear com \(lock.biometryName)", systemImage: lock.biometryIcon)
                }
                .buttonStyle(ModuleButtonStyle(color: Color(hex: 0x64D2FF)))
                .disabled(lock.isAuthenticating)

                Text("O app bloqueia sozinho ao sair e esconde o conteúdo no alternador de apps.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        // O pedido automático de Face ID é feito pelo AppLock,
        // que acompanha o ciclo de vida do app.
    }
}
