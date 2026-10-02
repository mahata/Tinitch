# Tinitch

Tinitch is a native macOS image tool inspired by Skitch.

The first milestone previews, annotates, and converts JPEG and PNG images to
PNG:

1. Click **Choose Image...**, drop an image onto the window, or paste one with
   **Command-V**.
2. The image fills the window next to a tool picker on the left.
3. Select the **Text** tool and click the image to add overlay letters. Press
   **Return** to add a line within the label. Click elsewhere or use **Add
   Text** to add another label; empty labels disappear.
4. Click **Save as PNG...** and choose where to save the output. Images that
   are not JPEG or PNG can still be previewed, but cannot be converted yet.
5. Tinitch writes the converted image as a PNG, including any overlay letters.

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or later

## Build and test

Open `Tinitch.xcodeproj` in Xcode, or use the command line:

```sh
xcodebuild -project Tinitch.xcodeproj -scheme Tinitch build
xcodebuild -project Tinitch.xcodeproj -scheme Tinitch test
```

## App icon

The icon is generated from code rather than checked in by hand. Regenerate it
after editing `Tools/GenerateAppIcon.swift`:

```sh
swift Tools/GenerateAppIcon.swift Tinitch/Assets.xcassets/AppIcon.appiconset
```

The script renders every size the macOS asset catalog needs and rewrites the
set's `Contents.json`.

## Release

Every successful CI run caused by a push to `main` builds an unsigned macOS
disk image and publishes it as a GitHub Release. Pull requests never publish
releases. Pushes that change only Markdown files, `LICENSE`, `.gitignore`, or
the Dependabot configuration do not run CI, so they do not publish a release
either.

The first automated release is `v0.1.0`. Each later release increments the
patch component of the highest existing `vMAJOR.MINOR.PATCH` tag, so merging a
Dependabot update also ships a new patch version. Rerunning CI for a commit
that already has a published release does not create another version. To start
a new minor or major series, push a tag such as `v0.2.0` to the latest released
commit and rerun that commit's Release workflow run; later releases continue
from the new tag.

The workflow archives the Release configuration with the tag as the app's
marketing version and the Release workflow run number as its build number, then
attaches `Tinitch-<version>.dmg` and a `.sha256` checksum to the release.
Download them from the
[Releases page](https://github.com/mahata/Tinitch/releases) or with:

```sh
gh release download v0.1.0 --repo mahata/Tinitch
shasum -a 256 -c Tinitch-0.1.0.dmg.sha256
```

The disk image contains an unsigned app, so macOS may require opening it with
**Control-click > Open** the first time. Developer ID signing and notarization
can be added later for public distribution.

Screenshots, resizing, and batch conversion are not included yet.
