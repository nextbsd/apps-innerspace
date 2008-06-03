/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "SaverWindow.h"

@implementation SaverWindow

- (void) makeOmnipresent
{
#if defined( GNUSTEP )
  // [self _setOmnipresent: YES];
#endif // GNUSTEP
}

- (void) setAction: (SEL)a forTarget: (id)t
{
  action = a;
  target = t;
}

- (void) keyDown: (NSEvent *)theEvent
{
  if([self level] != NSDesktopWindowLevel)
    {
      [NSApp sendAction: action to: target from: self];
    }
}

- (void) mouseUp: (NSEvent *)theEvent
{
  if([self level] != NSDesktopWindowLevel)
    {
      [NSApp sendAction: action to: target from: self];
    }
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
