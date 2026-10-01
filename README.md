# Tinitch

Tinitch is a native macOS image tool inspired by Skitch.

The first milestone previews and converts JPEG and PNG images to PNG:

1. Click **Choose Image...**, drop an image onto the window, or paste one with
   **Command-V**.
2. Review the image preview and click **Save as PNG...**. Images that are not
   JPEG or PNG can still be previewed, but cannot be converted yet.
3. Choose where to save the output.
4. Tinitch writes the converted image as a PNG.

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or later

## Build and test

Open `Tinitch.xcodeproj` in Xcode, or use the command line:

```sh
xcodebuild -project Tinitch.xcodeproj -scheme Tinitch build
xcodebuild -project Tinitch.xcodeproj -scheme Tinitch test
```

## Release

Push a version tag to build an unsigned macOS disk image and publish it as a
GitHub Release. Tags must use semantic versions such as `v1.2.3` or
`v1.2.3-beta.1`:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The workflow runs the tests, archives the Release configuration, creates
`Tinitch-v0.1.0.dmg` with a `.sha256` checksum, and attaches both to the
release. Download them from the
[Releases page](https://github.com/mahata/Tinitch/releases) or with:

```sh
gh release download v0.1.0 --repo mahata/Tinitch
shasum -a 256 -c Tinitch-v0.1.0.dmg.sha256
```

The disk image contains an unsigned app, so macOS may require opening it with
**Control-click > Open** the first time. Developer ID signing and notarization
can be added later for public distribution.

Annotation, screenshots, resizing, and batch conversion are not included yet.
