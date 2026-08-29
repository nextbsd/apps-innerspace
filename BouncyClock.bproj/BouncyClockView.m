#include "BouncyClockView.h"
#include <math.h>

#define BouncyClockClockModeKey @"BouncyClockClockMode"
#define BouncyClockModeDigital @"Digital"
#define BouncyClockModeAnalog  @"Analog"
#define AnalogClockDiameter 150.0

@implementation BouncyClockView

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if(self)
    {
      NSFont *font = [NSFont boldSystemFontOfSize: 64.0];

      textAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
					    font, NSFontAttributeName,
					    [NSColor whiteColor], NSForegroundColorAttributeName,
					    nil];
      timeString = nil;
      inspectorView = nil;
      clockModeMatrix = nil;
      [self loadDefaults];
      position = NSMakePoint(40.0, 40.0);
      xVelocity = 7.0;
      yVelocity = 5.0;
      [self updateClockString];
      [self updateClockSize];
    }
  return self;
}

- (void)dealloc
{
  RELEASE(timeString);
  RELEASE(textAttributes);
  RELEASE(inspectorView);
  RELEASE(clockModeMatrix);
  [super dealloc];
}

- (void)loadDefaults
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSDictionary *defaultValues;
  NSString *clockMode;

  defaultValues = [NSDictionary dictionaryWithObject: BouncyClockModeDigital
					      forKey: BouncyClockClockModeKey];
  [defaults registerDefaults: defaultValues];

  clockMode = [defaults stringForKey: BouncyClockClockModeKey];
  analogClock = [clockMode isEqualToString: BouncyClockModeAnalog];
}

- (void)saveClockMode
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  [defaults setObject: analogClock ? BouncyClockModeAnalog : BouncyClockModeDigital
	       forKey: BouncyClockClockModeKey];
  [defaults synchronize];
}

- (BOOL)useBufferedWindow
{
  return YES;
}

- (BOOL)isOpaque
{
  return YES;
}

- (NSTimeInterval)animationDelayTime
{
  return 0.04;
}

- (NSString *)windowTitle
{
  return @"Bouncy Clock";
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame: frame];
  [self keepClockInBounds];
}

- (void)drawRect:(NSRect)rects
{
  [[NSColor blackColor] set];
  NSRectFill(rects);
  [self drawClock];
}

- (void)updateClockString
{
  NSString *newString = [[NSCalendarDate calendarDate]
			  descriptionWithCalendarFormat: @"%H:%M:%S"];

  if(timeString == nil || ![timeString isEqualToString: newString])
    {
      ASSIGN(timeString, newString);
      [self updateClockSize];
      [self keepClockInBounds];
    }
}

- (void)updateClockSize
{
  if(analogClock)
    {
      clockSize = NSMakeSize(AnalogClockDiameter, AnalogClockDiameter);
    }
  else
    {
      clockSize = [timeString sizeWithAttributes: textAttributes];
    }
}

- (void)keepClockInBounds
{
  NSRect bounds = [self bounds];
  float maxX = bounds.size.width - clockSize.width;
  float maxY = bounds.size.height - clockSize.height;

  if(maxX < 0.0)
    {
      maxX = 0.0;
    }
  if(maxY < 0.0)
    {
      maxY = 0.0;
    }

  if(position.x > maxX)
    {
      position.x = maxX;
    }
  if(position.y > maxY)
    {
      position.y = maxY;
    }
  if(position.x < 0.0)
    {
      position.x = 0.0;
    }
  if(position.y < 0.0)
    {
      position.y = 0.0;
    }
}

- (void)drawClock
{
  if(analogClock)
    {
      [self drawAnalogClock];
    }
  else
    {
      [self drawDigitalClock];
    }
}

- (void)drawDigitalClock
{
  [timeString drawAtPoint: position withAttributes: textAttributes];
}

