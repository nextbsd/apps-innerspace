# InnerSpace

InnerSpace brings BackSpace-era animations to your desktop, with an animated
background and a manually started full-screen saver.

## macOS

Requires macOS 11 or later and Xcode Command Line Tools (`xcode-select --install`)
or Xcode. No GNUstep installation is needed.

From the project directory:

```sh
make
open build/InnerSpace.app
```

You can also run `make run`, or copy `build/InnerSpace.app` into Applications.
The app bundles all 16 animation modules. Select an animation, then choose
**Preview**, **Desktop**, or **Full Screen**. The last selected module and mode
are saved as you change them and restored on the next launch. Desktop mode
restarts quietly in the background, while Preview opens the controls and Full
Screen reopens the saver. On first launch, or if the saved mode is invalid,
Preview is used; a removed module falls back to Space2View.
The slider adjusts animation speed.
Press a key or click to leave full screen; Preview stops the desktop background.
Closing the control window leaves the animation running on the desktop. If you
close it during preview, InnerSpace switches to desktop mode automatically.
Click the Dock icon, choose **InnerSpace > Show Controls** (Command-0), or use
**Show Controls** in the sparkle-shaped menu-bar status item to reopen the
controls without restarting the desktop animation.

The status menu provides every installed module, Preview/Desktop/Full Screen,
pause/resume, animation speed, and Quit. Check **Hide Dock Icon** in the main
window (below the speed slider), or select it in the status menu, to run without
a Dock icon; this preference is saved across launches. The status item stays
available, and Show Controls works while the Dock icon is hidden. Uncheck
**Hide Dock Icon** to restore it. Quit from the status menu or use Command-Q.

The default build targets your Mac's processor. To build for both Apple Silicon
and Intel:

```sh
ARCHS="arm64 x86_64" ./macOS/build.sh
```

The build is locally ad-hoc signed. Distribution to other Macs would require
Developer ID signing and notarization. The old `InnerSpace.xcode` project is
historical; use the make/script build above with current Xcode.

### Verification

```sh
make test
```

This loads every bundled module, renders 600 frames per module, verifies pixel
changes (Black should stay black), checks the generated module manifest against
the dropdown, verifies StepMan’s image resource, and exercises all three window modes. The
window checks briefly open desktop/full-screen windows. They also exercise the
native settings, preference persistence, closing the controls with a live timer,
and reopening through the Dock/menu paths. The status-menu checks cover module
selection, modes, speed, pause/resume, Dock hiding/restoration, startup with a
hidden Dock icon, and Quit. A separate test runs real quit/relaunch cycles for
all three modes, closing controls into desktop mode, and missing/invalid saved
settings. It uses a temporary app identifier and preferences domain. Tests
restore your saved preferences. PNG render samples are
written to `build/`. Runtime checks were performed on Apple Silicon; the Intel
slice is cross-compiled, not runtime-tested on Intel hardware.

### Implementation and current scope

The native Cocoa host lives in `macOS/main.m`. It uses a persistent bitmap for
legacy incremental drawing, so animation trails survive AppKit redraws. A small
Core Graphics adapter replaces the modules' Display PostScript calls. SignalHead
draws each frame into the host bitmap, and Neko receives host window coordinates. GNUstep's
Gorm files are not loaded by Cocoa.

All 16 animations are available, with module selection and speed controls.
The build discovers every `*.bproj` project from its GNUmakefile source and
resource declarations, rather than maintaining a separate macOS module list.
It includes Black, Boink, BouncyClock, Boxes, DictionaryWords, FlyingToasters,
ItJustStopped, Kaleidoscope, Neko, NickSpace, Polyhedra, Qix, SignalHead,
Space2View, SporView, and StepMan (including its image resource).

Native settings panels replace the remaining Gorm inspectors:

- **BouncyClock:** digital/analog style, numbers, clock size, bubble bounce,
  and bounce period.
- **NickSpace:** grid spacing, trail density and length, and palette editing
  (previous/next, add/remove, and a native color well).
- **Polyhedra:** random or any of the five shapes, plus **Kick It!**.
- **SporView:** maximum/starting population, spread, cloud size, initial color
  distribution, and predation. **Apply and Restart** starts a new simulation.

Settings persist across mode changes and launches. The other modules have
no additional inspector settings in their original implementations. This is a
standalone app, not a System Settings `.saver` plug-in or a secure screen lock.
Desktop/full-screen mode uses the display containing the control window.
Additional macOS-built `.InnerSpace` bundles can be placed in
`~/Library/InnerSpace`; GNUstep binaries cannot be loaded by the native app.

## GNUstep

The original GNUstep build and interface files are retained. On GNUstep systems,
run `make` with gnustep-make configured. Modules are bundled with the application;
additional built modules can be copied to `$HOME/GNUstep/Library/InnerSpace`.
On macOS with a GNUstep toolchain, explicitly select that build with:

```sh
make INNERSPACE_PLATFORM=gnustep
```

The menu-bar status item and Dock preference belong to the Cocoa host only;
GNUstep retains its original application menus, Gorm interface, startup, and
module-switching behavior. Session mode restoration is Cocoa-only. No Cocoa
status-item or activation-policy API is compiled by the GNUstep target. A full
GNUstep compile has not been verified in this macOS environment because the
GNUstep toolchain is not installed.

## Notice

The savers `Polyhedra.bproj`, `SporView.bproj`, and `Space2View.bproj` were available
from next-ftp.peak.org with code and source available. The original author assumed
these were in the public domain. Individual source files contain additional
license notices.

## Contact

Gregory Casamento <greg.casamento@gmail.com>
