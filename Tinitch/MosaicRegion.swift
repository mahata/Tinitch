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
        self.normalizedRect = NormalizedRect.clamped(normalizedRect)
    }

    static func normalizedRect(from start: CGPoint, to end: CGPoint, in size: CGSize) -> CGRect {
        NormalizedRect.make(from: start, to: end, in: size)
    }

    static func blockSize(for size: CGSize) -> CGFloat {
        let shorterSide = min(size.width, size.height)
        return max(shorterSide * blockSizeRatio, minimumBlockSize)
    }

    func rect(in size: CGSize) -> CGRect {
        NormalizedRect.rect(for: normalizedRect, in: size)
    }

    func contains(normalizedPoint point: CGPoint) -> Bool {
        normalizedRect.contains(point)
    }
}
