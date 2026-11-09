#import "../InnerSpaceController.h"

@interface TestDirectModule : NSObject
{
@public
  BOOL handlesFrame;
  int directCalls, focusCalls, stepCalls, unlockCalls;
}

- (BOOL)renderAnimationFrame;
- (void)lockFocus;
- (void)unlockFocus;
- (void)oneStep;

@end

@implementation TestDirectModule

- (BOOL)renderAnimationFrame
{
  directCalls++;
  return handlesFrame;
}

- (void)lockFocus
{
  focusCalls++;
}

- (void)unlockFocus
{
  unlockCalls++;
}

- (void)oneStep
{
  stepCalls++;
}

@end

@interface TestPresentationWindow : NSObject
{
@public
  int flushCalls;
}

- (void)flushWindow;
- (void)close;

@end

@implementation TestPresentationWindow

- (void)flushWindow
{
  flushCalls++;
}

- (void)close
{
}

@end

int main(void)
{
  CREATE_AUTORELEASE_POOL(pool);
  InnerSpaceController *controller = [[InnerSpaceController alloc] init];
  TestDirectModule *module = [[TestDirectModule alloc] init];
  TestPresentationWindow *window = [[TestPresentationWindow alloc] init];

  /* Controller owns these allocated objects and releases them during teardown. */
  [controller setValue: module forKey: @"currentModule"];
  [controller setValue: window forKey: @"saverWindow"];
  module->handlesFrame = YES;
  [controller runAnimation: nil];
  if (module->directCalls != 1 || module->focusCalls != 0 || module->stepCalls != 0 || window->flushCalls != 0)
    return 1;
  module->handlesFrame = NO;
  [controller runAnimation: nil];
  if (module->directCalls != 2 || module->focusCalls != 1 || module->stepCalls != 1
      || module->unlockCalls != 1 || window->flushCalls != 1) return 1;
  RELEASE(controller);
  NSLog(@"PASS: direct rendering bypasses AppKit; fallback preserves legacy focus, step, and flush");
  RELEASE(pool);
  return 0;
}
