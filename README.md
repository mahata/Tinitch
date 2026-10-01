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

## Publish to GitHub Packages

Push a version tag to build and publish an unsigned macOS disk image to a
versioned OCI package in GitHub Container Registry:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The workflow runs the tests, archives the Release configuration, creates
`Tinitch-v0.1.0.dmg`, and publishes it as `ghcr.io/mahata/tinitch:v0.1.0`.
After authenticating ORAS to `ghcr.io`, pull the package into a directory with:

```sh
oras login ghcr.io
oras pull ghcr.io/mahata/tinitch:v0.1.0 --output tinitch-package
```

The package contains an unsigned app, so macOS may require opening it with
**Control-click > Open** the first time. Developer ID signing and notarization
can be added later for public distribution.

Annotation, screenshots, drag and drop, clipboard integration, resizing, and
batch conversion are not included yet.
