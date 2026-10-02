enum Tool: String, CaseIterable, Identifiable {
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text:
            "Text"
        }
    }

    var systemImageName: String {
        switch self {
        case .text:
            "textformat"
        }
    }

    var hint: String {
        switch self {
        case .text:
            "Click the image to add letters."
        }
    }
}