- (void)drawAnalogClock
{
  NSCalendarDate *date = [NSCalendarDate calendarDate];
  float radius = clockSize.width / 2.0;
  NSPoint center = NSMakePoint(position.x + radius, position.y + radius);
  int hour = [date hourOfDay] % 12;
  int minute = [date minuteOfHour];
  int second = [date secondOfMinute];
  float hourAngle = ((float)hour + ((float)minute / 60.0)) * ((float)M_PI / 6.0);
  float minuteAngle = ((float)minute + ((float)second / 60.0)) * ((float)M_PI / 30.0);
  float secondAngle = (float)second * ((float)M_PI / 30.0);
  int tick;

  [[NSColor whiteColor] set];
  {
    NSBezierPath *face = [NSBezierPath bezierPathWithOvalInRect:
			  NSMakeRect(position.x + 2.0, position.y + 2.0,
				     clockSize.width - 4.0, clockSize.height - 4.0)];
    [face setLineWidth: 3.0];
    [face stroke];
  }

  for(tick = 0; tick < 60; tick++)
    {
      float angle = (float)tick * ((float)M_PI / 30.0);
      float outerRadius = radius - 8.0;
      float innerRadius = outerRadius - ((tick % 5) == 0 ? 12.0 : 5.0);
      NSBezierPath *tickPath = [NSBezierPath bezierPath];

      [tickPath moveToPoint: NSMakePoint(center.x + sin(angle) * innerRadius,
					 center.y + cos(angle) * innerRadius)];
      [tickPath lineToPoint: NSMakePoint(center.x + sin(angle) * outerRadius,
					 center.y + cos(angle) * outerRadius)];
      [tickPath setLineWidth: ((tick % 5) == 0 ? 2.0 : 1.0)];
      [tickPath stroke];
    }

  {
    NSBezierPath *hourHand = [NSBezierPath bezierPath];
    [hourHand moveToPoint: center];
    [hourHand lineToPoint: NSMakePoint(center.x + sin(hourAngle) * (radius * 0.45),
				       center.y + cos(hourAngle) * (radius * 0.45))];
    [hourHand setLineWidth: 5.0];
    [hourHand stroke];
  }

  {
    NSBezierPath *minuteHand = [NSBezierPath bezierPath];
    [minuteHand moveToPoint: center];
    [minuteHand lineToPoint: NSMakePoint(center.x + sin(minuteAngle) * (radius * 0.68),
					 center.y + cos(minuteAngle) * (radius * 0.68))];
    [minuteHand setLineWidth: 3.0];
    [minuteHand stroke];
  }

  [[NSColor redColor] set];
  {
    NSBezierPath *secondHand = [NSBezierPath bezierPath];
    [secondHand moveToPoint: center];
    [secondHand lineToPoint: NSMakePoint(center.x + sin(secondAngle) * (radius * 0.72),
					 center.y + cos(secondAngle) * (radius * 0.72))];
    [secondHand setLineWidth: 1.0];
    [secondHand stroke];
  }

  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(center.x - 3.0, center.y - 3.0, 6.0, 6.0));
}

- (void)oneStep
{
  NSRect bounds = [self bounds];
  float maxX;
  float maxY;

  [[NSColor blackColor] set];
  NSRectFill(bounds);

  [self updateClockString];

  maxX = bounds.size.width - clockSize.width;
  maxY = bounds.size.height - clockSize.height;
  if(maxX < 0.0)
    {
      maxX = 0.0;
    }
  if(maxY < 0.0)
    {
      maxY = 0.0;
    }

  position.x += xVelocity;
  position.y += yVelocity;

  if(position.x <= 0.0)
    {
      position.x = 0.0;
      xVelocity = fabs(xVelocity);
    }
  else if(position.x >= maxX)
    {
      position.x = maxX;
      xVelocity = -fabs(xVelocity);
    }

  if(position.y <= 0.0)
    {
      position.y = 0.0;
      yVelocity = fabs(yVelocity);
    }
  else if(position.y >= maxY)
    {
      position.y = maxY;
      yVelocity = -fabs(yVelocity);
    }

  [self drawClock];
}

- (id)setClockMode:(id)sender
{
  analogClock = ([sender selectedRow] == 1);
  [self updateClockSize];
  [self keepClockInBounds];
  [self saveClockMode];
  [self setNeedsDisplay: YES];
  return self;
}

- (NSView *)inspector:(id)sender
{
  if(inspectorView == nil)
    {
      NSRect labelFrame = NSMakeRect(12.0, 58.0, 180.0, 20.0);
      NSRect matrixFrame = NSMakeRect(12.0, 12.0, 180.0, 44.0);
      NSTextField *label;
      NSButtonCell *prototype;

      inspectorView = [[NSView alloc] initWithFrame: NSMakeRect(0.0, 0.0, 220.0, 90.0)];

      label = [[NSTextField alloc] initWithFrame: labelFrame];
      [label setStringValue: @"Clock style"];
      [label setEditable: NO];
      [label setSelectable: NO];
      [label setBordered: NO];
      [label setDrawsBackground: NO];
      [inspectorView addSubview: label];
      RELEASE(label);

      prototype = [[NSButtonCell alloc] initTextCell: @""];
      [prototype setButtonType: NSRadioButton];
      clockModeMatrix = [[NSMatrix alloc] initWithFrame: matrixFrame
						   mode: NSRadioModeMatrix
					      prototype: prototype
					   numberOfRows: 2
					numberOfColumns: 1];
      RELEASE(prototype);

      [[clockModeMatrix cellAtRow: 0 column: 0] setTitle: @"Digital"];
      [[clockModeMatrix cellAtRow: 1 column: 0] setTitle: @"Analog"];
      [clockModeMatrix setTarget: self];
      [clockModeMatrix setAction: @selector(setClockMode:)];
      [clockModeMatrix selectCellAtRow: analogClock ? 1 : 0 column: 0];
      [inspectorView addSubview: clockModeMatrix];
    }

  return inspectorView;
}

@end

@implementation StaticBouncyClockView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect: rects];
}
@end
