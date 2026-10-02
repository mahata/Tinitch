import CoreGraphics
import Testing
@testable import Tinitch

struct TextAnnotationTests {
    @Test
    func normalizesPointWithinImageSize() {
        let position = TextAnnotation.normalizedPosition(
            for: CGPoint(x: 50, y: 20),
            in: CGSize(width: 200, height: 100)
        )

        #expect(position == CGPoint(x: 0.25, y: 0.2))
    }

    @Test
    func clampsPointOutsideImageSize() {
        let position = TextAnnotation.normalizedPosition(
            for: CGPoint(x: -10, y: 300),
            in: CGSize(width: 200, height: 100)
        )

        #expect(position == CGPoint(x: 0, y: 1))
    }

    @Test
    func normalizesToZeroForEmptySize() {
        let position = TextAnnotation.normalizedPosition(
            for: CGPoint(x: 50, y: 20),
            in: .zero
        )

        #expect(position == .zero)
    }

    @Test
    func convertsNormalizedPositionBackToPoint() {
        let annotation = TextAnnotation(
            text: "Hi",
            normalizedPosition: CGPoint(x: 0.25, y: 0.2)
        )

        #expect(annotation.point(in: CGSize(width: 200, height: 100)) == CGPoint(x: 50, y: 20))
    }

    @Test
    func scalesFontSizeWithImageHeight() {
        let small = TextAnnotation.fontSize(forHeight: 100)
        let large = TextAnnotation.fontSize(forHeight: 400)

        #expect(large == small * 4)
        #expect(TextAnnotation.fontSize(forHeight: 0) == 1)
    }
}
