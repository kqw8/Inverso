# Inverso

`inverso` is a tiny macOS CLI daemon that reverses the vertical direction of a physical mouse wheel while leaving trackpad-like scrolling alone.

It is intentionally not a menu bar app. Install it once, let launchd keep it running, and control it from the terminal.

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

macOS requires Accessibility permission for tools that read and rewrite input events. Run:

```sh
inverso permission
```

Then approve Inverso in System Settings -> Privacy & Security -> Accessibility.

## Notes

Inverso handles ordinary physical mouse-wheel events. Trackpad-like events are passed through unchanged.
