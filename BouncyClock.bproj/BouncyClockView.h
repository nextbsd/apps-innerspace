#include <AppKit/AppKit.h>

@interface BouncyClockView : NSView
{
  NSPoint position;
  NSSize clockSize;
  float xVelocity;
  float yVelocity;
  float bubbleDistortion;
  float bubbleDistortionVelocity;
  float bubbleDistortionX;
  float bubbleDistortionY;
  NSString *timeString;
  NSDictionary *textAttributes;
  NSDictionary *numberAttributes;
  BOOL analogClock;
  BOOL showNumbers;
  BOOL largeClock;
  BOOL bubbleBounce;
  NSView *inspectorView;
  NSMatrix *clockModeMatrix;
  NSButton *showNumbersButton;
  NSButton *largeClockButton;
  NSButton *bubbleBounceButton;
}
- (void)oneStep;
- (void)loadDefaults;
- (void)saveDefaults;
- (void)updateTextAttributes;
- (void)updateClockString;
- (void)updateClockSize;
- (void)keepClockInBounds;
- (void)drawClock;
- (void)drawUndistortedClock;
- (void)drawAnalogClock;
- (void)drawDigitalClock;
- (id)setClockMode:(id)sender;
- (id)setShowNumbers:(id)sender;
- (id)setLargeClock:(id)sender;
- (id)setBubbleBounce:(id)sender;
- (NSView *)inspector:(id)sender;
@end

@interface StaticBouncyClockView : BouncyClockView
{
}
@end
