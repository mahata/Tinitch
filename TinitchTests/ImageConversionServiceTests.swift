import CoreGraphics
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Tinitch

struct ImageConversionServiceTests {
    private let service = ImageConversionService()

    @Test
    func convertsJPEGToPNGWithoutChangingDimensions() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("input.jpg")
        let outputURL = directory.appendingPathComponent("output.png")
        try writeImage(
            makeImage(width: 3, height: 2, pixels: [
                255, 0, 0, 255,
                0, 255, 0, 255,
                0, 0, 255, 255,
                255, 255, 0, 255,
                255, 0, 255, 255,
                0, 255, 255, 255,
            ]),
            type: .jpeg,
            to: inputURL
        )

        try await service.convert(inputURL: inputURL, outputURL: outputURL)

        let source = try #require(CGImageSourceCreateWithURL(outputURL as CFURL, nil))
        #expect(CGImageSourceGetType(source) as String? == UTType.png.identifier)

        let properties = try #require(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        )
        #expect((properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue == 3)
        #expect((properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue == 2)
    }

    @Test
    func preservesAlphaWhenConvertingPNG() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("input.png")
        let outputURL = directory.appendingPathComponent("output.png")
        try writeImage(
            makeImage(width: 2, height: 1, pixels: [
                255, 0, 0, 0,
                0, 0, 255, 255,
            ]),
            type: .png,
            to: inputURL
        )

        try await service.convert(inputURL: inputURL, outputURL: outputURL)

        let source = try #require(CGImageSourceCreateWithURL(outputURL as CFURL, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let pixels = try rgbaPixels(from: image)
        #expect(pixels[3] == 0)
        #expect(pixels[7] == 255)
    }

    @Test
    func normalizesJPEGOrientation() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("input.jpg")
        let outputURL = directory.appendingPathComponent("output.png")
        try writeImage(
            makeImage(width: 3, height: 2, pixels: [
                255, 0, 0, 255,
                0, 255, 0, 255,
                0, 0, 255, 255,
                255, 255, 0, 255,
                255, 0, 255, 255,
                0, 255, 255, 255,
            ]),
            type: .jpeg,
            properties: [kCGImagePropertyOrientation: 6],
            to: inputURL
        )

        try await service.convert(inputURL: inputURL, outputURL: outputURL)

        let source = try #require(CGImageSourceCreateWithURL(outputURL as CFURL, nil))
        let properties = try #require(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        )
        #expect((properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue == 2)
        #expect((properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue == 3)
        #expect((properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1 == 1)
    }

    @Test
    func rejectsUnsupportedImageFormats() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("input.gif")
        let outputURL = directory.appendingPathComponent("output.png")
        try writeImage(
            makeImage(width: 1, height: 1, pixels: [255, 0, 0, 255]),
            type: .gif,
            to: inputURL
        )

        await #expect(throws: ImageConversionService.ConversionError.unsupportedFormat) {
            try await service.convert(inputURL: inputURL, outputURL: outputURL)
        }
        #expect(!FileManager.default.fileExists(atPath: outputURL.path))
    }

    @Test
    func validatesSupportedImageFormatsBeforeConversion() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("input.gif")
        try writeImage(
            makeImage(width: 1, height: 1, pixels: [255, 0, 0, 255]),
            type: .gif,
            to: inputURL
        )

        #expect(throws: ImageConversionService.ConversionError.unsupportedFormat) {
            try service.validate(inputURL: inputURL)
        }
    }

    @Test
    func invalidInputDoesNotCreateOutput() async throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("input.jpg")
        let outputURL = directory.appendingPathComponent("output.png")
        try Data("not an image".utf8).write(to: inputURL)

        await #expect(throws: ImageConversionService.ConversionError.unreadableInput) {
            try await service.convert(inputURL: inputURL, outputURL: outputURL)
        }
        #expect(!FileManager.default.fileExists(atPath: outputURL.path))
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private func makeImage(width: Int, height: Int, pixels: [UInt8]) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let provider = CGDataProvider(data: Data(pixels) as CFData)!

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )!
    }

    private func writeImage(
        _ image: CGImage,
        type: UTType,
        properties: [CFString: Any]? = nil,
        to url: URL
    ) throws {
        let destination = try #require(
            CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, properties as CFDictionary?)
        #expect(CGImageDestinationFinalize(destination))
    }

    private func rgbaPixels(from image: CGImage) throws -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        )
        let context = try #require(
            CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo.rawValue
            )
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return pixels
    }
}
