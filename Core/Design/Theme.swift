import SwiftUI
import UIKit

/// Identidade visual do Jarvis em um só lugar (substitui os temas do Fluxo e do Forja).
///
/// Cada cor tem um papel fixo. O modo escuro é o principal; no modo claro, as cores
/// vêm das variantes do próprio sistema, que já garantem contraste.
/// Este arquivo também é compilado na extensão de widgets, então não pode depender
/// de nada do app (nem do catálogo de imagens).
enum Theme {
    // Fundos e superfícies
    static let background = Color(.systemBackground)                  // preto no modo escuro
    static let card = Color(.secondarySystemBackground)               // #1C1C1E no modo escuro
    static let cardInner = Color(.tertiarySystemBackground)           // #2C2C2E no modo escuro
    static let textSecondary = Color.secondary

    // Destaque: briefing da IA, aba ativa e links. #64D2FF no escuro; azul mais fechado no claro.
    static let accent = Color(dynamic(dark: 0x64D2FF, light: 0x0071A4))

    // Uma cor por módulo (no modo escuro: os valores do documento de especificação).
    static let finance = Color(.systemGreen)      // #30D158
    static let training = Color(.systemOrange)    // #FF9F0A (também alertas, como a fatura)
    static let nutrition = Color(.systemYellow)   // #FFD60A
    static let health = Color(.systemPink)        // #FF375F
    static let calendar = Color(.systemRed)       // #FF453A
    static let mail = Color(dynamic(dark: 0x409CFF, light: 0x007AFF))

    /// Texto sobre um botão preenchido com a cor do módulo (sempre escuro).
    static let onModule = Color(hex: 0x0B0B0C)

    // Medidas
    static let cardRadius: CGFloat = 22
    static let innerRadius: CGFloat = 14
    static let margin: CGFloat = 16
    /// Área mínima de toque.
    static let minTouch: CGFloat = 44

    private static func dynamic(dark: UInt32, light: UInt32) -> UIColor {
        UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    /// Cria uma cor a partir de um hexadecimal, por exemplo `Color(hex: 0x64D2FF)`.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension View {
    /// Cartão padrão: fundo secundário, raio de 22 pt, sem vidro.
    func jarvisCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

/// Rótulo pequeno em maiúsculas (data no topo das telas, títulos de seção).
struct Overline: View {
    let text: String
    var color: Color = Theme.textSecondary

    init(_ text: String, color: Color = Theme.textSecondary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(color)
    }
}

/// Botão principal: preenchido com a cor do módulo e texto escuro.
struct ModuleButtonStyle: ButtonStyle {
    var color: Color = Theme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.onModule)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(color, in: RoundedRectangle(cornerRadius: Theme.innerRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// Marca do app (a mesma forma do ícone), desenhada em código.
struct AppMark: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: 0x2C2C2E), lineWidth: size * 0.11)
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(Color(hex: 0x64D2FF), style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .fill(Color(hex: 0x64D2FF))
                .frame(width: size * 0.26, height: size * 0.26)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
