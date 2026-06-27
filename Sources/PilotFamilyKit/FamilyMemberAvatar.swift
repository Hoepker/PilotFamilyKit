import SwiftUI

/// Mitglieder-Avatar: Foto, sonst farbiger Kreis mit Initialen (deterministische
/// Farbe aus einem Seed) bzw. Fallback-Icon (Haustier-Pfote).
public struct FamilyMemberAvatar: View {
    let initials: String
    let photoData: Data?
    let seed: String
    let fallbackIcon: String?
    var size: CGFloat

    public init(initials: String, photoData: Data?, seed: String,
                fallbackIcon: String? = nil, size: CGFloat = 44) {
        self.initials = initials
        self.photoData = photoData
        self.seed = seed
        self.fallbackIcon = fallbackIcon
        self.size = size
    }

    public var body: some View {
        Group {
            if let data = photoData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.pfLine, lineWidth: 0.5))
            } else {
                Circle().fill(color.opacity(0.16))
                    .overlay(content)
                    .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var content: some View {
        if let fallbackIcon {
            Image(systemName: fallbackIcon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(color)
        } else {
            Text(initials.isEmpty ? "•" : initials.uppercased())
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private var color: Color {
        let palette: [Color] = [
            Color(red: 0.23, green: 0.51, blue: 0.96),
            Color(red: 0.25, green: 0.64, blue: 0.48),
            Color(red: 0.95, green: 0.61, blue: 0.18),
            Color(red: 0.49, green: 0.23, blue: 0.93),
            Color(red: 0.05, green: 0.65, blue: 0.91),
            Color(red: 0.95, green: 0.45, blue: 0.45),
        ]
        let sum = seed.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[sum % palette.count]
    }
}
