import SwiftUI

struct ImageCanvasView: View {
    let image: NSImage
    @Binding var annotations: [TextAnnotation]
    @Binding var mosaicRegions: [MosaicRegion]
    let selectedTool: Tool?

    @FocusState private var focusedAnnotationID: UUID?
    @State private var draftMosaicStart: CGPoint?
    @State private var draftMosaicRect: CGRect?

    var body: some View {
        GeometryReader { proxy in
            let imageRect = ImageFit.rect(for: image.size, in: proxy.size)

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

                if selectedTool == .mosaic {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateDraftMosaic(with: value, in: imageRect)
                                }
                                .onEnded { value in
                                    commitDraftMosaic(with: value, in: imageRect)
                                }
                        )

                    if let draftMosaicRect {
                        Rectangle()
                            .stroke(.white, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .frame(width: draftMosaicRect.width, height: draftMosaicRect.height)
                            .position(x: draftMosaicRect.midX, y: draftMosaicRect.midY)
                            .allowsHitTesting(false)
                    }
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

    private func updateDraftMosaic(with value: DragGesture.Value, in imageRect: CGRect) {
        guard imageRect.width > 0,
              imageRect.height > 0,
              imageRect.contains(value.startLocation)
        else {
            return
        }

        let start = draftMosaicStart ?? clamp(value.startLocation, to: imageRect)
        draftMosaicStart = start

        let end = clamp(value.location, to: imageRect)
        draftMosaicRect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private func commitDraftMosaic(with value: DragGesture.Value, in imageRect: CGRect) {
        defer {
            draftMosaicStart = nil
            draftMosaicRect = nil
        }

        guard imageRect.width > 0,
              imageRect.height > 0,
              imageRect.contains(value.startLocation)
        else {
            return
        }

        let start = draftMosaicStart ?? clamp(value.startLocation, to: imageRect)
        let end = clamp(value.location, to: imageRect)
        let region = MosaicRegion(
            normalizedRect: MosaicRegion.normalizedRect(
                from: CGPoint(x: start.x - imageRect.minX, y: start.y - imageRect.minY),
                to: CGPoint(x: end.x - imageRect.minX, y: end.y - imageRect.minY),
                in: imageRect.size
            )
        )

        if region.isVisible {
            mosaicRegions.append(region)
        } else {
            removeMosaicRegion(at: end, in: imageRect)
        }
    }

    private func removeMosaicRegion(at location: CGPoint, in imageRect: CGRect) {
        guard imageRect.contains(location) else {
            return
        }

        let point = CGPoint(
            x: (location.x - imageRect.minX) / imageRect.width,
            y: (location.y - imageRect.minY) / imageRect.height
        )

        guard let index = mosaicRegions.lastIndex(where: { $0.contains(normalizedPoint: point) })
        else {
            return
        }

        mosaicRegions.remove(at: index)
    }

    private func clamp(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, rect.minX), rect.maxX),
            y: min(max(point.y, rect.minY), rect.maxY)
        )
    }
}
