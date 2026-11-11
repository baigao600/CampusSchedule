import SwiftUI

extension Course {
    var tint: Color {
        switch color {
        case "blue": .blue
        case "cyan": .cyan
        case "teal": .teal
        case "mint": .mint
        case "green": .green
        case "orange": .orange
        case "pink": .pink
        case "purple": .purple
        case "red": .red
        default: .indigo
        }
    }
}

enum CourseBoardStyle {
    static let cardRadius: CGFloat = 18
    static let pagePadding: CGFloat = 16
}
