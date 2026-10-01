import CoreGraphics
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Tinitch

@MainActor
struct ImagePreviewLoaderTests {
    private let loader = ImagePreviewLoader()

    @Test
    func loadsImageForPreview() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("input.png")
        try writeImage(width: 3, height: 2, type: .png, to: inputURL)

        let image = try loader.load(from: inputURL)

        #expect(image.size == CGSize(width: 3, height: 2))
    }

    @Test
    func loadsPreviewForFormatUnsupportedByConversion() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("input.gif")
        try writeImage(width: 2, height: 1, type: .gif, to: inputURL)

        let image = try loader.load(from: inputURL)

        #expect(image.size == CGSize(width: 2, height: 1))
    }

    @Test
    func rejectsInvalidImageData() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let inputURL = directory.appendingPathComponent("input.png")
        try Data("not an image".utf8).write(to: inputURL)

        #expect(throws: ImageConversionService.ConversionError.unableToDecode) {
            try loader.load(from: inputURL)
        }
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

    private func writeImage(width: Int, height: Int, type: UTType, to url: URL) throws {
        let pixels = [UInt8](repeating: 255, count: width * height * 4)
        let provider = try #require(CGDataProvider(data: Data(pixels) as CFData))
        let image = try #require(
            CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        )
        let destination = try #require(
            CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
    }
}
