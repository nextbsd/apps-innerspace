#include <AppKit/AppKit.h>

@interface BoinkView : NSView
{
  NSPoint ballPosition;
  NSPoint ballVelocity;
  float ballRadius;
  float rotation;
}
- (void)oneStep;
- (void)keepBallInBounds;
- (void)drawBall;
- (void)drawCheckerCellsWithRadius:(float)radius;
@end

@interface StaticBoinkView : BoinkView
{
}
@end
