import SwiftUI

enum FontWeight {
    case light
    case regular
    case medium
    case semiBold   // preferred
    case semibold   // alias for semiBold
    case bold
    case black
}

extension Font {
    static let customFont: (String, FontWeight, CGFloat) -> Font = { fontFamily, fontType, size in
        let fontName: String
        switch fontType {
        case .light:
            fontName = "\(fontFamily)-Light"
        case .regular:
            fontName = "\(fontFamily)-Regular"
        case .medium:
            fontName = "\(fontFamily)-Medium"
        case .semiBold, .semibold:   // both map to the same suffix
            fontName = "\(fontFamily)-SemiBold"
        case .bold:
            fontName = "\(fontFamily)-Bold"
        case .black:
            fontName = "\(fontFamily)-Black"
        }
        return .custom(fontName, size: size)
    }
}

extension Text {
    func customFont(
        _ fontFamily: String = "Roboto",
        _ fontWeight: FontWeight? = .regular,
        _ size: CGFloat? = nil
    ) -> Text {
        self.font(.customFont(fontFamily, fontWeight ?? .regular, size ?? 16))
    }
}
