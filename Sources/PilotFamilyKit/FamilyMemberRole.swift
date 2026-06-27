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

    /// Lokalisiert über das PACKAGE-Bundle (`Bundle.module`) — das Package bringt sein
    /// eigenes String-Catalog (de/en/es) mit und ist damit für JEDE konsumierende App
    /// selbst-lokalisierend (siehe [[Localization]]).
    public var localizedName: String {
        switch self {
        case .owner:         return pfL("Inhaber")
        case .partner:       return pfL("Partner")
        case .child:         return pfL("Kind")
        case .grandparent:   return pfL("Großeltern")
        case .pet:           return pfL("Haustier")
        case .trustedPerson: return pfL("Vertrauensperson")
        case .other:         return pfL("Sonstige")
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
