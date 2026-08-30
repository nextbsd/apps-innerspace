#include <AppKit/AppKit.h>

#define FlyingToastersCount 14

typedef struct flying_toaster
{
  NSPoint position;
  float speed;
  float drift;
  float scale;
  float phase;
  float flapSpeed;
} FlyingToaster;

@interface FlyingToastersView : NSView
{
  FlyingToaster toasters[FlyingToastersCount];
  float animationPhase;
}
- (void)oneStep;
- (void)resetToaster:(int)index offscreen:(BOOL)offscreen;
- (void)drawToaster:(FlyingToaster *)toaster;
- (void)drawWingWithScale:(float)scale flap:(float)flap mirrored:(BOOL)mirrored;
@end

@interface StaticFlyingToastersView : FlyingToastersView
{
}
@end
