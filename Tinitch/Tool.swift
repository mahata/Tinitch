enum Tool: String, CaseIterable, Identifiable {
    case text
    case mosaic
    case rectangle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text:
            "Text"
        case .mosaic:
            "Mosaic"
        case .rectangle:
            "Rectangle"
        }
    }

    var systemImageName: String {
        switch self {
        case .text:
            "textformat"
        case .mosaic:
            "squareshape.split.3x3"
        case .rectangle:
            "rectangle"
        }
    }

    var hint: String {
        switch self {
        case .text:
            "Click the image to add letters."
        case .mosaic:
            "Drag over the image to pixelate an area. Click a mosaic to remove it."
        case .rectangle:
            "Drag over the image to outline an area. Click a rectangle to remove it."
        }
    }
}
