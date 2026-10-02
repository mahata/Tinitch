import AppKit
import CoreGraphics
import Testing
@testable import Tinitch

struct MosaicRendererTests {
    private let renderer = MosaicRenderer()

    @Test
    func keepsSourceDimensions() throws {
        let source = try checkerboardImage(width: 200, height: 120)

        let rendered = try renderer.render(
            sourceImage: source,
            regions: [MosaicRegion(normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))]
        )

        #expect(rendered.width == 200)
        #expect(rendered.height == 120)
    }

    @Test
    func flattensPixelsInsideRegion() throws {
        let source = try checkerboardImage(width: 200, height: 200)

        let rendered = try renderer.render(
            sourceImage: source,
            regions: [MosaicRegion(normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))]
        )

        let samples = try pixels(in: rendered)
        let width = rendered.width
        for y in 60..<140 {
            for x in 60..<140 {
                let offset = (y * width + x) * 4
                #expect(samples[offset] == 127)
                #expect(samples[offset + 1] == 127)
                #expect(samples[offset + 2] == 127)
                #expect(samples[offset + 3] == 255)
            }
        }
    }

    @Test
    func leavesPixelsOutsideRegionUntouched() throws {
        let source = try checkerboardImage(width: 200, height: 200)

        let rendered = try renderer.render(
            sourceImage: source,
            regions: [MosaicRegion(normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))]
        )

        let original = try pixels(in: source)
        let samples = try pixels(in: rendered)
        let width = rendered.width
        for y in 0..<200 where y < 50 || y >= 150 {
            for x in 0..<200 {
                let offset = (y * width + x) * 4
                #expect(samples[offset] == original[offset])
            }
        }
    }

    @Test
    func leavesImageUntouchedWithoutRegions() throws {
        let source = try checkerboardImage(width: 80, height: 80)

        let rendered = try renderer.render(sourceImage: source, regions: [])

        #expect(try pixels(in: rendered) == pixels(in: source))
    }

    @Test
    func ignoresRegionsBelowTheVisibleSize() throws {
        let source = try checkerboardImage(width: 200, height: 200)

        let rendered = try renderer.render(
            sourceImage: source,
            regions: [
                MosaicRegion(normalizedRect: CGRect(x: 0.5, y: 0.5, width: 0.001, height: 0.5))
            ]
        )

        #expect(try pixels(in: rendered) == pixels(in: source))
    }

    @Test
    func rendersFromAppKitImage() throws {
        let source = try checkerboardImage(width: 200, height: 200)
        let image = NSImage(cgImage: source, size: CGSize(width: 200, height: 200))

        let rendered = try renderer.render(
            image: image,
            regions: [MosaicRegion(normalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))]
        )

        let samples = try pixels(in: rendered)
        let offset = (100 * rendered.width + 100) * 4
        #expect(samples[offset] == 127)
    }

    private func checkerboardImage(width: Int, height: Int) throws -> CGImage {
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

        let data = try #require(context.data).bindMemory(
            to: UInt8.self,
            capacity: width * height * 4
        )
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let value: UInt8 = (x + y).isMultiple(of: 2) ? 255 : 0
                data[offset] = value
                data[offset + 1] = value
                data[offset + 2] = value
                data[offset + 3] = 255
            }
        }

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
