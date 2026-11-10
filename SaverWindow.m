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

/* Desktop level is only a hint to a window manager, so without one this
   window has to send itself behind the others whenever it is ordered. */
- (void) orderWindow: (NSWindowOrderingMode)place relativeTo: (NSInteger)number
{
  [super orderWindow: place relativeTo: number];
#if !defined(__APPLE__)
  if ([self level] == NSDesktopWindowLevel && place != NSWindowOut)
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

- (BOOL) canBecomeMainWindow
{
  return YES;
}

- (void) hide: (id)sender
{
  // Don't react to hide.  This window cannot be hidden.
}

@end
