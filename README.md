# Tinitch

Tinitch is a native macOS image tool inspired by Skitch.

The first milestone converts JPEG and PNG images to PNG:

1. Click **Choose Image...** and select a `.jpg`, `.jpeg`, or `.png` file.
2. Choose where to save the output.
3. Tinitch writes the converted image as a PNG.

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or later

## Build and test

Open `Tinitch.xcodeproj` in Xcode, or use the command line:

```sh
xcodebuild -project Tinitch.xcodeproj -scheme Tinitch build
xcodebuild -project Tinitch.xcodeproj -scheme Tinitch test
```

Annotation, screenshots, drag and drop, clipboard integration, resizing, and
batch conversion are not included yet.
