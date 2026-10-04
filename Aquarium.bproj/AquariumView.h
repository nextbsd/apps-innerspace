#include <AppKit/AppKit.h>

@interface AquariumView : NSView
{
  double elapsed;
}
- (void)oneStep;
@end

@interface StaticAquariumView : AquariumView
@end
