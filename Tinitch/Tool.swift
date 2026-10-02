enum Tool: String, CaseIterable, Identifiable {
    case text
    case mosaic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text:
            "Text"
        case .mosaic:
            "Mosaic"
        }
    }

    var systemImageName: String {
        switch self {
        case .text:
            "textformat"
        case .mosaic:
            "squareshape.split.3x3"
        }
    }

    var hint: String {
        switch self {
        case .text:
            "Click the image to add letters."
        case .mosaic:
            "Drag over the image to pixelate an area. Click a mosaic to remove it."
        }
    }
}
