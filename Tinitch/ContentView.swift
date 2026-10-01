import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isConverting = false
    @State private var outputURL: URL?
    @State private var errorMessage: String?

    private let conversionService = ImageConversionService()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.arrow.down")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Convert an image to PNG")
                    .font(.title2.bold())

                Text("Choose a JPEG or PNG, then select where to save the converted PNG.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if isConverting {
                ProgressView("Converting...")
                    .controlSize(.small)
            } else {
                Button("Choose Image...") {
                    chooseImage()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }

            if let outputURL {
                Label {
                    Text("Saved \(outputURL.lastPathComponent)")
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .font(.callout)
            }
        }
        .frame(width: 520, height: 300)
        .padding(32)
        .alert(
            "Conversion Failed",
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

    private func chooseImage() {
        guard !isConverting else {
            return
        }

        let openPanel = NSOpenPanel()
        openPanel.title = "Choose an Image"
        openPanel.prompt = "Choose"
        openPanel.allowedContentTypes = [.jpeg, .png]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false

        guard openPanel.runModal() == .OK, let inputURL = openPanel.url else {
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

        let outputURL = selectedOutputURL.pathExtension.lowercased() == "png"
            ? selectedOutputURL
            : selectedOutputURL.deletingPathExtension().appendingPathExtension("png")

        isConverting = true
        self.outputURL = nil
        errorMessage = nil

        Task {
            do {
                try await conversionService.convert(inputURL: inputURL, outputURL: outputURL)
                self.outputURL = outputURL
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }

            isConverting = false
        }
    }
}

#Preview {
    ContentView()
}
