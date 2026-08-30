#include "BouncyClockView.h"
#include <math.h>

#define BouncyClockClockModeKey @"BouncyClockClockMode"
#define BouncyClockShowNumbersKey @"BouncyClockShowNumbers"
#define BouncyClockLargeClockKey @"BouncyClockLargeClock"
#define BouncyClockBubbleBounceKey @"BouncyClockBubbleBounce"
#define BouncyClockBubbleBouncePeriodKey @"BouncyClockBubbleBouncePeriod"
#define BouncyClockModeDigital @"Digital"
#define BouncyClockModeAnalog  @"Analog"
#define NormalAnalogClockDiameter 150.0
#define LargeAnalogClockDiameter 240.0
#define NormalDigitalFontSize 64.0
#define LargeDigitalFontSize 96.0
#define NormalNumberFontSize 14.0
#define LargeNumberFontSize 22.0
#define NormalIndicatorFontSize 18.0
#define LargeIndicatorFontSize 28.0
#define IndicatorGap 4.0
#define BubbleSpringStiffness 0.42
#define BubbleSpringDamping 0.68
#define BubbleBouncePeriodMinimum 1.0
#define BubbleBouncePeriodMaximum 4.0

@implementation BouncyClockView

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if(self)
    {
      timeString = nil;
      textAttributes = nil;
      numberAttributes = nil;
      indicatorAttributes = nil;
      inspectorView = nil;
      clockModeMatrix = nil;
      showNumbersButton = nil;
      largeClockButton = nil;
      bubbleBounceButton = nil;
      bubbleBouncePeriodSlider = nil;
      bubbleBouncePeriodField = nil;
      [self loadDefaults];
      [self updateTextAttributes];
      position = NSMakePoint(40.0, 40.0);
      xVelocity = 7.0;
      yVelocity = 5.0;
      bubbleDistortion = 0.0;
      bubbleDistortionVelocity = 0.0;
      bubbleDistortionX = 0.0;
      bubbleDistortionY = 0.0;
      [self updateClockString];
      [self updateClockSize];
    }
  return self;
}

- (void)dealloc
{
  RELEASE(timeString);
  RELEASE(textAttributes);
  RELEASE(numberAttributes);
  RELEASE(indicatorAttributes);
  RELEASE(inspectorView);
  RELEASE(clockModeMatrix);
  RELEASE(showNumbersButton);
  RELEASE(largeClockButton);
  RELEASE(bubbleBounceButton);
  RELEASE(bubbleBouncePeriodSlider);
  RELEASE(bubbleBouncePeriodField);
  [super dealloc];
}

- (void)loadDefaults
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSDictionary *defaultValues;
  NSString *clockMode;

  defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
				  BouncyClockModeDigital, BouncyClockClockModeKey,
				  [NSNumber numberWithBool: NO], BouncyClockShowNumbersKey,
				  [NSNumber numberWithBool: NO], BouncyClockLargeClockKey,
				  [NSNumber numberWithBool: NO], BouncyClockBubbleBounceKey,
				  [NSNumber numberWithFloat: BubbleBouncePeriodMinimum], BouncyClockBubbleBouncePeriodKey,
				  nil];
  [defaults registerDefaults: defaultValues];

  clockMode = [defaults stringForKey: BouncyClockClockModeKey];
  analogClock = [clockMode isEqualToString: BouncyClockModeAnalog];
  showNumbers = [defaults boolForKey: BouncyClockShowNumbersKey];
  largeClock = [defaults boolForKey: BouncyClockLargeClockKey];
  bubbleBounce = [defaults boolForKey: BouncyClockBubbleBounceKey];
  bubbleBouncePeriod = [defaults floatForKey: BouncyClockBubbleBouncePeriodKey];
  if(bubbleBouncePeriod < BubbleBouncePeriodMinimum)
    {
      bubbleBouncePeriod = BubbleBouncePeriodMinimum;
    }
  if(bubbleBouncePeriod > BubbleBouncePeriodMaximum)
    {
      bubbleBouncePeriod = BubbleBouncePeriodMaximum;
    }
}

- (void)saveDefaults
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  [defaults setObject: analogClock ? BouncyClockModeAnalog : BouncyClockModeDigital
	       forKey: BouncyClockClockModeKey];
  [defaults setBool: showNumbers forKey: BouncyClockShowNumbersKey];
  [defaults setBool: largeClock forKey: BouncyClockLargeClockKey];
  [defaults setBool: bubbleBounce forKey: BouncyClockBubbleBounceKey];
  [defaults setFloat: bubbleBouncePeriod forKey: BouncyClockBubbleBouncePeriodKey];
  [defaults synchronize];
}

