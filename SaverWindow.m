/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "SaverWindow.h"

@implementation SaverWindow

- (void) setAction: (SEL)a forTarget: (id)t
{
  action = a;
  target = t;
}


- (void) keyDown: (NSEvent *)theEvent
{
  [NSApp sendAction: action to: target from: self];
}

- (void) mouseUp: (NSEvent *)theEvent
{
  [NSApp sendAction: action to: target from: self];
}

- (BOOL) canBecomeKeyWindow
{
  return YES;
}

- (BOOL) canBecomeMainWindow
{
  return YES;
}

@end
