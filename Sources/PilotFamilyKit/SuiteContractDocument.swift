import Foundation
import SwiftData

/// Ein Dokument eines Vertrags, app-übergreifend im GETEILTEN Container
/// (`iCloud.de.hoepker.pilotsuite`). TRANSPORT für die echten Datei-Bytes zwischen
/// MyFamilyPilot und MyOfficePilot, damit ein PDF in BEIDEN Apps sichtbar/öffenbar ist.
///
/// Richtung:
/// - `source == .mfp`: aus MyFamilyPilot gespiegelt (MFP legt die Bytes hier ab, da MFP
///   sie sonst nur in seinem externen StorageProvider hält). `mfpDocumentID` gesetzt.
/// - `source == .mop`: in MyOfficePilot angehängt (nur Inhaber/`canWrite`). MFP zieht es
///   ein → erzeugt ein `Document` am `Entry` und setzt dann `mfpDocumentID` (= ingested).
///
/// CloudKit: Klassenname stabil (`CD_SuiteContractDocument`), alle Felder Default/optional,
/// Bytes via `@Attribute(.externalStorage)` (→ CKAsset). Kein `.unique`.
@Model
public final class SuiteContractDocument {
    public var id: UUID = UUID()
    /// Zugehöriger Vertrag (= MyFamilyPilot `Entry.id` / MyOfficePilot `SuiteContract.id`).
    public var contractID: UUID = UUID()
    public var displayName: String = ""
    public var fileName: String = ""
    public var mimeType: String = "application/pdf"
    public var sizeBytes: Int = 0
    /// Die eigentlichen Datei-Bytes (Transport-Nutzlast). Extern gespeichert → CKAsset.
    @Attribute(.externalStorage) public var fileData: Data?
    /// SHA-256 (Hex) der Bytes — Dedup + „einmal einlesen".
    public var contentHash: String = ""
    /// Gesetzt, sobald das Dokument in MyFamilyPilot als `Document` existiert (gespiegelt
    /// ODER nach Ingest eines MOP-Uploads). `nil` = MOP-Upload, von MFP noch nicht eingelesen.
    public var mfpDocumentID: UUID?
    /// Ursprung ("mfp" | "mop").
    public var sourceRaw: String = SuiteContractDocumentSource.mfp.rawValue
    /// Wer hat es angehängt (für Anzeige/Audit).
    public var addedByMemberID: UUID?
    public var addedAt: Date = Date()
    public var updatedAt: Date = Date()

    public init(id: UUID = UUID(), contractID: UUID = UUID(), displayName: String = "",
                fileName: String = "", mimeType: String = "application/pdf", sizeBytes: Int = 0,
                fileData: Data? = nil, contentHash: String = "", mfpDocumentID: UUID? = nil,
                source: SuiteContractDocumentSource = .mfp, addedByMemberID: UUID? = nil,
                addedAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.contractID = contractID
        self.displayName = displayName
        self.fileName = fileName
        self.mimeType = mimeType
        self.sizeBytes = sizeBytes
        self.fileData = fileData
        self.contentHash = contentHash
        self.mfpDocumentID = mfpDocumentID
        self.sourceRaw = source.rawValue
        self.addedByMemberID = addedByMemberID
        self.addedAt = addedAt
        self.updatedAt = updatedAt
    }

    public var source: SuiteContractDocumentSource {
        get { SuiteContractDocumentSource(rawValue: sourceRaw) ?? .mfp }
        set { sourceRaw = newValue.rawValue }
    }
}

public enum SuiteContractDocumentSource: String, Codable {
    case mfp   // aus MyFamilyPilot gespiegelt
    case mop   // in MyOfficePilot angehängt
}
