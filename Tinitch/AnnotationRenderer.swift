import AppKit
import CoreGraphics

@MainActor
struct AnnotationRenderer {
    func render(image: NSImage, annotations: [TextAnnotation]) throws -> CGImage {
        guard let sourceImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageConversionService.ConversionError.unableToDecode
        }

        return try render(sourceImage: sourceImage, annotations: annotations)
    }

    func render(sourceImage: CGImage, annotations: [TextAnnotation]) throws -> CGImage {
        let imageSize = CGSize(width: sourceImage.width, height: sourceImage.height)
        guard let context = CGContext(
            data: nil,
            width: sourceImage.width,
            height: sourceImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ImageConversionService.ConversionError.unableToEncode
        }

        context.draw(sourceImage, in: CGRect(origin: .zero, size: imageSize))

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)

        let attributes = Self.textAttributes(forHeight: imageSize.height)
        for annotation in annotations where !annotation.text.isEmpty {
            let attributedText = NSAttributedString(string: annotation.text, attributes: attributes)
            let textSize = attributedText.size()
            let center = annotation.point(in: imageSize)
            attributedText.draw(
                at: CGPoint(
                    x: center.x - textSize.width / 2,
                    y: imageSize.height - center.y - textSize.height / 2
                )
            )
        }

        NSGraphicsContext.restoreGraphicsState()

        guard let renderedImage = context.makeImage() else {
            throw ImageConversionService.ConversionError.unableToEncode
        }

        return renderedImage
    }

    static func textAttributes(forHeight height: CGFloat) -> [NSAttributedString.Key: Any] {
        let fontSize = TextAnnotation.fontSize(forHeight: height)
        let shadow = NSShadow()
        shadow.shadowColor = .black
        shadow.shadowBlurRadius = fontSize / 6
        shadow.shadowOffset = CGSize(width: 0, height: -fontSize / 16)

        return [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: NSColor.white,
            .shadow: shadow,
        ]
    }
}
