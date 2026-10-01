import AppKit
import Foundation

struct ImagePreviewLoader {
    func load(from inputURL: URL) throws -> NSImage {
        guard let image = NSImage(contentsOf: inputURL) else {
            throw ImageConversionService.ConversionError.unableToDecode
        }

        return image
    }
}