- (void)updateTextAttributes
{
  NSFont *textFont = [NSFont boldSystemFontOfSize:
			       largeClock ? LargeDigitalFontSize : NormalDigitalFontSize];
  NSFont *numberFont = [NSFont boldSystemFontOfSize:
				 largeClock ? LargeNumberFontSize : NormalNumberFontSize];
  NSFont *indicatorFont = [NSFont boldSystemFontOfSize:
				    largeClock ? LargeIndicatorFontSize : NormalIndicatorFontSize];
  NSDictionary *newTextAttributes;
  NSDictionary *newNumberAttributes;
  NSDictionary *newIndicatorAttributes;

  newTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				       textFont, NSFontAttributeName,
				       [NSColor whiteColor], NSForegroundColorAttributeName,
				       nil];
  newNumberAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
					 numberFont, NSFontAttributeName,
					 [NSColor blackColor], NSForegroundColorAttributeName,
					 nil];
  newIndicatorAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
					    indicatorFont, NSFontAttributeName,
					    [NSColor whiteColor], NSForegroundColorAttributeName,
					    nil];

  ASSIGN(textAttributes, newTextAttributes);
  ASSIGN(numberAttributes, newNumberAttributes);
  ASSIGN(indicatorAttributes, newIndicatorAttributes);
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
  NSSize indicatorSize = [@"PM" sizeWithAttributes: indicatorAttributes];
  float indicatorHeight = indicatorSize.height + IndicatorGap;

  if(analogClock)
    {
      float diameter = largeClock ? LargeAnalogClockDiameter : NormalAnalogClockDiameter;

      clockSize = NSMakeSize(diameter, diameter);
    }
  else
    {
      NSSize timeSize = [timeString sizeWithAttributes: textAttributes];

      clockSize = NSMakeSize(MAX(timeSize.width, indicatorSize.width),
			     timeSize.height + indicatorHeight);
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
  if(bubbleBounce && fabs(bubbleDistortion) > 0.01)
    {
      NSAffineTransform *transform = [NSAffineTransform transform];
      float centerX = position.x + (clockSize.width / 2.0);
      float centerY = position.y + (clockSize.height / 2.0);
      float squeeze = 1.0 - (0.20 * bubbleDistortion);
      float bulge = 1.0 + (0.24 * bubbleDistortion);
      float xScale = 1.0;
      float yScale = 1.0;

      if(bubbleDistortionX != 0.0)
	{
	  xScale = squeeze;
	  yScale = bulge;
	}
      if(bubbleDistortionY != 0.0)
	{
	  xScale = (xScale == 1.0) ? bulge : ((xScale + bulge) / 2.0);
	  yScale = squeeze;
	}

      [NSGraphicsContext saveGraphicsState];
      [transform translateXBy: centerX yBy: centerY];
      [transform scaleXBy: xScale yBy: yScale];
      [transform translateXBy: -centerX yBy: -centerY];
      [transform concat];
      [self drawUndistortedClock];
      [NSGraphicsContext restoreGraphicsState];
    }
  else
    {
      [self drawUndistortedClock];
    }
}

- (void)drawUndistortedClock
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
  NSSize timeSize = [timeString sizeWithAttributes: textAttributes];
  NSSize indicatorSize = [@"PM" sizeWithAttributes: indicatorAttributes];

  [timeString drawAtPoint: NSMakePoint(position.x + ((clockSize.width - timeSize.width) / 2.0),
				       position.y + indicatorSize.height + IndicatorGap)
	   withAttributes: textAttributes];
  [self drawAmPmIndicator];
}

