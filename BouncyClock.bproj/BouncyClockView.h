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
  float bubbleBouncePeriod;
  NSString *timeString;
  NSDictionary *textAttributes;
  NSDictionary *numberAttributes;
  NSDictionary *indicatorAttributes;
  BOOL analogClock;
  BOOL showNumbers;
  BOOL largeClock;
  BOOL bubbleBounce;
  NSView *inspectorView;
  NSMatrix *clockModeMatrix;
  NSButton *showNumbersButton;
  NSButton *largeClockButton;
  NSButton *bubbleBounceButton;
  NSSlider *bubbleBouncePeriodSlider;
  NSTextField *bubbleBouncePeriodField;
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
- (void)drawAmPmIndicator;
- (void)drawAmPmIndicatorAtPoint:(NSPoint)indicatorPoint
		   withAttributes:(NSDictionary *)attributes;
- (id)setClockMode:(id)sender;
- (id)setShowNumbers:(id)sender;
- (id)setLargeClock:(id)sender;
- (id)setBubbleBounce:(id)sender;
- (id)setBubbleBouncePeriod:(id)sender;
- (void)updateBubbleBouncePeriodField;
- (NSView *)inspector:(id)sender;
@end

@interface StaticBouncyClockView : BouncyClockView
{
}
@end
