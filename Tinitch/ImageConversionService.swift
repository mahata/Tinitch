import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageConversionService: Sendable {
    enum ConversionError: LocalizedError, Equatable {
        case unreadableInput
        case unsupportedFormat
        case unableToDecode
        case unableToEncode
        case unableToWrite

        var errorDescription: String? {
            switch self {
            case .unreadableInput:
                "The selected file is not a readable image."
            case .unsupportedFormat:
                "Tinitch currently supports JPEG and PNG images only."
            case .unableToDecode:
                "The image data could not be decoded."
            case .unableToEncode:
                "The image could not be encoded as PNG."
            case .unableToWrite:
                "The PNG could not be written to the selected location."
            }
        }
    }

    func convert(inputURL: URL, outputURL: URL) async throws {
        try await Task.detached(priority: .userInitiated) {
            try Self.convertSynchronously(inputURL: inputURL, outputURL: outputURL)
        }.value
    }

    func write(image: CGImage, to outputURL: URL) throws {
        let encodedData = try Self.encodePNG(image)

        do {
            try encodedData.write(to: outputURL, options: .atomic)
        } catch {
            throw ConversionError.unableToWrite
        }
    }

    func validate(inputURL: URL) throws {
        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let sourceType = CGImageSourceGetType(source)
        else {
            throw ConversionError.unreadableInput
        }

        guard Self.allowedTypes.contains(sourceType as String) else {
            throw ConversionError.unsupportedFormat
        }
    }

    private static func convertSynchronously(inputURL: URL, outputURL: URL) throws {
        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let sourceType = CGImageSourceGetType(source)
        else {
            throw ConversionError.unreadableInput
        }

        guard Self.allowedTypes.contains(sourceType as String) else {
            throw ConversionError.unsupportedFormat
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber
        else {
            throw ConversionError.unableToDecode
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(width.intValue, height.intValue),
            kCGImageSourceShouldCacheImmediately: true,
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            throw ConversionError.unableToDecode
        }

        let encodedData = try Self.encodePNG(image)

        do {
            try encodedData.write(to: outputURL, options: .atomic)
        } catch {
            throw ConversionError.unableToWrite
        }
    }

    private static func encodePNG(_ image: CGImage) throws -> Data {
        let encodedData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            encodedData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw ConversionError.unableToEncode
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.unableToEncode
        }

        return encodedData as Data
    }

    private static let allowedTypes = [
        UTType.jpeg.identifier,
        UTType.png.identifier,
    ]
}
