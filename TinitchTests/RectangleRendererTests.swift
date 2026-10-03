import AppKit
import CoreGraphics
import Testing
@testable import Tinitch

struct RectangleRendererTests {
    private let renderer = RectangleRenderer()

    @Test
    func keepsSourceDimensions() throws {
        let source = try blackImage(width: 400, height: 240)

        let rendered = try renderer.render(
            sourceImage: source,
            rectangles: [
                RectangleAnnotation(
                    normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
                )
            ]
        )

        #expect(rendered.width == 400)
        #expect(rendered.height == 240)
    }

    @Test
    func strokesTheRectangleEdges() throws {
        let source = try blackImage(width: 400, height: 400)

        let rendered = try renderer.render(
            sourceImage: source,
            rectangles: [
                RectangleAnnotation(
                    normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
                )
            ]
        )

        let samples = try pixels(in: rendered)
        #expect(isRed(samples, x: 100, y: 200, width: 400))
        #expect(isRed(samples, x: 300, y: 200, width: 400))
        #expect(isRed(samples, x: 200, y: 100, width: 400))
        #expect(isRed(samples, x: 200, y: 300, width: 400))
    }

    @Test
    func leavesTheInteriorUntouched() throws {
        let source = try blackImage(width: 400, height: 400)

        let rendered = try renderer.render(
            sourceImage: source,
            rectangles: [
                RectangleAnnotation(
                    normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
                )
            ]
        )

        let samples = try pixels(in: rendered)
        #expect(isBlack(samples, x: 200, y: 200, width: 400))
        #expect(isBlack(samples, x: 20, y: 20, width: 400))
    }

    @Test
    func roundsTheCorners() throws {
        let source = try blackImage(width: 400, height: 400)

        let rendered = try renderer.render(
            sourceImage: source,
            rectangles: [
                RectangleAnnotation(
                    normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
                )
            ]
        )

        let samples = try pixels(in: rendered)
        #expect(isBlack(samples, x: 100, y: 100, width: 400))
        #expect(isBlack(samples, x: 299, y: 299, width: 400))
    }

    @Test
    func usesTopLeftOriginForNormalizedCoordinates() throws {
        let source = try blackImage(width: 400, height: 400)

        let rendered = try renderer.render(
            sourceImage: source,
            rectangles: [
                RectangleAnnotation(
                    normalizedRect: CGRect(x: 0.25, y: 0.1, width: 0.5, height: 0.3)
                )
            ]
        )

        let samples = try pixels(in: rendered)
        #expect(isRed(samples, x: 200, y: 40, width: 400))
        #expect(isRed(samples, x: 200, y: 160, width: 400))
        #expect(isBlack(samples, x: 200, y: 300, width: 400))
    }

    @Test
    func keepsEdgeHuggingStrokesInsideTheImage() throws {
        let source = try blackImage(width: 400, height: 400)

        let rendered = try renderer.render(
            sourceImage: source,
            rectangles: [RectangleAnnotation(normalizedRect: CGRect(x: 0, y: 0, width: 1, height: 1))]
        )

        let samples = try pixels(in: rendered)
        #expect(isRed(samples, x: 0, y: 200, width: 400))
        #expect(isRed(samples, x: 399, y: 200, width: 400))
        #expect(isRed(samples, x: 200, y: 0, width: 400))
        #expect(isRed(samples, x: 200, y: 399, width: 400))
    }

    @Test
    func leavesImageUntouchedWithoutRectangles() throws {
        let source = try blackImage(width: 80, height: 80)

        let rendered = try renderer.render(sourceImage: source, rectangles: [])

        #expect(try pixels(in: rendered) == pixels(in: source))
    }

    @Test
    func ignoresRectanglesBelowTheVisibleSize() throws {
        let source = try blackImage(width: 400, height: 400)

        let rendered = try renderer.render(
            sourceImage: source,
            rectangles: [
                RectangleAnnotation(
                    normalizedRect: CGRect(x: 0.5, y: 0.5, width: 0.001, height: 0.5)
                )
            ]
        )

        #expect(try pixels(in: rendered) == pixels(in: source))
    }

    @Test
    func rendersFromAppKitImage() throws {
        let source = try blackImage(width: 400, height: 400)
        let image = NSImage(cgImage: source, size: CGSize(width: 400, height: 400))

        let rendered = try renderer.render(
            image: image,
            rectangles: [
                RectangleAnnotation(
                    normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
                )
            ]
        )

        #expect(isRed(try pixels(in: rendered), x: 100, y: 200, width: 400))
    }

    private func isRed(_ samples: [UInt8], x: Int, y: Int, width: Int) -> Bool {
        let offset = (y * width + x) * 4
        return samples[offset] > 200 && samples[offset + 1] < 60 && samples[offset + 2] < 60
    }

    private func isBlack(_ samples: [UInt8], x: Int, y: Int, width: Int) -> Bool {
        let offset = (y * width + x) * 4
        return samples[offset] == 0 && samples[offset + 1] == 0 && samples[offset + 2] == 0
    }

    private func blackImage(width: Int, height: Int) throws -> CGImage {
        let context = try #require(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        return try #require(context.makeImage())
    }

    private func pixels(in image: CGImage) throws -> [UInt8] {
        let width = image.width
        let height = image.height
        let context = try #require(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let data = try #require(context.data).bindMemory(
            to: UInt8.self,
            capacity: width * height * 4
        )
        return Array(UnsafeBufferPointer(start: data, count: width * height * 4))
    }
}
