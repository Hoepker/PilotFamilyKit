# PilotFamilyKit

Geteilte Familien-Verwaltung der MyPilot-Suite — ein gemeinsames Swift-Package für
MyFamilyPilot und MyOfficePilot (und künftige Apps).

Enthält:
- `SuiteFamilyMember` — das geteilte SwiftData-Modell (CloudKit-Typ `CD_SuiteFamilyMember`)
- `FamilyMemberRole` — Rollen + Schreibrechte-Semantik
- `FamilyStore` — CRUD + Deduplizierung
- `FamilyMembersScreen` / `FamilyMemberEditView` / `FamilyMemberAvatar` — die zentralen Screens

Eigenständige Tokens (über eine Akzentfarbe themebar), keine Abhängigkeit zu app-lokalen
Design-Systemen.
