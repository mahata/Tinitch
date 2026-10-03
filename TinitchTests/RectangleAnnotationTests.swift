import CoreGraphics
import Testing
@testable import Tinitch

struct RectangleAnnotationTests {
    @Test
    func normalizesRectFromDragPoints() {
        let rect = RectangleAnnotation.normalizedRect(
            from: CGPoint(x: 50, y: 20),
            to: CGPoint(x: 150, y: 70),
            in: CGSize(width: 200, height: 100)
        )

        #expect(rect == CGRect(x: 0.25, y: 0.2, width: 0.5, height: 0.5))
    }

    @Test
    func normalizesRectFromReversedDrag() {
        let forward = RectangleAnnotation.normalizedRect(
            from: CGPoint(x: 50, y: 20),
            to: CGPoint(x: 150, y: 70),
            in: CGSize(width: 200, height: 100)
        )
        let reversed = RectangleAnnotation.normalizedRect(
            from: CGPoint(x: 150, y: 70),
            to: CGPoint(x: 50, y: 20),
            in: CGSize(width: 200, height: 100)
        )

        #expect(forward == reversed)
    }

    @Test
    func clampsRectOutsideImageBounds() {
        let rect = RectangleAnnotation.normalizedRect(
            from: CGPoint(x: -50, y: -20),
            to: CGPoint(x: 400, y: 300),
            in: CGSize(width: 200, height: 100)
        )

        #expect(rect == CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    @Test
    func normalizesToZeroForEmptySize() {
        let rect = RectangleAnnotation.normalizedRect(
            from: CGPoint(x: 50, y: 20),
            to: CGPoint(x: 150, y: 70),
            in: .zero
        )

        #expect(rect == .zero)
    }

    @Test
    func clampsRectPassedToInitializer() {
        let annotation = RectangleAnnotation(
            normalizedRect: CGRect(x: -0.5, y: 0.5, width: 2, height: 2)
        )

        #expect(annotation.normalizedRect == CGRect(x: 0, y: 0.5, width: 1, height: 0.5))
    }

    @Test
    func convertsNormalizedRectBackToPixels() {
        let annotation = RectangleAnnotation(
            normalizedRect: CGRect(x: 0.25, y: 0.2, width: 0.5, height: 0.5)
        )

        #expect(
            annotation.rect(in: CGSize(width: 200, height: 100))
                == CGRect(x: 50, y: 20, width: 100, height: 50)
        )
    }

    @Test
    func treatsTinyRectanglesAsInvisible() {
        let tiny = RectangleAnnotation(
            normalizedRect: CGRect(x: 0.5, y: 0.5, width: 0.001, height: 0.5)
        )
        let large = RectangleAnnotation(
            normalizedRect: CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.2)
        )

        #expect(!tiny.isVisible)
        #expect(large.isVisible)
    }

    @Test
    func hitTestsNormalizedPoints() {
        let annotation = RectangleAnnotation(
            normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        )

        #expect(annotation.contains(normalizedPoint: CGPoint(x: 0.5, y: 0.5)))
        #expect(!annotation.contains(normalizedPoint: CGPoint(x: 0.1, y: 0.5)))
    }

    @Test
    func scalesStrokeWidthWithShorterSide() {
        let large = RectangleAnnotation.strokeWidth(for: CGSize(width: 2000, height: 1000))
        let small = RectangleAnnotation.strokeWidth(for: CGSize(width: 10, height: 10))

        #expect(large == 5)
        #expect(small == RectangleAnnotation.minimumStrokeWidth)
    }

    @Test
    func scalesDisplayedStrokeWidthFromSourcePixels() {
        let enlarged = RectangleAnnotation.displayedStrokeWidth(
            sourceSize: CGSize(width: 100, height: 100),
            displayedSize: CGSize(width: 400, height: 400)
        )
        let reduced = RectangleAnnotation.displayedStrokeWidth(
            sourceSize: CGSize(width: 2000, height: 1000),
            displayedSize: CGSize(width: 1000, height: 500)
        )

        #expect(enlarged == 8)
        #expect(reduced == 2.5)
    }

    @Test
    func scalesCornerRadiusWithShorterSide() {
        let annotation = RectangleAnnotation(
            normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        )

        #expect(annotation.cornerRadius(in: CGSize(width: 2000, height: 1000)) == 15)
    }

    @Test
    func limitsCornerRadiusToHalfTheShorterEdge() {
        let annotation = RectangleAnnotation(
            normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.02)
        )

        #expect(annotation.cornerRadius(in: CGSize(width: 1000, height: 1000)) == 10)
    }
}
