import CoreGraphics
import Testing
@testable import Tinitch

struct ImageFitTests {
    @Test
    func centersWideImageVerticallyInSquareContainer() {
        let rect = ImageFit.rect(
            for: CGSize(width: 200, height: 100),
            in: CGSize(width: 100, height: 100)
        )

        #expect(rect == CGRect(x: 0, y: 25, width: 100, height: 50))
    }

    @Test
    func centersTallImageHorizontallyInSquareContainer() {
        let rect = ImageFit.rect(
            for: CGSize(width: 100, height: 200),
            in: CGSize(width: 100, height: 100)
        )

        #expect(rect == CGRect(x: 25, y: 0, width: 50, height: 100))
    }

    @Test
    func fillsContainerForMatchingAspectRatio() {
        let rect = ImageFit.rect(
            for: CGSize(width: 400, height: 200),
            in: CGSize(width: 200, height: 100)
        )

        #expect(rect == CGRect(x: 0, y: 0, width: 200, height: 100))
    }

    @Test
    func returnsZeroRectForEmptySizes() {
        #expect(ImageFit.rect(for: .zero, in: CGSize(width: 100, height: 100)) == .zero)
        #expect(ImageFit.rect(for: CGSize(width: 100, height: 100), in: .zero) == .zero)
    }
}
