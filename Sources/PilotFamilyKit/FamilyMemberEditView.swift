import SwiftUI
import SwiftData
import PhotosUI

/// Anlegen/Bearbeiten eines Familienmitglieds — zentral für alle Apps. Operiert auf
/// dem geteilten `SuiteFamilyMember` via `FamilyStore`. Struktur wie MyFamilyPilots
/// `FamilyMemberEditView` (Avatar · Person · Kontakt · Rolle/Berechtigung · Notizen).
public struct FamilyMemberEditView: View {
    @Environment(\.dismiss) private var dismiss

    private let editing: SuiteFamilyMember?
    private let store: FamilyStore
    private let theme: FamilyTheme

    public init(editing: SuiteFamilyMember?, store: FamilyStore, theme: FamilyTheme) {
        self.editing = editing
        self.store = store
        self.theme = theme
    }

    @State private var displayName = ""
    @State private var initials = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var hasBirthday = false
    @State private var birthday = Date()
    @State private var notes = ""
    @State private var role: FamilyMemberRole = .partner
    @State private var avatarColorSeed = "coral"
    @State private var photoData: Data?
    @State private var canWriteToggle = true
    @State private var photoPickerItem: PhotosPickerItem?

    public var body: some View {
        Form {
            avatarSection
            personSection
            kontaktSection
            roleSection
            notesSection
            if editing != nil {
                Section {
                    Button(role: .destructive) { performDelete() } label: {
                        Label("Mitglied löschen", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(editing == nil ? "Neues Mitglied" : displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Sichern") { save() }.disabled(!isValid)
            }
        }
        .tint(theme.accent)
        .onAppear(perform: hydrate)
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run { photoData = data }
                }
            }
        }
    }

    // MARK: - Sections

    private var avatarSection: some View {
        Section {
            HStack(spacing: PFSpacing.m) {
                FamilyMemberAvatar(initials: initials.isEmpty ? "?" : initials,
                                   photoData: photoData, seed: avatarColorSeed,
                                   fallbackIcon: role.fallbackIcon, size: 72)
                VStack(alignment: .leading, spacing: 4) {
                    PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                        Label(photoData == nil ? "Foto wählen" : "Foto ändern", systemImage: "photo")
                            .font(.subheadline.weight(.medium))
                    }
                    if photoData != nil {
                        Button(role: .destructive) { photoData = nil } label: {
                            Text("Foto entfernen").font(.footnote)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private var personSection: some View {
        Section("Person") {
            TextField("Anzeigename", text: $displayName)
                .onChange(of: displayName) { _, v in
                    if initials.isEmpty || initials.count <= 2 { initials = autoInitials(from: v) }
                }
            TextField("Initialen", text: $initials)
                .textInputAutocapitalization(.characters)
                .onChange(of: initials) { _, v in initials = String(v.uppercased().prefix(3)) }
            Toggle("Geburtstag", isOn: $hasBirthday)
            if hasBirthday {
                DatePicker("Datum", selection: $birthday, displayedComponents: .date)
            }
        }
    }

    private var kontaktSection: some View {
        Section("Kontakt") {
            TextField("E-Mail", text: $email)
                .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
            TextField("Telefon", text: $phone).keyboardType(.phonePad)
            TextField("Postanschrift", text: $address, axis: .vertical).lineLimit(2...4)
        }
    }

    @ViewBuilder
    private var roleSection: some View {
        Section {
            Picker("Rolle", selection: $role) {
                ForEach(FamilyMemberRole.allCases, id: \.self) { r in
                    Text(r.localizedName).tag(r)
                }
            }
            Picker("Avatar-Farbe", selection: $avatarColorSeed) {
                Text("Pilot (Grün/Blau)").tag("pilot")
                Text("Coral").tag("coral")
                Text("Neutral (Grau)").tag("neutral")
            }
        } header: {
            Text("Rolle & Darstellung")
        }
        if role.forcedCanWrite == .toggleable {
            Section {
                Toggle("Schreibrechte", isOn: $canWriteToggle)
            } header: {
                Text("Berechtigung")
            } footer: {
                Text("Ohne Schreibrechte nur Lesezugriff — keine Änderungen möglich.")
            }
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Notizen (Allergien, Hausarzt, …)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Notizen")
        }
    }

    // MARK: - Logik

    private var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !initials.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func hydrate() {
        guard let m = editing else { return }
        displayName = m.displayName
        initials = m.initials
        email = m.email ?? ""
        phone = m.phone ?? ""
        address = m.address ?? ""
        notes = m.notes ?? ""
        role = m.role
        avatarColorSeed = m.avatarColorSeed
        photoData = m.photoData
        canWriteToggle = m.canWrite
        if let bd = m.birthday { hasBirthday = true; birthday = bd }
    }

    private func autoInitials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let a = parts.first?.first.map(String.init) ?? ""
        let b = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (a + b).uppercased()
    }

    private func save() {
        let m = editing ?? SuiteFamilyMember()
        m.displayName = displayName.trimmingCharacters(in: .whitespaces)
        m.initials = initials.trimmingCharacters(in: .whitespaces)
        m.email = email.trimmingCharacters(in: .whitespaces).nilIfEmpty
        m.phone = phone.trimmingCharacters(in: .whitespaces).nilIfEmpty
        m.address = address.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        m.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        m.birthday = hasBirthday ? birthday : nil
        m.role = role
        m.avatarColorSeed = avatarColorSeed
        m.photoData = photoData
        m.canWrite = role.effectiveCanWrite(override: canWriteToggle)
        store.save(m)
        dismiss()
    }

    private func performDelete() {
        guard let m = editing else { return }
        store.delete(m)
        dismiss()
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
