import CoreGraphics
import Testing
@testable import Tinitch

struct MosaicRegionTests {
    @Test
    func normalizesRectFromDragPoints() {
        let rect = MosaicRegion.normalizedRect(
            from: CGPoint(x: 50, y: 20),
            to: CGPoint(x: 150, y: 70),
            in: CGSize(width: 200, height: 100)
        )

        #expect(rect == CGRect(x: 0.25, y: 0.2, width: 0.5, height: 0.5))
    }

    @Test
    func normalizesRectFromReversedDrag() {
        let forward = MosaicRegion.normalizedRect(
            from: CGPoint(x: 50, y: 20),
            to: CGPoint(x: 150, y: 70),
            in: CGSize(width: 200, height: 100)
        )
        let reversed = MosaicRegion.normalizedRect(
            from: CGPoint(x: 150, y: 70),
            to: CGPoint(x: 50, y: 20),
            in: CGSize(width: 200, height: 100)
        )

        #expect(forward == reversed)
    }

    @Test
    func clampsRectOutsideImageBounds() {
        let rect = MosaicRegion.normalizedRect(
            from: CGPoint(x: -50, y: -20),
            to: CGPoint(x: 400, y: 300),
            in: CGSize(width: 200, height: 100)
        )

        #expect(rect == CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    @Test
    func normalizesToZeroForEmptySize() {
        let rect = MosaicRegion.normalizedRect(
            from: CGPoint(x: 50, y: 20),
            to: CGPoint(x: 150, y: 70),
            in: .zero
        )

        #expect(rect == .zero)
    }

    @Test
    func clampsRectPassedToInitializer() {
        let region = MosaicRegion(
            normalizedRect: CGRect(x: -0.5, y: 0.5, width: 2, height: 2)
        )

        #expect(region.normalizedRect == CGRect(x: 0, y: 0.5, width: 1, height: 0.5))
    }

    @Test
    func convertsNormalizedRectBackToPixels() {
        let region = MosaicRegion(
            normalizedRect: CGRect(x: 0.25, y: 0.2, width: 0.5, height: 0.5)
        )

        #expect(
            region.rect(in: CGSize(width: 200, height: 100))
                == CGRect(x: 50, y: 20, width: 100, height: 50)
        )
    }

    @Test
    func treatsTinyRegionsAsInvisible() {
        let tiny = MosaicRegion(
            normalizedRect: CGRect(x: 0.5, y: 0.5, width: 0.001, height: 0.5)
        )
        let large = MosaicRegion(
            normalizedRect: CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.2)
        )

        #expect(!tiny.isVisible)
        #expect(large.isVisible)
    }

    @Test
    func hitTestsNormalizedPoints() {
        let region = MosaicRegion(
            normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        )

        #expect(region.contains(normalizedPoint: CGPoint(x: 0.5, y: 0.5)))
        #expect(!region.contains(normalizedPoint: CGPoint(x: 0.1, y: 0.5)))
    }

    @Test
    func scalesBlockSizeWithShorterSide() {
        let large = MosaicRegion.blockSize(for: CGSize(width: 2000, height: 1000))
        let small = MosaicRegion.blockSize(for: CGSize(width: 10, height: 10))

        #expect(large == 20)
        #expect(small == MosaicRegion.minimumBlockSize)
    }
}
