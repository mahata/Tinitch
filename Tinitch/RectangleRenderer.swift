import AppKit
import CoreGraphics

struct RectangleRenderer {
    func render(image: NSImage, rectangles: [RectangleAnnotation]) throws -> CGImage {
        guard let sourceImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageConversionService.ConversionError.unableToDecode
        }

        return try render(sourceImage: sourceImage, rectangles: rectangles)
    }

    func render(sourceImage: CGImage, rectangles: [RectangleAnnotation]) throws -> CGImage {
        let visibleRectangles = rectangles.filter(\.isVisible)
        guard !visibleRectangles.isEmpty else {
            return sourceImage
        }

        let width = sourceImage.width
        let height = sourceImage.height
        guard width > 0, height > 0, let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ImageConversionService.ConversionError.unableToEncode
        }

        let imageSize = CGSize(width: width, height: height)
        context.draw(sourceImage, in: CGRect(origin: .zero, size: imageSize))

        let strokeWidth = RectangleAnnotation.strokeWidth(for: imageSize)
        context.setShouldAntialias(true)
        context.setLineWidth(strokeWidth)
        context.setStrokeColor(Self.strokeColor)

        for rectangle in visibleRectangles {
            let drawingRect = Self.strokeRect(for: rectangle, in: imageSize, strokeWidth: strokeWidth)
            guard !drawingRect.isNull, drawingRect.width > 0, drawingRect.height > 0 else {
                continue
            }

            let radius = min(
                rectangle.cornerRadius(in: imageSize),
                min(drawingRect.width, drawingRect.height) / 2
            )
            context.addPath(
                CGPath(
                    roundedRect: drawingRect,
                    cornerWidth: radius,
                    cornerHeight: radius,
                    transform: nil
                )
            )
            context.strokePath()
        }

        guard let renderedImage = context.makeImage() else {
            throw ImageConversionService.ConversionError.unableToEncode
        }

        return renderedImage
    }

    /// Normalized rects use a top-left origin, while `CGContext` draws from the bottom left.
    private static func strokeRect(
        for rectangle: RectangleAnnotation,
        in imageSize: CGSize,
        strokeWidth: CGFloat
    ) -> CGRect {
        let topDownRect = rectangle.rect(in: imageSize)
        let flippedRect = CGRect(
            x: topDownRect.minX,
            y: imageSize.height - topDownRect.maxY,
            width: topDownRect.width,
            height: topDownRect.height
        )
        let drawableBounds = CGRect(origin: .zero, size: imageSize)
            .insetBy(dx: strokeWidth / 2, dy: strokeWidth / 2)

        return flippedRect.intersection(drawableBounds)
    }

    private static let strokeColor = CGColor(
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        components: [
            RectangleAnnotation.strokeColorComponents.red,
            RectangleAnnotation.strokeColorComponents.green,
            RectangleAnnotation.strokeColorComponents.blue,
            1,
        ]
    ) ?? CGColor(gray: 0, alpha: 1)
}
