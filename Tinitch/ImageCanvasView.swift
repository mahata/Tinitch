import SwiftUI

struct ImageCanvasView: View {
    let image: NSImage
    @Binding var annotations: [TextAnnotation]
    let isTextToolActive: Bool

    @FocusState private var focusedAnnotationID: UUID?

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

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            addAnnotation(at: value.location, in: imageRect)
                        }
                    )
                    .allowsHitTesting(isTextToolActive)

                ForEach($annotations) { $annotation in
                    TextField("Text", text: $annotation.text)
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
                        .fixedSize()
                        .focused($focusedAnnotationID, equals: annotation.id)
                        .position(
                            x: imageRect.minX + annotation.normalizedPosition.x * imageRect.width,
                            y: imageRect.minY + annotation.normalizedPosition.y * imageRect.height
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

        annotations.removeAll { $0.id == annotationID && $0.text.isEmpty }
    }
}
