#include <AppKit/AppKit.h>

@interface BouncyClockView : NSView
{
  NSPoint position;
  NSSize clockSize;
  float xVelocity;
  float yVelocity;
  NSString *timeString;
  NSDictionary *textAttributes;
  BOOL analogClock;
  NSView *inspectorView;
  NSMatrix *clockModeMatrix;
}
- (void)oneStep;
- (void)loadDefaults;
- (void)saveClockMode;
- (void)updateClockString;
- (void)updateClockSize;
- (void)keepClockInBounds;
- (void)drawClock;
- (void)drawAnalogClock;
- (void)drawDigitalClock;
- (id)setClockMode:(id)sender;
- (NSView *)inspector:(id)sender;
@end

@interface StaticBouncyClockView : BouncyClockView
{
}
@end
