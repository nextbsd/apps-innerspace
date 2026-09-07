#include <AppKit/AppKit.h>

typedef enum {
  NekoStateWalking = 0,
  NekoStateSleeping,
  NekoStateWandering,
  NekoStateSurprised
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
  int surpriseTicks;
  int animationTicks;
  int runningTicks;
  NSImage *spriteSheet;
  NSImage *runningSpriteSheet;
  BOOL facingLeft;
  BOOL saverMode;
}

- (void)oneStep;
- (void)setAnimationHostView:(NSView *)host;

@end
