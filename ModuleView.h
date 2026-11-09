#include <AppKit/AppKit.h>

@interface ModuleView : NSView
{
}
// animation methods...
- (void) oneStep;
/* Optional: YES means the module presented directly, without AppKit focus. */
- (BOOL) renderAnimationFrame;
- (NSTimeInterval) animationDelayTime;
/* Optional pacing with motion compensation for reduced drawing frequency. */
- (NSTimeInterval)animationIntervalForRequestedInterval:(NSTimeInterval)interval;
- (void)setAnimationStepScale:(double)scale;
- (void) didLockFocus;

// inspector methods...
- (NSView *) inspector: (id)sender;
- (void) inspectorInstalled;
- (void) inspectorWillBeRemoved;

// window methods...
- (BOOL) useBufferedWindow;
- (BOOL) isBoringScreenSaver;
- (BOOL) ignoreMouseMovement;
- (NSString *) windowTitle;

// notification methods..
- (void) willEnterScreenSaverMode;
- (void) enteredScreenSaverMode;
- (void) willExitScreenSaverMode;
@end
