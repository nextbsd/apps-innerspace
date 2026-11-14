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
The app bundles all 21 modules. Select an animation, then choose
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

Neko uses 32×32 sprite frames rendered at 2× with nearest-neighbor scaling.
Its twelve-frame running cycle follows the mouse and plays more slowly while
wandering in full screen; idle, grooming, and sleeping use the original sheet.
The normalized running asset is `Neko.bproj/neko_running_32.png`; the generated
source is preserved alongside it. To regenerate the normalized asset, run
`python3 Neko.bproj/tools/normalize-running.py` with Pillow installed.

All 21 modules are available, with module selection and speed controls.
The build discovers every `*.bproj` project from its GNUmakefile source and
resource declarations, rather than maintaining a separate macOS module list.
It includes Aquarium, Black, Boink, BouncyClock, Boxes, ConnectionMachine, DictionaryWords, FlyingToasters, HAL9000,
ItJustStopped, Kaleidoscope, Neko, NickSpace, Polyhedra, Qix, SignalHead,
Space2View, SporView, StepMan (including its image resource), SystemStats, and Weather.

Aquarium fills the screen with tropical fish, swaying aquatic plants, gravel,
rocks, rising bubbles, and slowly drifting underwater light. Three fish designs
swim in both directions with animated fins and tails. The scene scales to the
window, with more fish in wider tanks. All artwork is drawn natively, with no
downloads or external assets required. Select **Aquarium** in the module menu
and use the standard speed and Preview/Desktop/Full Screen controls.

ConnectionMachine presents eight matte-black panels with 4,096 red LEDs, inspired
by the Connection Machine's processor-status lights. Six panels map rows to the
computer's logical CPU cores (repeating cores across the array); the remaining
two show network receive and transmit activity. CPU LED duty cycle follows busy
time, while network activity uses a fixed logarithmic scale up to 1 MiB/s.
Counters are sampled every half-second using monotonic time, independently of
the animation-speed slider. The readout shows measured CPU use and KiB/s. The
spatial flicker is a visualization of these measurements, not a trace of
individual instructions or packets. Loopback traffic is excluded; virtual
interfaces may count traffic again. Unsupported or failed readings are labeled
unavailable and their lights fade out. Sampling uses public, unprivileged macOS
APIs or Linux /proc files; it includes InnerSpace's own activity.

SystemStats displays CPU, memory, swap, disk, network, load, uptime, and process
statistics on both Linux and macOS. The panel fades in at a random position,
remains fully visible for 10–15 seconds, then fades out before appearing elsewhere.
Each fade lasts two seconds, with a one-second gap between appearances.
The network row shows download/upload rates; its bar scales combined throughput
against the peak observed during the session (with a minimum scale of 1 KiB/s).
macOS thread counts include only processes
that permit inspection; temperature displays as unavailable because macOS has
no supported public Celsius-reading API.

Weather shows current temperature (°C or °F), humidity, wind speed (km/h), weather
conditions, and the observation/model timestamp, alongside a simplified
world map with a location marker. Select **Weather**, then enter latitude and
longitude in its inspector and choose **Apply and Refresh**, or press Enter in
either coordinate field to apply the values while keeping keyboard focus. Toggle **Use Fahrenheit
(°F)** to switch temperature units immediately; unchecked uses Celsius. This choice
is saved across launches and does not require another weather request. Coordinates persist
across launches; the initial location is New York (40.7128, -74.0060). The map is
a native, offline geographic overview with approximate coastlines, not radar or
street-level mapping.

