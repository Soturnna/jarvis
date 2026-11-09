import WidgetKit
import SwiftUI

/// Widgets nativos do Jarvis (caminho WidgetKit).
///
/// Eles não buscam nada na internet nem abrem o cofre: só leem o resumo que o app
/// grava na pasta do App Group (ver WidgetShared). Sem o App Group, o iOS nem
/// chega a oferecer estes widgets; o caminho que sempre funciona é o Scriptable.
///
/// Regras de memória (a extensão tem cerca de 30 MB): nada de AsyncImage ou
/// downloads aqui dentro, só texto e SF Symbols.
struct JarvisEntry: TimelineEntry {
    let date: Date
    let envelope: WidgetShared.Envelope?
}

struct JarvisProvider: TimelineProvider {
    func placeholder(in context: Context) -> JarvisEntry {
        JarvisEntry(date: .now, envelope: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (JarvisEntry) -> Void) {
        // Na galeria de widgets, um exemplo; na tela, os dados de verdade.
        let real = WidgetShared.readFromGroup()
        completion(JarvisEntry(date: .now, envelope: context.isPreview && real == nil ? Self.sample : real))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JarvisEntry>) -> Void) {
        // Registra a memória livre para a tela de Diagnóstico.
        WidgetShared.recordWidgetMemory(family: String(describing: context.family))
        let entry = JarvisEntry(date: .now, envelope: WidgetShared.readFromGroup())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date) ?? entry.date
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private static let sample = WidgetShared.Envelope(
        schemaVersion: WidgetShared.schemaVersion, updatedAt: .now, showValues: false, note: "Seu dia em um só lugar")
}

/// Widget de teste da fase 0: mostra o texto gravado no app e a hora da última atualização.
/// Os widgets definitivos (Painel do dia, Finanças, Treino etc.) entram na fase 5.
struct PanelWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "jarvis.painel", provider: JarvisProvider()) { entry in
            PanelWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.black }
                .widgetURL(URL(string: "jarvis://hoje"))
        }
        .configurationDisplayName("Painel")
        .description("Mostra o que o Jarvis gravou por último.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct PanelWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: JarvisEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text("JARVIS")
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(family == .accessoryRectangular ? Color.primary : Color(hex: 0x64D2FF))

            Text(message)
                .font(family == .accessoryRectangular ? .footnote : .subheadline.weight(.semibold))
                .foregroundStyle(family == .accessoryRectangular ? Color.primary : Color.white)
                .lineLimit(family == .systemSmall ? 4 : 3)
                .minimumScaleFactor(0.8)

            if family != .accessoryRectangular { Spacer(minLength: 0) }

            // Toda entrada mostra a hora da última atualização.
            if let updatedAt = entry.envelope?.updatedAt {
                (Text("Atualizado ") + Text(updatedAt, style: .time))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var message: String {
        guard let envelope = entry.envelope else { return "Abra o Jarvis para gravar o resumo." }
        return envelope.note ?? "Sem texto de teste. Grave um em Ajustes."
    }
}

@main
struct JarvisWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PanelWidget()
    }
}
