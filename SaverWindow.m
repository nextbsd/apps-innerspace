/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "SaverWindow.h"
#if !defined(__APPLE__)
#include <GNUstepGUI/GSDisplayServer.h>
#include <X11/Xlib.h>
#endif

@implementation SaverWindow
- (void) setAction: (SEL)a forTarget: (id)t
{
  action = a;
  target = t;
}

- (void) _triggerAction
{
  if([self level] != NSDesktopWindowLevel)
    {
      [NSApp sendAction: action to: target from: self];
    }
}

- (void) keyDown: (NSEvent *)theEvent
{
  [self _triggerAction];
}

- (void) mouseMoved: (NSEvent *)theEvent
{
  [self _triggerAction];
}

- (void) mouseUp: (NSEvent *)theEvent
{
  [self _triggerAction];
}

/* Under X, desktop level is only a hint to a window manager, so without one
   this window has to send itself behind the others whenever it is ordered.
   Other backends (the NextBSD WindowServer) keep desktop-level windows at
   the bottom themselves, and their serverDevice isn't an X Display. */
- (void) orderWindow: (NSWindowOrderingMode)place relativeTo: (NSInteger)number
{
  [super orderWindow: place relativeTo: number];
#if !defined(__APPLE__)
  if ([self level] == NSDesktopWindowLevel && place != NSWindowOut
      && [GSServerForWindow(self) isKindOfClass: NSClassFromString(@"XGServer")])
    {
      Display *display = (Display *)[GSServerForWindow(self) serverDevice];
      XLowerWindow(display, (Window)[self windowRef]);
      XFlush(display);
    }
#endif
}

- (BOOL) canBecomeKeyWindow
{
  return YES;
}

/* Never the main window: it only shows the saver, and in the in-window
   menu style (NBMenuStyle inwindow) GNUstep puts the main menu in every
   window that can become main, which put a menu bar along the top of
   the desktop, behind the other apps' windows and under a top Dock.
   Being key is enough for the keys and clicks that stop the saver. */
- (BOOL) canBecomeMainWindow
{
  return NO;
}

- (void) hide: (id)sender
{
  // Don't react to hide.  This window cannot be hidden.
}

@end
