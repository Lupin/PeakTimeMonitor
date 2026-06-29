import SwiftUI
import WidgetKit

/// Point d'entrée pour l'extension WidgetKit.
/// Déclare tous les widgets fournis par cette extension.
@main
struct PeakTimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        PeakTimeWidget()
    }
}
