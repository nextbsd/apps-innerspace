#include <AppKit/AppKit.h>

@interface HAL9000View : NSView
{
  double phase;
  unsigned int frameCount;
  NSDictionary *smallAttributes;
  NSDictionary *titleAttributes;
}
- (void)oneStep;
- (void)drawDisplayInRect:(NSRect)rect;
- (void)drawMonitor:(int)index inRect:(NSRect)rect;
- (void)drawGraphic:(int)kind;
- (void)drawHalEyeInRect:(NSRect)rect;
@end

@interface StaticHAL9000View : HAL9000View
@end
