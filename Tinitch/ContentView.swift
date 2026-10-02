import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isConverting = false
    @State private var inputURL: URL?
    @State private var previewImage: NSImage?
    @State private var temporaryInputURL: URL?
    @State private var outputURL: URL?
    @State private var errorMessage: String?
    @State private var isDropTargeted = false
    @State private var selectedTool: Tool?
    @State private var annotations: [TextAnnotation] = []

    private let conversionService = ImageConversionService()
    private let previewLoader = ImagePreviewLoader()
    private let annotationRenderer = AnnotationRenderer()

    var body: some View {
        Group {
            if let previewImage {
                editor(for: previewImage)
            } else {
                emptyState
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .onDrop(
            of: [UTType.fileURL.identifier, UTType.image.identifier],
            isTargeted: $isDropTargeted,
            perform: handleDrop
        )
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.tint, lineWidth: 3)
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .onPasteCommand(of: [.image], perform: handlePaste)
        .onDisappear(perform: removeTemporaryInput)
        .alert(
            "Image Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The image could not be converted.")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.arrow.down")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Convert an image to PNG")
                    .font(.title2.bold())

                Text("Choose, drop, or paste an image.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Choose Image...") {
                chooseImage()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            Text("Drop an image here or press ⌘V to paste.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private func editor(for image: NSImage) -> some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            ImageCanvasView(
                image: image,
                annotations: $annotations,
                isTextToolActive: selectedTool == .text
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            ToolPickerView(selectedTool: $selectedTool)

            Spacer()

            if isConverting {
                ProgressView("Converting...")
                    .controlSize(.small)
            }

            if let outputURL {
                Label {
                    Text("Saved \(outputURL.lastPathComponent)")
                        .lineLimit(2)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .font(.caption)
            }

            VStack(spacing: 8) {
                Button("Choose Another...") {
                    chooseImage()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Save as PNG...") {
                    savePreviewedImage()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .keyboardShortcut(.defaultAction)
            }
            .disabled(isConverting)
        }
        .padding(16)
        .frame(width: 200)
        .background(.bar)
    }

    private func chooseImage() {
        guard !isConverting else {
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.title = "Choose an Image"
        openPanel.prompt = "Choose"
        openPanel.allowedContentTypes = [.image]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false

        guard openPanel.runModal() == .OK, let inputURL = openPanel.url else {
            return
        }

        loadImage(from: inputURL)
    }

    private func loadImage(from inputURL: URL, isTemporary: Bool = false) {
        guard !isConverting else {
            if isTemporary {
                try? FileManager.default.removeItem(at: inputURL)
            }
            return
        }

        do {
            let image = try previewLoader.load(from: inputURL)

            removeTemporaryInput()
            self.inputURL = inputURL
            previewImage = image
            temporaryInputURL = isTemporary ? inputURL : nil
            annotations = []
            outputURL = nil
            errorMessage = nil
        } catch {
            if isTemporary {
                try? FileManager.default.removeItem(at: inputURL)
            }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func savePreviewedImage() {
        guard let inputURL, !isConverting else {
            return
        }

        do {
            try conversionService.validate(inputURL: inputURL)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return
        }

        let savePanel = NSSavePanel()
        savePanel.title = "Save PNG"
        savePanel.prompt = "Save"
        savePanel.allowedContentTypes = [.png]
        savePanel.allowsOtherFileTypes = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = inputURL.deletingPathExtension().lastPathComponent + ".png"

        guard savePanel.runModal() == .OK, let selectedOutputURL = savePanel.url else {
            return
        }

        let destinationURL = selectedOutputURL.pathExtension.lowercased() == "png"
            ? selectedOutputURL
            : selectedOutputURL.deletingPathExtension().appendingPathExtension("png")

        isConverting = true
        self.outputURL = nil
        errorMessage = nil

        Task {
            do {
                let annotatedAnnotations = annotations.filter(\.hasVisibleText)
                if annotatedAnnotations.isEmpty {
                    try await conversionService.convert(inputURL: inputURL, outputURL: destinationURL)
                } else if let previewImage {
                    let renderedImage = try annotationRenderer.render(
                        image: previewImage,
                        annotations: annotatedAnnotations
                    )
                    try await conversionService.write(image: renderedImage, to: destinationURL)
                } else {
                    throw ImageConversionService.ConversionError.unableToDecode
                }

                self.outputURL = destinationURL
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }

            isConverting = false
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !isConverting, let provider = providers.first else {
            return false
        }

        Task {
            do {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    let data = try await loadDataRepresentation(
                        from: provider,
                        typeIdentifier: UTType.fileURL.identifier
                    )
                    guard let data, let url = URL(dataRepresentation: data, relativeTo: nil) else {
                        throw ImageConversionService.ConversionError.unreadableInput
                    }
                    loadImage(from: url)
                } else {
                    try await loadImageData(from: provider)
                }
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }

        return true
    }

    private func handlePaste(_ providers: [NSItemProvider]) {
        guard !isConverting, let provider = providers.first else {
            return
        }

        Task {
            do {
                try await loadImageData(from: provider)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    private func loadImageData(from provider: NSItemProvider) async throws {
        let typeIdentifier = provider.registeredTypeIdentifiers.first {
            guard let type = UTType($0) else {
                return false
            }
            return type.conforms(to: .image)
        }
        guard let typeIdentifier else {
            throw ImageConversionService.ConversionError.unreadableInput
        }

        guard let data = try await loadDataRepresentation(
            from: provider,
            typeIdentifier: typeIdentifier
        ) else {
            throw ImageConversionService.ConversionError.unreadableInput
        }

        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Tinitch-\(UUID().uuidString)")
            .appendingPathExtension(
                UTType(typeIdentifier)?.preferredFilenameExtension ?? "image"
            )
        try data.write(to: temporaryURL, options: .atomic)
        loadImage(from: temporaryURL, isTemporary: true)
    }

    private func loadDataRepresentation(
        from provider: NSItemProvider,
        typeIdentifier: String
    ) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data)
                }
            }
        }
    }

    private func removeTemporaryInput() {
        guard let temporaryInputURL else {
            return
        }

        try? FileManager.default.removeItem(at: temporaryInputURL)
        self.temporaryInputURL = nil
    }
}

#Preview {
    ContentView()
}
