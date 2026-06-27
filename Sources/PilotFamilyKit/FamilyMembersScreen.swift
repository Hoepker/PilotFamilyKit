import SwiftUI
import SwiftData

/// Zentrale Familien-Verwaltung — gemeinsamer Screen für alle Pilot-Apps. Zeigt das
/// deduplizierte Roster, erlaubt Anlegen/Bearbeiten/Löschen und die Auswahl der
/// eigenen Identität. Einladen/Annehmen werden über Closures von der jeweiligen App
/// beigesteuert (app-spezifische CloudKit-Sheets).
///
/// Erwartet den geteilten Suite-Container im Environment (`.modelContainer(...)`).
public struct FamilyMembersScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\SuiteFamilyMember.joinedAt)])
    private var rawMembers: [SuiteFamilyMember]

    private let theme: FamilyTheme
    @Binding private var currentMemberID: String
    private let onInvite: (() -> Void)?
    private let onAccept: (() -> Void)?

    @State private var creating = false

    public init(theme: FamilyTheme,
                currentMemberID: Binding<String>,
                onInvite: (() -> Void)? = nil,
                onAccept: (() -> Void)? = nil) {
        self.theme = theme
        self._currentMemberID = currentMemberID
        self.onInvite = onInvite
        self.onAccept = onAccept
    }

    private var store: FamilyStore { FamilyStore(context: modelContext) }
    private var members: [SuiteFamilyMember] { FamilyStore.canonical(rawMembers) }

    public var body: some View {
        Group {
            if members.isEmpty {
                ContentUnavailableView {
                    Label("Keine Familie", systemImage: "person.2")
                } description: {
                    Text("Lege ein Familienmitglied an oder nimm eine Einladung an.")
                } actions: {
                    Button("Mitglied anlegen") { creating = true }
                    if let onAccept { Button("Einladung annehmen") { onAccept() } }
                }
            } else {
                List {
                    identitySection
                    membersSection
                    inviteSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Familie")
        .tint(theme.accent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { creating = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $creating) {
            NavigationStack {
                FamilyMemberEditView(editing: nil, store: store, theme: theme)
            }
        }
    }

    private var identitySection: some View {
        Section {
            Picker(selection: $currentMemberID) {
                Text("Nicht zugeordnet").tag("")
                ForEach(members) { m in
                    Text(m.displayName.isEmpty ? "Unbenannt" : m.displayName).tag(m.id.uuidString)
                }
            } label: {
                Label("Das bin ich", systemImage: "person.fill.checkmark")
            }
            .pickerStyle(.menu)
        } footer: {
            Text("Wähle, welches Familienmitglied Du auf diesem Gerät bist — so siehst Du genau die für Dich freigegebenen Inhalte.")
        }
    }

    private var membersSection: some View {
        Section {
            ForEach(members) { member in
                NavigationLink {
                    FamilyMemberEditView(editing: member, store: store, theme: theme)
                } label: {
                    MemberRow(member: member,
                              isCurrentUser: member.id.uuidString == currentMemberID,
                              accent: theme.accent)
                }
            }
            .onDelete(perform: delete)
        } header: {
            Text("Mitglieder")
        } footer: {
            Text("Tippe ein Mitglied an, um es zu bearbeiten. Die Familie gilt in allen Pilot-Apps.")
        }
    }

    @ViewBuilder
    private var inviteSection: some View {
        if onInvite != nil || onAccept != nil {
            Section {
                if let onInvite {
                    Button { onInvite() } label: {
                        Label("Mitglied einladen", systemImage: "person.crop.circle.badge.plus")
                    }
                }
                if let onAccept {
                    Button { onAccept() } label: {
                        Label("Einladung annehmen", systemImage: "envelope.open")
                    }
                }
            } footer: {
                Text("Lade Mitglieder per iCloud ein oder nimm eine Einladung an — eine Familie für die ganze Suite.")
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { store.delete(members[index]) }
    }
}

// MARK: - Zeile

private struct MemberRow: View {
    let member: SuiteFamilyMember
    var isCurrentUser: Bool
    var accent: Color

    var body: some View {
        HStack(spacing: PFSpacing.s) {
            FamilyMemberAvatar(initials: member.initials, photoData: member.photoData,
                               seed: member.avatarColorSeed.isEmpty ? member.id.uuidString : member.id.uuidString,
                               fallbackIcon: member.role.fallbackIcon, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: PFSpacing.xs) {
                    Text(member.displayName.isEmpty ? "Unbenannt" : member.displayName)
                        .font(.body.weight(.semibold)).foregroundStyle(Color.pfInkPrimary)
                    if isCurrentUser {
                        Text("Du").font(.caption2.weight(.semibold)).foregroundStyle(accent)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(accent.opacity(0.14), in: Capsule())
                    }
                }
                HStack(spacing: 6) {
                    Text(member.role.localizedName).font(.footnote).foregroundStyle(Color.pfInkTertiary)
                    if let phone = member.phone, !phone.isEmpty {
                        Text("·").font(.footnote).foregroundStyle(Color.pfInkTertiary)
                        Text(phone).font(.footnote).foregroundStyle(Color.pfInkTertiary).lineLimit(1)
                    }
                }
            }
            Spacer()
            if !member.canWrite {
                Label("Nur Lesen", systemImage: "eye")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.pfInkTertiary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.pfLine.opacity(0.4), in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
