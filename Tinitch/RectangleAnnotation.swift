import CoreGraphics
import Foundation

struct RectangleAnnotation: Identifiable, Equatable {
    static let strokeWidthRatio: CGFloat = 0.005
    static let minimumStrokeWidth: CGFloat = 2
    static let cornerRadiusRatio: CGFloat = 0.015
    static let minimumNormalizedSize: CGFloat = 0.01
    static let strokeColorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat) =
        (1, 0.17, 0.13)

    let id: UUID
    var normalizedRect: CGRect

    var isVisible: Bool {
        normalizedRect.width >= Self.minimumNormalizedSize
            && normalizedRect.height >= Self.minimumNormalizedSize
    }

    init(id: UUID = UUID(), normalizedRect: CGRect) {
        self.id = id
        self.normalizedRect = NormalizedRect.clamped(normalizedRect)
    }

    static func normalizedRect(from start: CGPoint, to end: CGPoint, in size: CGSize) -> CGRect {
        NormalizedRect.make(from: start, to: end, in: size)
    }

    static func strokeWidth(for size: CGSize) -> CGFloat {
        let shorterSide = min(size.width, size.height)
        return max(shorterSide * strokeWidthRatio, minimumStrokeWidth)
    }

    func rect(in size: CGSize) -> CGRect {
        NormalizedRect.rect(for: normalizedRect, in: size)
    }

    func cornerRadius(in size: CGSize) -> CGFloat {
        let shorterSide = min(size.width, size.height)
        let pixelRect = rect(in: size)
        let shorterEdge = min(pixelRect.width, pixelRect.height)
        return min(shorterSide * Self.cornerRadiusRatio, shorterEdge / 2)
    }

    func contains(normalizedPoint point: CGPoint) -> Bool {
        normalizedRect.contains(point)
    }
}
