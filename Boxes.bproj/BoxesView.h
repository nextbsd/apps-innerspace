#include <AppKit/AppKit.h>

@interface BoxesView : NSView
{
  BOOL randomAngles;
  NSView *inspectorView;
}

- (void)oneStep;
- (NSView *)inspector:(id)sender;
- (void)setRandomAngles:(id)sender;

@end

@interface StaticBoxesView : BoxesView
{
}

@end