- (void)drawAnalogClock
{
  NSCalendarDate *date = [NSCalendarDate calendarDate];
  float clockDiameter = largeClock ? LargeAnalogClockDiameter : NormalAnalogClockDiameter;
  float radius = clockDiameter / 2.0;
  float clockBottom = position.y;
  NSPoint center = NSMakePoint(position.x + radius, clockBottom + radius);
  int hour = [date hourOfDay] % 12;
  int minute = [date minuteOfHour];
  int second = [date secondOfMinute];
  float hourAngle = ((float)hour + ((float)minute / 60.0)) * ((float)M_PI / 6.0);
  float minuteAngle = ((float)minute + ((float)second / 60.0)) * ((float)M_PI / 30.0);
  float secondAngle = (float)second * ((float)M_PI / 30.0);
  float scale = clockDiameter / NormalAnalogClockDiameter;
  int tick;

  {
    NSBezierPath *face = [NSBezierPath bezierPathWithOvalInRect:
			  NSMakeRect(position.x + (2.0 * scale),
				     clockBottom + (2.0 * scale),
				     clockDiameter - (4.0 * scale),
				     clockDiameter - (4.0 * scale))];

    [[NSColor whiteColor] set];
    [face fill];
    [[NSColor colorWithCalibratedRed: 0.35 green: 0.0 blue: 0.0 alpha: 1.0] set];
    [face setLineWidth: 3.0 * scale];
    [face stroke];
  }

  for(tick = 0; tick < 60; tick++)
    {
      float angle = (float)tick * ((float)M_PI / 30.0);
      float outerRadius = radius - (8.0 * scale);
      float innerRadius = outerRadius - (((tick % 5) == 0 ? 12.0 : 5.0) * scale);
      NSBezierPath *tickPath = [NSBezierPath bezierPath];

      [tickPath moveToPoint: NSMakePoint(center.x + sin(angle) * innerRadius,
					 center.y + cos(angle) * innerRadius)];
      [tickPath lineToPoint: NSMakePoint(center.x + sin(angle) * outerRadius,
					 center.y + cos(angle) * outerRadius)];
      [((tick % 5) == 0 ? [NSColor darkGrayColor] : [NSColor blackColor]) set];
      [tickPath setLineWidth: ((tick % 5) == 0 ? 2.0 : 1.0) * scale];
      [tickPath stroke];
    }

  if(showNumbers)
    {
      int number;

      for(number = 1; number <= 12; number++)
	{
	  NSString *numberString = [NSString stringWithFormat: @"%d", number];
	  NSSize numberSize = [numberString sizeWithAttributes: numberAttributes];
	  float angle = (float)number * ((float)M_PI / 6.0);
	  float numberRadius = radius - (31.0 * scale);
	  NSPoint numberPoint;

	  numberPoint = NSMakePoint(center.x + sin(angle) * numberRadius - (numberSize.width / 2.0),
				    center.y + cos(angle) * numberRadius - (numberSize.height / 2.0));
	  [numberString drawAtPoint: numberPoint withAttributes: numberAttributes];
	}
    }

  {
    [[NSColor blackColor] set];
    NSBezierPath *hourHand = [NSBezierPath bezierPath];
    [hourHand moveToPoint: center];
    [hourHand lineToPoint: NSMakePoint(center.x + sin(hourAngle) * (radius * 0.45),
				       center.y + cos(hourAngle) * (radius * 0.45))];
    [hourHand setLineWidth: 5.0 * scale];
    [hourHand stroke];
  }

  {
    NSBezierPath *minuteHand = [NSBezierPath bezierPath];
    [minuteHand moveToPoint: center];
    [minuteHand lineToPoint: NSMakePoint(center.x + sin(minuteAngle) * (radius * 0.68),
					 center.y + cos(minuteAngle) * (radius * 0.68))];
    [minuteHand setLineWidth: 3.0 * scale];
    [minuteHand stroke];
  }

  [[NSColor redColor] set];
  {
    NSBezierPath *secondHand = [NSBezierPath bezierPath];
    [secondHand moveToPoint: center];
    [secondHand lineToPoint: NSMakePoint(center.x + sin(secondAngle) * (radius * 0.72),
					 center.y + cos(secondAngle) * (radius * 0.72))];
    [secondHand setLineWidth: 1.0 * scale];
    [secondHand stroke];
  }

  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(center.x - (3.0 * scale), center.y - (3.0 * scale),
			6.0 * scale, 6.0 * scale));

  {
    NSString *indicatorString = ([date hourOfDay] < 12) ? @"AM" : @"PM";
    NSDictionary *blackIndicatorAttributes;
    NSSize indicatorSize;
    NSPoint indicatorPoint;

    blackIndicatorAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
					     [indicatorAttributes objectForKey: NSFontAttributeName], NSFontAttributeName,
					     [NSColor blackColor], NSForegroundColorAttributeName,
					     nil];
    indicatorSize = [indicatorString sizeWithAttributes: blackIndicatorAttributes];
    indicatorPoint = NSMakePoint(center.x - (indicatorSize.width / 2.0),
				 center.y - indicatorSize.height - (8.0 * scale));
    [self drawAmPmIndicatorAtPoint: indicatorPoint
		    withAttributes: blackIndicatorAttributes];
  }
}

