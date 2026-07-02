import Foundation
import SwiftData

/// Verwaltung des geteilten Familien-Rosters (`SuiteFamilyMember`) auf einem
/// ModelContext. Wird von der zentralen Verwaltungs-UI genutzt; beide Apps reichen
/// ihren Suite-Container-Context herein.
@MainActor
public struct FamilyStore {
    public let context: ModelContext
    public init(context: ModelContext) { self.context = context }

    /// Roh-Fetch aller Mitglieder.
    public func allMembers() -> [SuiteFamilyMember] {
        (try? context.fetch(FetchDescriptor<SuiteFamilyMember>(
            sortBy: [SortDescriptor(\.joinedAt)]))) ?? []
    }

    /// Dedupliziertes Roster für die Anzeige (eine Zeile pro Person).
    public func members() -> [SuiteFamilyMember] {
        Self.canonical(allMembers())
    }

    @discardableResult
    public func save(_ member: SuiteFamilyMember) -> SuiteFamilyMember {
        if member.modelContext == nil { context.insert(member) }
        try? context.save()
        return member
    }

    public func delete(_ member: SuiteFamilyMember) {
        // Alle Duplikate derselben Person mitlöschen (konsistent zur Anzeige).
        let key = Self.personKey(member)
        for m in allMembers() where Self.personKey(m) == key {
            context.delete(m)
        }
        try? context.save()
    }

    // MARK: - Dedup

    /// Geräte-stabiler Identitäts-Schlüssel EINER Person (OHNE Rolle). Primär der
    /// normalisierte Name — das einzige Feld, das auf jeder Kopie garantiert
    /// gesetzt ist (`displayName` ist Pflicht) und über Geräte hinweg stabil
    /// bleibt. NIE über geräte-lokale IDs (z.B. Contacts-`contactIdentifier`) oder
    /// `email` schlüsseln: die sind mal gesetzt, mal nicht, und `contactIdentifier`
    /// unterscheidet sich pro Gerät → dieselbe Person wird in mehrere Einträge
    /// gespalten (der Mehrfach-Bug). Fallback auf `id` nur bei leerem Namen.
    ///
    /// EINE Quelle der Wahrheit für die ganze Suite: `personKey` (Roster, mit
    /// Rolle) baut hierauf auf, und MyFamilyPilot delegiert für seine
    /// familienübergreifende Entdopplung ebenfalls hierher (dort OHNE Rolle,
    /// weil dieselbe Person je Familie eine andere Rolle haben kann).
    nonisolated public static func identityKey(displayName: String, id: UUID) -> String {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return name.isEmpty ? "id:\(id.uuidString)" : "name:\(name)"
    }

    /// Dedup-Schlüssel im geteilten Suite-Roster: Identität + Rolle. Rolle im Key
    /// ist hier korrekt, weil jede Person im Roster genau EINE Rolle trägt.
    nonisolated public static func personKey(_ m: SuiteFamilyMember) -> String {
        "\(identityKey(displayName: m.displayName, id: m.id))|\(m.roleRaw)"
    }

    /// Genau ein Eintrag pro Person. Gewinner: Foto schlägt kein-Foto (cross-app
    /// liefert MyFamilyPilot das Bild — ein photoloser Seed-Import-Zwilling darf es
    /// nicht verdecken), danach der älteste (`createdAt`, Tie-Break UUID).
    nonisolated public static func canonical(_ members: [SuiteFamilyMember]) -> [SuiteFamilyMember] {
        var map: [String: SuiteFamilyMember] = [:]
        for m in members {
            let key = personKey(m)
            if let existing = map[key] {
                let mHasPhoto = (m.photoData?.isEmpty == false)
                let exHasPhoto = (existing.photoData?.isEmpty == false)
                let wins: Bool
                if mHasPhoto != exHasPhoto {
                    wins = mHasPhoto
                } else {
                    wins = m.createdAt < existing.createdAt
                        || (m.createdAt == existing.createdAt && m.id.uuidString < existing.id.uuidString)
                }
                if wins { map[key] = m }
            } else {
                map[key] = m
            }
        }
        return map.values.sorted {
            $0.joinedAt != $1.joinedAt ? $0.joinedAt < $1.joinedAt
                                       : $0.id.uuidString < $1.id.uuidString
        }
    }
}
