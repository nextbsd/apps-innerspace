/* All Rights reserved */

#import <AppKit/AppKit.h>

@interface SaverWindow : NSWindow
{
  id  target;
  SEL action;
}
- (void) setAction: (SEL)action forTarget: (id) target;
@end