- (void)drawAmPmIndicator
{
  NSCalendarDate *date = [NSCalendarDate calendarDate];
  NSString *indicatorString = ([date hourOfDay] < 12) ? @"AM" : @"PM";
  NSSize indicatorSize = [indicatorString sizeWithAttributes: indicatorAttributes];
  NSPoint indicatorPoint;

  indicatorPoint = NSMakePoint(position.x + ((clockSize.width - indicatorSize.width) / 2.0),
			       position.y);
  [self drawAmPmIndicatorAtPoint: indicatorPoint
		  withAttributes: indicatorAttributes];
}

- (void)drawAmPmIndicatorAtPoint:(NSPoint)indicatorPoint
		   withAttributes:(NSDictionary *)attributes
{
  NSCalendarDate *date = [NSCalendarDate calendarDate];
  NSString *indicatorString = ([date hourOfDay] < 12) ? @"AM" : @"PM";

  [indicatorString drawAtPoint: indicatorPoint withAttributes: attributes];
}

- (void)oneStep
{
  NSRect bounds = [self bounds];
  float maxX;
  float maxY;
  float hitX = 0.0;
  float hitY = 0.0;

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
      hitX = -1.0;
    }
  else if(position.x >= maxX)
    {
      position.x = maxX;
      xVelocity = -fabs(xVelocity);
      hitX = 1.0;
    }

  if(position.y <= 0.0)
    {
      position.y = 0.0;
      yVelocity = fabs(yVelocity);
      hitY = -1.0;
    }
  else if(position.y >= maxY)
    {
      position.y = maxY;
      yVelocity = -fabs(yVelocity);
      hitY = 1.0;
    }

  if(bubbleBounce && (hitX != 0.0 || hitY != 0.0))
    {
      bubbleDistortionX = hitX;
      bubbleDistortionY = hitY;
      bubbleDistortion = 1.0;
      bubbleDistortionVelocity = 0.0;
    }
  else if(bubbleDistortion != 0.0 || bubbleDistortionVelocity != 0.0)
    {
      float step = 1.0 / bubbleBouncePeriod;

      bubbleDistortionVelocity -= bubbleDistortion * BubbleSpringStiffness * step;
      bubbleDistortionVelocity *= pow(BubbleSpringDamping, step);
      bubbleDistortion += bubbleDistortionVelocity * step;
      if(fabs(bubbleDistortion) <= 0.01 && fabs(bubbleDistortionVelocity) <= 0.01)
	{
	  bubbleDistortion = 0.0;
	  bubbleDistortionVelocity = 0.0;
	  bubbleDistortionX = 0.0;
	  bubbleDistortionY = 0.0;
	}
    }

  [self drawClock];
}

- (id)setClockMode:(id)sender
{
  analogClock = ([sender selectedRow] == 1);
  [self updateClockSize];
  [self keepClockInBounds];
  [self saveDefaults];
  [self setNeedsDisplay: YES];
  return self;
}

- (id)setShowNumbers:(id)sender
{
  showNumbers = ([sender state] == NSOnState);
  [self saveDefaults];
  [self setNeedsDisplay: YES];
  return self;
}

- (id)setLargeClock:(id)sender
{
  largeClock = ([sender state] == NSOnState);
  [self updateTextAttributes];
  [self updateClockSize];
  [self keepClockInBounds];
  [self saveDefaults];
  [self setNeedsDisplay: YES];
  return self;
}

- (id)setBubbleBounce:(id)sender
{
  bubbleBounce = ([sender state] == NSOnState);
  if(bubbleBouncePeriodSlider != nil)
    {
      [bubbleBouncePeriodSlider setEnabled: bubbleBounce];
    }
  if(bubbleBouncePeriodField != nil)
    {
      [bubbleBouncePeriodField setEnabled: bubbleBounce];
    }
  if(!bubbleBounce)
    {
      bubbleDistortion = 0.0;
      bubbleDistortionVelocity = 0.0;
      bubbleDistortionX = 0.0;
      bubbleDistortionY = 0.0;
    }
  [self saveDefaults];
  [self setNeedsDisplay: YES];
  return self;
}

- (id)setBubbleBouncePeriod:(id)sender
{
  bubbleBouncePeriod = [sender floatValue];
  if(bubbleBouncePeriod < BubbleBouncePeriodMinimum)
    {
      bubbleBouncePeriod = BubbleBouncePeriodMinimum;
    }
  if(bubbleBouncePeriod > BubbleBouncePeriodMaximum)
    {
      bubbleBouncePeriod = BubbleBouncePeriodMaximum;
    }
  if(bubbleBouncePeriodSlider != nil)
    {
      [bubbleBouncePeriodSlider setFloatValue: bubbleBouncePeriod];
    }
  [self updateBubbleBouncePeriodField];
  [self saveDefaults];
  return self;
}

