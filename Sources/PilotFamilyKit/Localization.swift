import Foundation

/// Lokalisiert einen Key über das PACKAGE-Bundle (`Bundle.module`) — damit die
/// Package-Screens unabhängig vom String-Catalog der konsumierenden App in de/en/es
/// erscheinen. Nötig, weil SwiftUI `Text`/`Label`/`Section` in einem SPM-Package sonst
/// gegen das Haupt-Bundle der App auflösen. Rückgabe ist ein bereits aufgelöster String;
/// an die SwiftUI-Controls als `StringProtocol` (verbatim) übergeben.
func pfL(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}
