#include <AppKit/AppKit.h>

typedef enum {
  NekoStateWalking = 0,
  NekoStateSleeping,
  NekoStateWandering
} NekoState;

@interface NekoView : NSView
{
  NSView *animationHostView; // Non-owning; supplied by offscreen rendering hosts.
  NSPoint catPosition;
  NSPoint catVelocity;
  NSPoint targetPosition;
  NSPoint wanderTarget;
  NekoState state;
  int sleepTicks;
  int blinkTicks;
  BOOL facingLeft;
  BOOL saverMode;
}

- (void)oneStep;
- (void)setAnimationHostView:(NSView *)host;

@end