- (void)updateBubbleBouncePeriodField
{
  if(bubbleBouncePeriodField != nil)
    {
      [bubbleBouncePeriodField setStringValue:
				 [NSString stringWithFormat: @"%.1fs", bubbleBouncePeriod]];
    }
}

- (NSView *)inspector:(id)sender
{
  if(inspectorView == nil)
    {
      NSRect labelFrame = NSMakeRect(12.0, 170.0, 180.0, 20.0);
      NSRect matrixFrame = NSMakeRect(12.0, 124.0, 180.0, 44.0);
      NSTextField *label;
      NSTextField *periodLabel;
      NSButtonCell *prototype;

      inspectorView = [[NSView alloc] initWithFrame: NSMakeRect(0.0, 0.0, 220.0, 202.0)];

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

      showNumbersButton = [[NSButton alloc] initWithFrame: NSMakeRect(12.0, 96.0, 180.0, 22.0)];
      [showNumbersButton setButtonType: NSSwitchButton];
      [showNumbersButton setTitle: @"Show numbers"];
      [showNumbersButton setState: showNumbers ? NSOnState : NSOffState];
      [showNumbersButton setTarget: self];
      [showNumbersButton setAction: @selector(setShowNumbers:)];
      [inspectorView addSubview: showNumbersButton];

      largeClockButton = [[NSButton alloc] initWithFrame: NSMakeRect(12.0, 72.0, 180.0, 22.0)];
      [largeClockButton setButtonType: NSSwitchButton];
      [largeClockButton setTitle: @"Large clock"];
      [largeClockButton setState: largeClock ? NSOnState : NSOffState];
      [largeClockButton setTarget: self];
      [largeClockButton setAction: @selector(setLargeClock:)];
      [inspectorView addSubview: largeClockButton];

      bubbleBounceButton = [[NSButton alloc] initWithFrame: NSMakeRect(12.0, 48.0, 180.0, 22.0)];
      [bubbleBounceButton setButtonType: NSSwitchButton];
      [bubbleBounceButton setTitle: @"Bubble bounce"];
      [bubbleBounceButton setState: bubbleBounce ? NSOnState : NSOffState];
      [bubbleBounceButton setTarget: self];
      [bubbleBounceButton setAction: @selector(setBubbleBounce:)];
      [inspectorView addSubview: bubbleBounceButton];

      periodLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(12.0, 26.0, 180.0, 18.0)];
      [periodLabel setStringValue: @"Bounce period"];
      [periodLabel setEditable: NO];
      [periodLabel setSelectable: NO];
      [periodLabel setBordered: NO];
      [periodLabel setDrawsBackground: NO];
      [inspectorView addSubview: periodLabel];
      RELEASE(periodLabel);

      bubbleBouncePeriodField = [[NSTextField alloc] initWithFrame: NSMakeRect(158.0, 26.0, 44.0, 18.0)];
      [bubbleBouncePeriodField setEditable: NO];
      [bubbleBouncePeriodField setSelectable: NO];
      [bubbleBouncePeriodField setBordered: NO];
      [bubbleBouncePeriodField setDrawsBackground: NO];
      [bubbleBouncePeriodField setAlignment: NSRightTextAlignment];
      [bubbleBouncePeriodField setEnabled: bubbleBounce];
      [inspectorView addSubview: bubbleBouncePeriodField];

      bubbleBouncePeriodSlider = [[NSSlider alloc] initWithFrame: NSMakeRect(12.0, 6.0, 190.0, 20.0)];
      [bubbleBouncePeriodSlider setMinValue: BubbleBouncePeriodMinimum];
      [bubbleBouncePeriodSlider setMaxValue: BubbleBouncePeriodMaximum];
      [bubbleBouncePeriodSlider setFloatValue: bubbleBouncePeriod];
      [bubbleBouncePeriodSlider setContinuous: YES];
      [bubbleBouncePeriodSlider setEnabled: bubbleBounce];
      [bubbleBouncePeriodSlider setTarget: self];
      [bubbleBouncePeriodSlider setAction: @selector(setBubbleBouncePeriod:)];
      [inspectorView addSubview: bubbleBouncePeriodSlider];
      [self updateBubbleBouncePeriodField];
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
