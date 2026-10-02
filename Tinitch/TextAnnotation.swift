import CoreGraphics
import Foundation

struct TextAnnotation: Identifiable, Equatable {
    static let fontHeightRatio: CGFloat = 0.06

    let id: UUID
    var text: String
    var normalizedPosition: CGPoint

    var hasVisibleText: Bool {
        text.contains { !$0.isWhitespace }
    }

    init(id: UUID = UUID(), text: String = "", normalizedPosition: CGPoint) {
        self.id = id
        self.text = text
        self.normalizedPosition = Self.clamped(normalizedPosition)
    }

    static func normalizedPosition(for point: CGPoint, in size: CGSize) -> CGPoint {
        guard size.width > 0, size.height > 0 else {
            return .zero
        }

        return clamped(CGPoint(x: point.x / size.width, y: point.y / size.height))
    }

    static func fontSize(forHeight height: CGFloat) -> CGFloat {
        max(height * fontHeightRatio, 1)
    }

    func point(in size: CGSize) -> CGPoint {
        CGPoint(
            x: normalizedPosition.x * size.width,
            y: normalizedPosition.y * size.height
        )
    }

    private static func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), 1),
            y: min(max(point.y, 0), 1)
        )
    }
}
