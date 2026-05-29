fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build

```sh
[bundle exec] fastlane android build
```

Build release AAB only (no upload)

### android internal

```sh
[bundle exec] fastlane android internal
```

Build and upload to Google Play internal testing track

### android beta

```sh
[bundle exec] fastlane android beta
```

Build and upload to Google Play beta (open testing) track

### android release

```sh
[bundle exec] fastlane android release
```

Build and upload to Google Play production track

### android upload_metadata

```sh
[bundle exec] fastlane android upload_metadata
```

Upload only text metadata (title, descriptions) to Play Store

### android upload_screenshots

```sh
[bundle exec] fastlane android upload_screenshots
```

Upload only screenshots + feature graphic / icon to Play Store

### android upload_listing

```sh
[bundle exec] fastlane android upload_listing
```

Upload text metadata + images + screenshots to Play Store

### android download_metadata

```sh
[bundle exec] fastlane android download_metadata
```

Download current metadata from Play Store

### android screenshots

```sh
[bundle exec] fastlane android screenshots
```

Frame raw Android screenshots using frameit

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
