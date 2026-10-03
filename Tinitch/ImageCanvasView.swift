import SwiftUI

struct ImageCanvasView: View {
    static let strokeColor = Color(
        .sRGB,
        red: RectangleAnnotation.strokeColorComponents.red,
        green: RectangleAnnotation.strokeColorComponents.green,
        blue: RectangleAnnotation.strokeColorComponents.blue
    )

    let image: NSImage
    @Binding var annotations: [TextAnnotation]
    @Binding var mosaicRegions: [MosaicRegion]
    @Binding var rectangles: [RectangleAnnotation]
    let selectedTool: Tool?

    @FocusState private var focusedAnnotationID: UUID?
    @State private var draftStart: CGPoint?
    @State private var draftRect: CGRect?

    private var isDragTool: Bool {
        selectedTool == .mosaic || selectedTool == .rectangle
    }

    var body: some View {
        GeometryReader { proxy in
            let imageRect = ImageFit.rect(for: image.size, in: proxy.size)
            let sourcePixelSize = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
                .map { CGSize(width: $0.width, height: $0.height) } ?? image.size
            let displayedStrokeWidth = RectangleAnnotation.displayedStrokeWidth(
                sourceSize: sourcePixelSize,
                displayedSize: imageRect.size
            )

            ZStack(alignment: .topLeading) {
                Color.black

                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageRect.width, height: imageRect.height)
                    .position(x: imageRect.midX, y: imageRect.midY)

                if selectedTool == .text {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture().onEnded { value in
                                addAnnotation(at: value.location, in: imageRect)
                            }
                        )
                }

                ForEach(rectangles) { rectangle in
                    let frame = rectangle.rect(in: imageRect.size)

                    RoundedRectangle(cornerRadius: rectangle.cornerRadius(in: imageRect.size))
                        .stroke(
                            Self.strokeColor,
                            lineWidth: displayedStrokeWidth
                        )
                        .frame(width: frame.width, height: frame.height)
                        .position(
                            x: imageRect.minX + frame.midX,
                            y: imageRect.minY + frame.midY
                        )
                        .allowsHitTesting(false)
                }

                ForEach($annotations) { $annotation in
                    TextField("Text", text: $annotation.text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(
                            .system(
                                size: TextAnnotation.fontSize(forHeight: imageRect.height),
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                        .shadow(radius: TextAnnotation.fontSize(forHeight: imageRect.height) / 6)
                        .multilineTextAlignment(.center)
                        .lineLimit(1...)
                        .fixedSize(horizontal: true, vertical: true)
                        .focused($focusedAnnotationID, equals: annotation.id)
                        .position(
                            x: imageRect.minX + annotation.normalizedPosition.x * imageRect.width,
                            y: imageRect.minY + annotation.normalizedPosition.y * imageRect.height
                        )
                }

                if isDragTool {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateDraft(with: value, in: imageRect)
                                }
                                .onEnded { value in
                                    commitDraft(with: value, in: imageRect)
                                }
                        )
                }

                if let draftRect {
                    draftOverlay(
                        for: draftRect,
                        in: imageRect,
                        strokeWidth: displayedStrokeWidth
                    )
                }

                if selectedTool == .text {
                    Button("Add Text", systemImage: "plus") {
                        addAnnotation(
                            at: CGPoint(x: imageRect.midX, y: imageRect.midY),
                            in: imageRect
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("t", modifiers: [.command, .shift])
                    .position(
                        x: imageRect.maxX - 62,
                        y: imageRect.maxY - 24
                    )
                }
            }
            .onChange(of: focusedAnnotationID) { previousID, _ in
                discardEmptyAnnotation(previousID)
            }
        }
        .clipped()
    }

    @ViewBuilder
    private func draftOverlay(
        for rect: CGRect,
        in imageRect: CGRect,
        strokeWidth: CGFloat
    ) -> some View {
        Group {
            if selectedTool == .rectangle {
                RoundedRectangle(
                    cornerRadius: min(
                        min(imageRect.width, imageRect.height)
                            * RectangleAnnotation.cornerRadiusRatio,
                        min(rect.width, rect.height) / 2
                    )
                )
                .stroke(
                    Self.strokeColor,
                    lineWidth: strokeWidth
                )
            } else {
                Rectangle()
                    .stroke(.white, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
        .allowsHitTesting(false)
    }

    private func addAnnotation(at location: CGPoint, in imageRect: CGRect) {
        guard imageRect.contains(location) else {
            return
        }

        let annotation = TextAnnotation(
            normalizedPosition: TextAnnotation.normalizedPosition(
                for: CGPoint(x: location.x - imageRect.minX, y: location.y - imageRect.minY),
                in: imageRect.size
            )
        )
        annotations.append(annotation)
        focusedAnnotationID = annotation.id
    }

    private func discardEmptyAnnotation(_ annotationID: UUID?) {
        guard let annotationID else {
            return
        }

        annotations.removeAll { $0.id == annotationID && !$0.hasVisibleText }
    }

    private func updateDraft(with value: DragGesture.Value, in imageRect: CGRect) {
        guard imageRect.width > 0,
              imageRect.height > 0,
              imageRect.contains(value.startLocation)
        else {
            return
        }

        let start = draftStart ?? clamp(value.startLocation, to: imageRect)
        draftStart = start

        let end = clamp(value.location, to: imageRect)
        draftRect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private func commitDraft(with value: DragGesture.Value, in imageRect: CGRect) {
        defer {
            draftStart = nil
            draftRect = nil
        }

        guard imageRect.width > 0,
              imageRect.height > 0,
              imageRect.contains(value.startLocation)
        else {
            return
        }

        let start = draftStart ?? clamp(value.startLocation, to: imageRect)
        let end = clamp(value.location, to: imageRect)
        let normalizedRect = NormalizedRect.make(
            from: CGPoint(x: start.x - imageRect.minX, y: start.y - imageRect.minY),
            to: CGPoint(x: end.x - imageRect.minX, y: end.y - imageRect.minY),
            in: imageRect.size
        )

        switch selectedTool {
        case .mosaic:
            let region = MosaicRegion(normalizedRect: normalizedRect)
            if region.isVisible {
                mosaicRegions.append(region)
            } else {
                removeMosaicRegion(at: end, in: imageRect)
            }
        case .rectangle:
            let rectangle = RectangleAnnotation(normalizedRect: normalizedRect)
            if rectangle.isVisible {
                rectangles.append(rectangle)
            } else {
                removeRectangle(at: end, in: imageRect)
            }
        default:
            break
        }
    }

    private func removeMosaicRegion(at location: CGPoint, in imageRect: CGRect) {
        guard let point = normalizedPoint(for: location, in: imageRect),
              let index = mosaicRegions.lastIndex(where: { $0.contains(normalizedPoint: point) })
        else {
            return
        }

        mosaicRegions.remove(at: index)
    }

    private func removeRectangle(at location: CGPoint, in imageRect: CGRect) {
        guard let point = normalizedPoint(for: location, in: imageRect),
              let index = rectangles.lastIndex(where: { $0.contains(normalizedPoint: point) })
        else {
            return
        }

        rectangles.remove(at: index)
    }

    private func normalizedPoint(for location: CGPoint, in imageRect: CGRect) -> CGPoint? {
        guard imageRect.contains(location) else {
            return nil
        }

        return CGPoint(
            x: (location.x - imageRect.minX) / imageRect.width,
            y: (location.y - imageRect.minY) / imageRect.height
        )
    }

    private func clamp(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY)
        )
    }
}
