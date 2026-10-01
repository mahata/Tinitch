import AppKit
import CoreGraphics
import Testing
@testable import Tinitch

@MainActor
struct AnnotationRendererTests {
    private let renderer = AnnotationRenderer()

    @Test
    func keepsSourceDimensions() throws {
        let source = try whiteImage(width: 120, height: 80)

        let rendered = try renderer.render(
            sourceImage: source,
            annotations: [
                TextAnnotation(text: "Hi", normalizedPosition: CGPoint(x: 0.5, y: 0.5))
            ]
        )

        #expect(rendered.width == 120)
        #expect(rendered.height == 80)
    }

    @Test
    func drawsAnnotationTextOntoImage() throws {
        let source = try whiteImage(width: 120, height: 80)

        let rendered = try renderer.render(
            sourceImage: source,
            annotations: [
                TextAnnotation(text: "Hi", normalizedPosition: CGPoint(x: 0.5, y: 0.5))
            ]
        )

        #expect(try nonWhitePixelCount(in: rendered) > 0)
    }

    @Test
    func leavesImageUntouchedWithoutAnnotations() throws {
        let source = try whiteImage(width: 120, height: 80)

        let rendered = try renderer.render(sourceImage: source, annotations: [])

        #expect(try nonWhitePixelCount(in: rendered) == 0)
    }

    @Test
    func ignoresEmptyAnnotations() throws {
        let source = try whiteImage(width: 120, height: 80)

        let rendered = try renderer.render(
            sourceImage: source,
            annotations: [
                TextAnnotation(text: "", normalizedPosition: CGPoint(x: 0.5, y: 0.5))
            ]
        )

        #expect(try nonWhitePixelCount(in: rendered) == 0)
    }

    @Test
    func rendersFromAppKitImage() throws {
        let source = try whiteImage(width: 120, height: 80)
        let image = NSImage(cgImage: source, size: CGSize(width: 120, height: 80))

        let rendered = try renderer.render(
            image: image,
            annotations: [
                TextAnnotation(text: "Hi", normalizedPosition: CGPoint(x: 0.5, y: 0.5))
            ]
        )

        #expect(rendered.width == 120)
        #expect(try nonWhitePixelCount(in: rendered) > 0)
    }

    private func whiteImage(width: Int, height: Int) throws -> CGImage {
        let context = try #require(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return try #require(context.makeImage())
    }

    private func nonWhitePixelCount(in image: CGImage) throws -> Int {
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

        let pixels = try #require(context.data).bindMemory(
            to: UInt8.self,
            capacity: width * height * 4
        )
        var count = 0
        for offset in stride(from: 0, to: width * height * 4, by: 4)
        where pixels[offset] != 255 || pixels[offset + 1] != 255 || pixels[offset + 2] != 255 {
            count += 1
        }

        return count
    }
}
