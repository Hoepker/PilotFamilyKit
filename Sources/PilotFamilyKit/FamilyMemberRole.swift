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

    public var localizedName: String {
        switch self {
        case .owner:         return "Inhaber"
        case .partner:       return "Partner"
        case .child:         return "Kind"
        case .grandparent:   return "Großeltern"
        case .pet:           return "Haustier"
        case .trustedPerson: return "Vertrauensperson"
        case .other:         return "Sonstige"
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
