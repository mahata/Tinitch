import AppKit
import CoreGraphics

struct MosaicRenderer {
    func render(image: NSImage, regions: [MosaicRegion]) throws -> CGImage {
        guard let sourceImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageConversionService.ConversionError.unableToDecode
        }

        return try render(sourceImage: sourceImage, regions: regions)
    }

    func render(sourceImage: CGImage, regions: [MosaicRegion]) throws -> CGImage {
        let visibleRegions = regions.filter(\.isVisible)
        guard !visibleRegions.isEmpty else {
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

        guard let data = context.data else {
            throw ImageConversionService.ConversionError.unableToEncode
        }

        let bytesPerRow = context.bytesPerRow
        let pixels = data.bindMemory(to: UInt8.self, capacity: height * bytesPerRow)
        let blockSize = max(Int(MosaicRegion.blockSize(for: imageSize).rounded()), 1)

        for region in visibleRegions {
            pixelate(
                region.rect(in: imageSize),
                in: pixels,
                bytesPerRow: bytesPerRow,
                width: width,
                height: height,
                blockSize: blockSize
            )
        }

        guard let renderedImage = context.makeImage() else {
            throw ImageConversionService.ConversionError.unableToEncode
        }

        return renderedImage
    }

    /// Pixel rows are stored top-down, so `rect` is used with its top-left origin as-is.
    private func pixelate(
        _ rect: CGRect,
        in pixels: UnsafeMutablePointer<UInt8>,
        bytesPerRow: Int,
        width: Int,
        height: Int,
        blockSize: Int
    ) {
        let minX = max(Int(rect.minX.rounded(.down)), 0)
        let minY = max(Int(rect.minY.rounded(.down)), 0)
        let maxX = min(Int(rect.maxX.rounded(.up)), width)
        let maxY = min(Int(rect.maxY.rounded(.up)), height)

        guard minX < maxX, minY < maxY else {
            return
        }

        var blockMinY = minY
        while blockMinY < maxY {
            let blockMaxY = min(blockMinY + blockSize, maxY)
            var blockMinX = minX

            while blockMinX < maxX {
                let blockMaxX = min(blockMinX + blockSize, maxX)

                var totals = [Int](repeating: 0, count: 4)
                var sampleCount = 0
                for y in blockMinY..<blockMaxY {
                    for x in blockMinX..<blockMaxX {
                        let offset = y * bytesPerRow + x * 4
                        for component in 0..<4 {
                            totals[component] += Int(pixels[offset + component])
                        }
                        sampleCount += 1
                    }
                }

                if sampleCount > 0 {
                    let averages = totals.map { UInt8($0 / sampleCount) }
                    for y in blockMinY..<blockMaxY {
                        for x in blockMinX..<blockMaxX {
                            let offset = y * bytesPerRow + x * 4
                            for component in 0..<4 {
                                pixels[offset + component] = averages[component]
                            }
                        }
                    }
                }

                blockMinX = blockMaxX
            }

            blockMinY = blockMaxY
        }
    }
}
