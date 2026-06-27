import Foundation
import SwiftData

/// Übergreifendes Familienmitglied der MyPilot-Suite — das GEMEINSAME Modell für
/// alle Apps (MyFamilyPilot, MyOfficePilot, MyScanPilot). Liegt im geteilten CloudKit-
/// Container `iCloud.de.hoepker.pilotsuite`.
///
/// WICHTIG: Der Klassenname `SuiteFamilyMember` bleibt unverändert, damit der CloudKit-
/// Record-Typ `CD_SuiteFamilyMember` identisch bleibt und bestehende Daten + MyFamilyPilots
/// Spiegelung kompatibel sind. Felder bewusst alle mit Default/optional (CloudKit-Regel).
/// Die Felder `phone`/`birthday`/`address`/`notes` sind ADDITIV (älteres MyFamilyPilot
/// ohne diese Felder bleibt kompatibel — fehlende Felder werden als nil gelesen).
@Model
public final class SuiteFamilyMember {
    public var id: UUID = UUID()
    public var displayName: String = ""
    public var initials: String = ""
    public var email: String?
    /// Roh-Rolle (`FamilyMemberRole.rawValue`): owner/partner/child/grandparent/pet/
    /// trustedPerson/other.
    public var roleRaw: String = "partner"
    /// Aufgelöste Schreibrechte (Single Source of Truth über die Apps hinweg).
    public var canWrite: Bool = false
    public var avatarColorSeed: String = "pilot"
    @Attribute(.externalStorage) public var photoData: Data?
    public var joinedAt: Date = Date()
    /// Anlage-Zeitpunkt — für deterministische Dedup-Auswahl.
    public var createdAt: Date = Date()

    // Additive Kontakt-/Personen-Felder (für die zentrale Verwaltung).
    public var phone: String?
    public var birthday: Date?
    public var address: String?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        displayName: String = "",
        initials: String = "",
        email: String? = nil,
        roleRaw: String = "partner",
        canWrite: Bool = false,
        avatarColorSeed: String = "pilot",
        photoData: Data? = nil,
        joinedAt: Date = Date(),
        phone: String? = nil,
        birthday: Date? = nil,
        address: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.initials = initials
        self.email = email
        self.roleRaw = roleRaw
        self.canWrite = canWrite
        self.avatarColorSeed = avatarColorSeed
        self.photoData = photoData
        self.joinedAt = joinedAt
        self.createdAt = Date()
        self.phone = phone
        self.birthday = birthday
        self.address = address
        self.notes = notes
    }

    public var role: FamilyMemberRole {
        get { FamilyMemberRole(rawValue: roleRaw) ?? .other }
        set { roleRaw = newValue.rawValue }
    }
}
