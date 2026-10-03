import CoreGraphics
import Foundation

enum NormalizedRect {
    static func make(from start: CGPoint, to end: CGPoint, in size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0 else {
            return .zero
        }

        let rect = CGRect(
            x: min(start.x, end.x) / size.width,
            y: min(start.y, end.y) / size.height,
            width: abs(end.x - start.x) / size.width,
            height: abs(end.y - start.y) / size.height
        )

        return clamped(rect)
    }

    static func clamped(_ rect: CGRect) -> CGRect {
        let standardized = rect.standardized
        let unitRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        guard !unitRect.contains(standardized) else {
            return standardized
        }

        let intersection = standardized.intersection(unitRect)
        return intersection.isNull ? .zero : intersection
    }

    static func rect(for normalizedRect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: normalizedRect.minX * size.width,
            y: normalizedRect.minY * size.height,
            width: normalizedRect.width * size.width,
            height: normalizedRect.height * size.height
        )
    }
}
