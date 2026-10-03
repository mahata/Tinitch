import CoreGraphics
import Foundation

struct MosaicRegion: Identifiable, Equatable {
    static let blockSizeRatio: CGFloat = 0.02
    static let minimumBlockSize: CGFloat = 4
    static let minimumNormalizedSize: CGFloat = 0.01

    let id: UUID
    var normalizedRect: CGRect

    var isVisible: Bool {
        normalizedRect.width >= Self.minimumNormalizedSize
            && normalizedRect.height >= Self.minimumNormalizedSize
    }

    init(id: UUID = UUID(), normalizedRect: CGRect) {
        self.id = id
        self.normalizedRect = Self.clamped(normalizedRect)
    }

    static func normalizedRect(from start: CGPoint, to end: CGPoint, in size: CGSize) -> CGRect {
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

    static func blockSize(for size: CGSize) -> CGFloat {
        let shorterSide = min(size.width, size.height)
        return max(shorterSide * blockSizeRatio, minimumBlockSize)
    }

    func rect(in size: CGSize) -> CGRect {
        CGRect(
            x: normalizedRect.minX * size.width,
            y: normalizedRect.minY * size.height,
            width: normalizedRect.width * size.width,
            height: normalizedRect.height * size.height
        )
    }

    func contains(normalizedPoint point: CGPoint) -> Bool {
        normalizedRect.contains(point)
    }

    private static func clamped(_ rect: CGRect) -> CGRect {
        let standardized = rect.standardized
        let unitRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        guard !unitRect.contains(standardized) else {
            return standardized
        }

        let intersection = standardized.intersection(unitRect)
        return intersection.isNull ? .zero : intersection
    }
}
