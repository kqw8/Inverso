# Inverso

`inverso` is a tiny macOS CLI daemon that reverses the vertical direction of a physical mouse wheel while leaving trackpad-like scrolling alone.

It is intentionally not a menu bar app. Install it once, let launchd keep it running, and control it from the terminal.

## Install

### Quick install

No Xcode required. This downloads the latest universal binary from GitHub Releases, verifies its checksum, and installs it to `/usr/local/bin`:

```sh
curl -fsSL https://raw.githubusercontent.com/kqw8/Inverso/main/scripts/install.sh | bash
```

Then start the background service:

```sh
inverso install
```

### Build from source

Requires the Swift toolchain:

```sh
git clone https://github.com/kqw8/Inverso.git
cd Inverso
swift build -c release
.build/release/inverso install
```

## Commands

```sh
inverso install
inverso status
inverso permission
inverso stop
inverso start
inverso uninstall
```

`install` enables start-at-login by default.

## Permission

macOS requires Accessibility permission for tools that read and rewrite input events.

When the background service starts without permission, Inverso asks macOS for approval and keeps retrying while it waits. You can also trigger the same flow manually:

```sh
inverso permission
```

Then approve Inverso in System Settings -> Privacy & Security -> Accessibility.

If macOS does not list the binary, add `/usr/local/bin/inverso` manually.

## Notes

Inverso handles ordinary physical mouse-wheel events. Trackpad-like events are passed through unchanged.
