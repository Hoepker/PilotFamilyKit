import Foundation
import SwiftData

/// Übergreifender „Vertrag" der MyPilot-Suite — ein schlanker Spiegel eines
/// MyFamilyPilot-`Entry` (Vertrag/Versicherung/Abo/Sparen). Liegt im GETEILTEN
/// CloudKit-Container `iCloud.de.hoepker.pilotsuite`.
///
/// Datenfluss: **MyFamilyPilot SCHREIBT** (Quelle der Wahrheit), **MyOfficePilot LIEST
/// nur** und materialisiert daraus eine Akte (`origin == .contract`). Die Freigaben
/// (`shareGrantsRaw`) sind reine **Lese-Info** für die Anzeige „wer hat Zugriff" — die
/// Hoheit über das Teilen bleibt in MyFamilyPilot.
///
/// WICHTIG (CloudKit): Klassenname stabil halten (Record-Typ `CD_SuiteContract`). Alle
/// Felder mit Default bzw. optional, kein `@Attribute(.unique)` — wie `SuiteFamilyMember`.
@Model
public final class SuiteContract {
    /// Identisch zur MyFamilyPilot-`Entry.id` → dient MyOfficePilot als `sourceRef`.
    public var id: UUID = UUID()
    public var title: String = ""
    public var providerName: String = ""
    /// `EntryType`-RawValue (contract/insurance/subscription/savings) — für Icon/Label.
    public var entryTypeRaw: String = "contract"
    public var startDate: Date?
    public var endDate: Date?
    /// Pro-Person-Freigaben im Format `"<key>:<level>"`, `\n`-getrennt (key = "family"
    /// oder Mitglieds-UUID). READ-ONLY in MyOfficePilot — nur zur Anzeige.
    public var shareGrantsRaw: String = ""
    /// Anzahl der im Vertrag hinterlegten Dokumente (in MyFamilyPilot) — damit
    /// MyOfficePilot die Zahl auf der Akten-Kachel zeigen kann, ohne MFPs Dokument-
    /// Container zu kennen.
    public var documentCount: Int = 0
    /// Inhaber des Vertrags (MyFamilyPilot `Entry.ownerID`). Zusammen mit
    /// `shareGrants` ergibt das „wer kann den Vertrag sehen" (Inhaber + Empfänger).
    public var ownerID: UUID?
    public var updatedAt: Date = Date()
    public var createdAt: Date = Date()

    public init(id: UUID = UUID(), title: String = "", providerName: String = "",
                entryTypeRaw: String = "contract", startDate: Date? = nil, endDate: Date? = nil,
                shareGrantsRaw: String = "", documentCount: Int = 0, ownerID: UUID? = nil,
                updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.providerName = providerName
        self.entryTypeRaw = entryTypeRaw
        self.startDate = startDate
        self.endDate = endDate
        self.shareGrantsRaw = shareGrantsRaw
        self.documentCount = documentCount
        self.ownerID = ownerID
        self.updatedAt = updatedAt
        self.createdAt = Date()
    }

    /// Freigaben als Liste (Roh-Strings „<key>:<level>"). Reine Anzeige.
    public var shareGrants: [String] {
        get { shareGrantsRaw.isEmpty ? [] : shareGrantsRaw.components(separatedBy: "\n") }
        set { shareGrantsRaw = newValue.joined(separator: "\n") }
    }
}
