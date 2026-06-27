import Foundation

/// Rolle eines Familienmitglieds. Roh-Werte identisch zu MyFamilyPilots `MemberRole`,
/// damit der geteilte Roster app-übergreifend konsistent bleibt.
public enum FamilyMemberRole: String, CaseIterable, Sendable {
    case owner
    case partner
    case child
    case grandparent
    case pet
    case trustedPerson
    case other

    /// Lokalisiert über `Bundle.main` (Standard von `String(localized:)`) — die
    /// konsumierende App (MyOfficePilot rendert die Package-Screens) liefert de/en/es
    /// aus ihrem String-Catalog. Bewusst NICHT `bundle: .module`, damit SwiftUI `Text`
    /// und diese Rollennamen dieselbe (App-)Quelle nutzen.
    public var localizedName: String {
        switch self {
        case .owner:         return String(localized: "Inhaber")
        case .partner:       return String(localized: "Partner")
        case .child:         return String(localized: "Kind")
        case .grandparent:   return String(localized: "Großeltern")
        case .pet:           return String(localized: "Haustier")
        case .trustedPerson: return String(localized: "Vertrauensperson")
        case .other:         return String(localized: "Sonstige")
        }
    }

    /// Schreibrechte-Regel der Rolle.
    public enum ForcedWrite { case alwaysTrue, alwaysFalse, toggleable }

    public var forcedCanWrite: ForcedWrite {
        switch self {
        case .owner:               return .alwaysTrue
        case .child, .pet:         return .alwaysFalse
        default:                   return .toggleable
        }
    }

    /// Default-Schreibrecht, wenn der Nutzer nichts überschreibt.
    public var defaultCanWrite: Bool {
        switch self {
        case .owner, .partner: return true
        default:               return false
        }
    }

    /// Aufgelöstes Schreibrecht aus Rolle + optionalem Override.
    public func effectiveCanWrite(override: Bool?) -> Bool {
        switch forcedCanWrite {
        case .alwaysTrue:  return true
        case .alwaysFalse: return false
        case .toggleable:  return override ?? defaultCanWrite
        }
    }

    /// Fallback-Icon (Haustier = Pfote), sonst Initialen/Foto.
    public var fallbackIcon: String? {
        self == .pet ? "pawprint.fill" : nil
    }
}