Weather requests run on a worker queue over HTTPS, refresh every 15 minutes, and
retry after five minutes on failure. DNS and connection setup stay off the UI
thread so applying coordinates does not wait for the network. Responses for
previous locations are ignored after a new location is applied. Failed updates keep the previous reading
with a status message and timestamp; changing location clears it. No API key or
location permission is needed. The module sends the selected coordinates directly
to [Open-Meteo](https://open-meteo.com/en/docs) for model-based current conditions,
requesting Celsius and km/h explicitly. It no longer selects an NWS station:
individual stations can have missing measurements even in a successful response.
The footer identifies Open-Meteo, and successful updates are explicitly labeled.
HTTP and connection errors appear in the status line to help distinguish a failed
request from missing data. Responses missing required measurements are rejected;
a failed refresh preserves the previous complete reading with its timestamp.
Open-Meteo data is provided under [CC BY 4.0](https://open-meteo.com/en/licence);
the free endpoint is for [non-commercial use](https://open-meteo.com/en/terms).

The Weather module can be built independently with `make -C Weather.bproj`.
Its offline regression tests cover response validation, retaining readings on
failure, invalid coordinates, direct provider selection, recovery after errors,
slow-network responsiveness, ignoring superseded requests, Enter-key editing in
both coordinate fields, and rendering. On GNUstep with an X display:

```sh
clang $(gnustep-config --objc-flags) Weather.bproj/WeatherView.m \
  Weather.bproj/Tests/WeatherTests.m -o /tmp/innerspace-weather-tests \
  $(gnustep-config --gui-libs)
/tmp/innerspace-weather-tests
```

Use `--headless` to run only the data and provider checks without an X display.
For GUI checks on a headless system, run with `xvfb-run -a`. It writes a
render sample to `/tmp/innerspace-weather-test.png` and does not use the network.

Native settings panels replace the remaining Gorm inspectors:

- **Boxes:** **Random angles** rotates each new box independently. It is off
  by default, and the setting is saved across launches.
- **Space2View:** star color: White (default), Random, Blue, Red, Blue-white, Yellow, or Orange. Random
  assigns each star its own color; changes apply immediately and persist.
  **Show moving nebulae** adds small procedural gas clouds that move and grow
  in perspective with the stars. Counts use a documented WISE catalog density
  reference; colors and visibility represent enhanced astronomical imaging.
  It is off by default, works offline, and remembers your choice.
  Uncheck **Rotate space view** to disable rotation while keeping outward
  motion. Rotation defaults off for new settings; saved choices are preserved.
  **COSMOS mode** is off by default. Enable it for slow, depth-based travel,
  muted stars, gentle optional rotation, and large diffuse red nebulae with
  dark dust lanes. The red clouds appear independently of the smaller-nebula
  switch. Turning COSMOS off restores the faster, brighter starfield.
  **Use GPU rendering** defaults on. A dedicated OpenGL view renders cached
  cloud textures and batched stars directly; the inspector shows the driver or
  a CPU-fallback reason. Unsupported and recognized software-only drivers
  retain the existing CPU renderer. The GNUstep build requires OpenGL headers
  and libGL (the OpenGL framework on Darwin). COSMOS CPU fallback uses a
  bounded cloud-compositing surface and cached backdrop while keeping stars full
  resolution. Software rendering is capped at 10 fps, with COSMOS clouds updated
  every second frame; compensated motion preserves travel speed. This reduces
  CPU use at the cost of smoothness and one full-size backdrop in memory.
  Hardware OpenGL keeps the requested frame rate.
  A software-only VNC display still uses CPU rendering.
  Oversized module inspectors scroll inside the Controls box so all options
  and renderer status remain accessible.
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

### Kaleidoscope on the GPU

Kaleidoscope draws with OpenGL when the GNUstep backend can make an
`NSOpenGLContext` with a hardware renderer (on NextBSD, a WindowServer with
GPU buffers; see libs-back's `NextBSDOpenGL.h`), and with cairo on the CPU
otherwise (no OpenGL, a software renderer, or a failure while drawing). The
GNUstep build links libGL for it.

The CPU version darkens the whole window by 12% every step and draws the
particles over it, so every disc fades by 0.88 a step. Darkening commutes
with drawing over, so the GPU version draws the same picture from scratch
each frame: the discs of the last 36 steps (after that a disc is below two
levels of 255, where the CPU version's 8-bit fade stops taking anything
away), oldest first over black, each with its colour scaled by
0.88 per step of age. They stay in a vertex buffer, one step's 18 particles
in their 16 mirrored copies at a time, and are drawn as point sprites whose
fragment shader draws the antialiased fill and 1-point outline. There's no
full-window fade pass, no copy of the previous frame and no read-back. The
steps keep the CPU version's 30 ms; between them the newest discs glide
toward the next step's, fading in, so a frame at any rate moves smoothly
while the trails stay as before. Frames have a pixel per backing pixel on
HiDPI screens (`-wantsBestResolutionOpenGLSurface`).

Frames are paced by the display: a module that presents directly can
implement `-setAnimationFrameTarget:action:` (ModuleView.h) and tell the host
when the display is ready for the next frame; Kaleidoscope does so when its
context reports frame completion (WindowServer's frame-done on NextBSD). The
host then draws a frame each time instead of on its timer, which only stays
as a one-second watchdog, and goes back to the timer if the module falls back
to the CPU. With nothing on screen being redrawn, no frames are drawn.

The regression test for the host's side (no display needed):

```sh
clang $(gnustep-config --objc-flags) Tests/DirectRenderingTests.m InnerSpaceController.m SaverWindow.m UtilFunctions.c -o /tmp/innerspace-direct-tests $(gnustep-config --gui-libs) -lX11
/tmp/innerspace-direct-tests
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
