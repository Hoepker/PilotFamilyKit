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

    nonisolated public static func personKey(_ m: SuiteFamilyMember) -> String {
        let name = m.displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return name.isEmpty ? "id:\(m.id.uuidString)" : "\(name)|\(m.roleRaw)"
    }

    /// Genau ein Eintrag pro Person — kanonisch = ältester (`createdAt`, Tie-Break UUID).
    nonisolated public static func canonical(_ members: [SuiteFamilyMember]) -> [SuiteFamilyMember] {
        var map: [String: SuiteFamilyMember] = [:]
        for m in members {
            let key = personKey(m)
            if let existing = map[key] {
                let wins = m.createdAt < existing.createdAt
                    || (m.createdAt == existing.createdAt && m.id.uuidString < existing.id.uuidString)
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
