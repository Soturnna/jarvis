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

    /// Trilho das barras de progresso (#3A3A3C no modo escuro).
    static let track = Color(.systemGray4)
    /// Linha fina entre as linhas de um cartão (#2C2C2E no modo escuro).
    static let hairline = Color(.tertiarySystemBackground)

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

/// Botão principal: cápsula preenchida com a cor do módulo e texto escuro.
/// A resposta ao toque vem do LimeButtonStyle do Fluxo: escurece e, sem
/// "Reduzir movimento", encolhe 2% (sem mexer no layout em volta).
struct ModuleButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.bold))
            .foregroundStyle(Theme.onModule)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(color, in: Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Resposta ao toque dos cartões que abrem algo (a grade da aba Hoje).
struct PressableCardStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Ícone dentro de um quadrado arredondado, tingido com a cor do módulo a 18%.
struct IconChip: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.47, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Cabeçalho de cartão: ícone na cor do módulo, título e um complemento à direita.
struct CardHeader<Trailing: View>: View {
    let icon: String
    let title: String
    let color: Color
    /// O título acompanha a cor do ícone (usado no "Resumo do dia").
    var tintedTitle = false
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tintedTitle ? color : Color.primary)
            Spacer(minLength: 8)
            trailing()
        }
    }
}

extension CardHeader where Trailing == EmptyView {
    init(icon: String, title: String, color: Color, tintedTitle: Bool = false) {
        self.init(icon: icon, title: title, color: color, tintedTitle: tintedTitle, trailing: { EmptyView() })
    }
}

/// Barra de progresso fina. `fraction` nil = ainda sem dado (só o trilho).
struct ProgressTrack: View {
    var fraction: Double?
    var color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                if let fraction {
                    Capsule()
                        .fill(color)
                        .frame(width: max(height, proxy.size.width * min(max(fraction, 0), 1)))
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Estado de um módulo. Sempre ícone + texto, nunca só a cor.
enum StatusKind {
    case active, stale, configure, pending

    var icon: String {
        switch self {
        case .active: return "checkmark"
        case .stale: return "clock"
        case .configure: return "chevron.right"
        case .pending: return "minus.circle"
        }
    }

    var color: Color {
        switch self {
        case .active: return Theme.finance
        case .stale: return Theme.training
        case .configure: return Theme.accent
        case .pending: return Theme.textSecondary
        }
    }
}

struct StatusLabel: View {
    let kind: StatusKind
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: kind.icon)
                .font(.caption.weight(.bold))
                .accessibilityHidden(true)
            Text(text)
                .font(.footnote.weight(.semibold))
        }
        .foregroundStyle(kind.color)
    }
}

extension View {
    /// Liquid Glass só na camada de navegação e de controles (iOS 26+). Do Fluxo.
    /// Em versões anteriores cai para um material padrão; o sistema troca o vidro
    /// sozinho com "Reduzir transparência" ou "Aumentar contraste".
    @ViewBuilder
    func jarvisGlass<S: Shape>(in shape: S) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
        #else
        self.background(.ultraThinMaterial, in: shape)
        #endif
    }

    /// Lista dentro de um cartão: sem margem interna, para as linhas irem de borda a borda.
    func jarvisListCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

/// Linha fina entre as linhas de um cartão de lista.
struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// Título de seção das telas de lista (Ajustes).
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased())
            .font(.footnote)
            .tracking(0.3)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.isHeader)
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
