#include "SignalHeadView.h"
#include <math.h>
#include <stdlib.h>
#include <time.h>

#define TWO_PI 6.28318530717958647692
#define RAND_FLOAT ((float)rand() / (float)RAND_MAX)

@implementation SignalHeadView

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if(self)
    {
      srand((unsigned int)time(NULL));
      phase = RAND_FLOAT * TWO_PI;
      blinkPhase = RAND_FLOAT * TWO_PI;
      mouthPhase = RAND_FLOAT * TWO_PI;
      jitterPhase = 0.0;
      gridDrift = 0.0;
      captionIndex = 0;
      captionHold = 0;
      captionAttributes = nil;
      smallCaptionAttributes = nil;
      [self buildCaptions];
      [self updateCaptionAttributes];
    }
  return self;
}

- (void)dealloc
{
  int i;

  for(i = 0; i < SignalHeadCaptionCount; i++)
    {
      RELEASE(captions[i]);
    }
  RELEASE(captionAttributes);
  RELEASE(smallCaptionAttributes);
  [super dealloc];
}

- (void)buildCaptions
{
  captions[0] = RETAIN(@"SIGNAL LOCK");
  captions[1] = RETAIN(@"PLEASE STAND BY");
  captions[2] = RETAIN(@"CHANNEL DRIFT");
  captions[3] = RETAIN(@"SYNC PULSE");
  captions[4] = RETAIN(@"LIVE FROM NOWHERE");
  captions[5] = RETAIN(@"HELLO VIEWER");
}

- (void)updateCaptionAttributes
{
  NSDictionary *newCaptionAttributes;
  NSDictionary *newSmallCaptionAttributes;

  newCaptionAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
			  [NSFont boldSystemFontOfSize: 28.0], NSFontAttributeName,
			  [NSColor colorWithCalibratedRed: 0.10 green: 1.0 blue: 0.88 alpha: 1.0],
			  NSForegroundColorAttributeName,
			  nil];
  newSmallCaptionAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
			       [NSFont boldSystemFontOfSize: 12.0], NSFontAttributeName,
			       [NSColor colorWithCalibratedRed: 0.95 green: 0.18 blue: 0.42 alpha: 1.0],
			       NSForegroundColorAttributeName,
			       nil];

  ASSIGN(captionAttributes, newCaptionAttributes);
  ASSIGN(smallCaptionAttributes, newSmallCaptionAttributes);
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
  return @"Signal Head";
}

- (void)drawRect:(NSRect)rects
{
  NSRect bounds = [self bounds];

  [[NSColor blackColor] set];
  NSRectFill(rects);
  [self drawBackdropInBounds: bounds];
  [self drawHeadInBounds: bounds];
  [self drawCaptionInBounds: bounds];
  [self drawScanlinesInBounds: bounds];
}

- (void)oneStep
{
  phase += 0.075;
  blinkPhase += 0.115;
  mouthPhase += 0.42;
  jitterPhase += 0.23;
  gridDrift += 1.2;

  captionHold++;
  if(captionHold > 70)
    {
      captionHold = 0;
      captionIndex = (captionIndex + 1 + (rand() % 2)) % SignalHeadCaptionCount;
    }

  [self setNeedsDisplay: YES];
}

- (void)drawBackdropInBounds:(NSRect)bounds
{
  NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
  float horizon = bounds.size.height * 0.38;
  float vanishingY = bounds.size.height * 0.60;
  float spacing = 24.0;
  int i;

  [[NSColor colorWithCalibratedRed: 0.015 green: 0.02 blue: 0.035 alpha: 1.0] set];
  NSRectFill(bounds);

  [[NSColor colorWithCalibratedRed: 0.02 green: 0.35 blue: 0.35 alpha: 0.55] set];
  for(i = -18; i <= 18; i++)
    {
      NSBezierPath *ray = [NSBezierPath bezierPath];
      float x = center.x + (i * spacing);

      [ray moveToPoint: NSMakePoint(center.x, vanishingY)];
      [ray lineToPoint: NSMakePoint(x + sinf(phase + i) * 8.0, 0.0)];
      [ray setLineWidth: 1.0];
      [ray stroke];
    }

  for(i = 0; i < 18; i++)
    {
      NSBezierPath *line = [NSBezierPath bezierPath];
      float t = (float)i / 17.0;
      float y = horizon * t * t;
      float alpha = 0.16 + (t * 0.34);

      [[NSColor colorWithCalibratedRed: 0.00 green: 0.62 blue: 0.70 alpha: alpha] set];
      [line moveToPoint: NSMakePoint(0.0, fmodf(y + gridDrift, horizon))];
      [line lineToPoint: NSMakePoint(bounds.size.width, fmodf(y + gridDrift, horizon))];
      [line setLineWidth: 1.0];
      [line stroke];
    }

  [[NSColor colorWithCalibratedRed: 0.05 green: 0.08 blue: 0.13 alpha: 0.82] set];
  NSRectFillUsingOperation(NSMakeRect(0.0, horizon, bounds.size.width,
				      bounds.size.height - horizon),
			   NSCompositeSourceOver);
}

- (void)drawScanlinesInBounds:(NSRect)bounds
{
  float y;

  [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.18] set];
  for(y = 0.0; y < bounds.size.height; y += 4.0)
    {
      NSRectFillUsingOperation(NSMakeRect(0.0, y, bounds.size.width, 1.0),
			       NSCompositeSourceOver);
    }

  if(((int)(phase * 10.0) % 23) == 0)
    {
      [[NSColor colorWithCalibratedRed: 0.10 green: 1.0 blue: 0.88 alpha: 0.18] set];
      NSRectFillUsingOperation(NSMakeRect(0.0,
					  fmodf(phase * 53.0, bounds.size.height),
					  bounds.size.width,
					  12.0),
			       NSCompositeSourceOver);
    }
}

- (void)drawHeadInBounds:(NSRect)bounds
{
  float span = bounds.size.width < bounds.size.height
    ? bounds.size.width
    : bounds.size.height;
  float scale = span / 390.0;
  NSPoint center;

  if(scale < 0.55)
    {
      scale = 0.55;
    }

  center = NSMakePoint(NSMidX(bounds) + sinf(phase * 1.6) * 9.0 * scale,
		       NSMidY(bounds) + 18.0 * scale + sinf(phase) * 6.0 * scale);

  [self drawJitterBandsAtCenter: center scale: scale];
  [self drawWireHeadAtCenter: center scale: scale];
}

- (void)drawWireHeadAtCenter:(NSPoint)center scale:(float)scale
{
  NSBezierPath *neck;
  NSBezierPath *head;
  NSBezierPath *jaw;
  NSBezierPath *visor;
  NSBezierPath *mouth;
  NSBezierPath *nose;
  NSBezierPath *shine;
  float blink = fabs(sinf(blinkPhase));
  float mouthOpen = 5.0 + (14.0 * fabs(sinf(mouthPhase)));
  float lean = sinf(phase * 0.8) * 2.5;
  int i;

  [NSGraphicsContext saveGraphicsState];
  {
    NSAffineTransform *transform = [NSAffineTransform transform];

    [transform translateXBy: center.x yBy: center.y];
    [transform rotateByDegrees: lean];
    [transform translateXBy: -center.x yBy: -center.y];
    [transform concat];
  }

  [[NSColor colorWithCalibratedRed: 0.02 green: 0.95 blue: 0.86 alpha: 0.17] set];
  head = [NSBezierPath bezierPathWithOvalInRect:
	  NSMakeRect(center.x - 82.0 * scale,
		     center.y - 108.0 * scale,
		     164.0 * scale,
		     220.0 * scale)];
  [head fill];

  [[NSColor colorWithCalibratedRed: 0.04 green: 0.95 blue: 0.90 alpha: 0.95] set];
  [head setLineWidth: 2.0 * scale];
  [head stroke];

  for(i = -3; i <= 3; i++)
    {
      NSBezierPath *contour = [NSBezierPath bezierPath];
      float w = (82.0 - fabs((float)i) * 13.0) * scale;
      float y = center.y + ((float)i * 30.0 * scale);

      [contour appendBezierPathWithOvalInRect:
	NSMakeRect(center.x - w, y - 4.0 * scale, w * 2.0, 8.0 * scale)];
      [[NSColor colorWithCalibratedRed: 0.08 green: 0.80 blue: 0.82 alpha: 0.28] set];
      [contour setLineWidth: 1.0];
      [contour stroke];
    }

  [[NSColor colorWithCalibratedRed: 0.72 green: 0.05 blue: 0.28 alpha: 0.86] set];
  visor = [NSBezierPath bezierPathWithRoundedRect:
	   NSMakeRect(center.x - 60.0 * scale,
		      center.y + 20.0 * scale,
		      120.0 * scale,
		      (blink < 0.10 ? 6.0 : 28.0) * scale)
				     xRadius: 8.0 * scale
				     yRadius: 8.0 * scale];
  [visor fill];

  [[NSColor colorWithCalibratedRed: 0.98 green: 0.20 blue: 0.50 alpha: 1.0] set];
  [visor setLineWidth: 2.0 * scale];
  [visor stroke];

  [[NSColor colorWithCalibratedRed: 0.80 green: 1.0 blue: 0.95 alpha: 0.86] set];
  nose = [NSBezierPath bezierPath];
  [nose moveToPoint: NSMakePoint(center.x + 2.0 * scale, center.y + 10.0 * scale)];
  [nose lineToPoint: NSMakePoint(center.x - 12.0 * scale, center.y - 24.0 * scale)];
  [nose lineToPoint: NSMakePoint(center.x + 10.0 * scale, center.y - 21.0 * scale)];
  [nose setLineWidth: 1.6 * scale];
  [nose stroke];

  [[NSColor blackColor] set];
  mouth = [NSBezierPath bezierPathWithRect:
	   NSMakeRect(center.x - 42.0 * scale,
		      center.y - 63.0 * scale,
		      84.0 * scale,
		      mouthOpen * scale)];
  [mouth fill];
  [[NSColor colorWithCalibratedRed: 0.07 green: 0.95 blue: 0.86 alpha: 1.0] set];
  [mouth setLineWidth: 2.0 * scale];
  [mouth stroke];

  [[NSColor colorWithCalibratedRed: 0.85 green: 1.0 blue: 0.95 alpha: 0.7] set];
  jaw = [NSBezierPath bezierPath];
  [jaw moveToPoint: NSMakePoint(center.x - 48.0 * scale, center.y - 82.0 * scale)];
  [jaw curveToPoint: NSMakePoint(center.x + 48.0 * scale, center.y - 82.0 * scale)
      controlPoint1: NSMakePoint(center.x - 24.0 * scale, center.y - 102.0 * scale)
      controlPoint2: NSMakePoint(center.x + 24.0 * scale, center.y - 102.0 * scale)];
  [jaw setLineWidth: 1.4 * scale];
  [jaw stroke];

  [[NSColor colorWithCalibratedRed: 0.05 green: 0.68 blue: 0.70 alpha: 0.50] set];
  neck = [NSBezierPath bezierPath];
  [neck moveToPoint: NSMakePoint(center.x - 38.0 * scale, center.y - 105.0 * scale)];
  [neck lineToPoint: NSMakePoint(center.x - 58.0 * scale, center.y - 160.0 * scale)];
  [neck lineToPoint: NSMakePoint(center.x + 58.0 * scale, center.y - 160.0 * scale)];
  [neck lineToPoint: NSMakePoint(center.x + 38.0 * scale, center.y - 105.0 * scale)];
  [neck closePath];
  [neck fill];
  [[NSColor colorWithCalibratedRed: 0.08 green: 0.98 blue: 0.88 alpha: 0.86] set];
  [neck setLineWidth: 2.0 * scale];
  [neck stroke];

  shine = [NSBezierPath bezierPath];
  [shine moveToPoint: NSMakePoint(center.x - 32.0 * scale, center.y + 88.0 * scale)];
  [shine curveToPoint: NSMakePoint(center.x + 36.0 * scale, center.y + 84.0 * scale)
	controlPoint1: NSMakePoint(center.x - 8.0 * scale, center.y + 106.0 * scale)
	controlPoint2: NSMakePoint(center.x + 18.0 * scale, center.y + 106.0 * scale)];
  [[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 0.55] set];
  [shine setLineWidth: 2.0 * scale];
  [shine stroke];

  [NSGraphicsContext restoreGraphicsState];
}

- (void)drawJitterBandsAtCenter:(NSPoint)center scale:(float)scale
{
  int i;

  for(i = 0; i < SignalHeadBandCount; i++)
    {
      float width = (120.0 + RAND_FLOAT * 95.0) * scale;
      float height = (3.0 + RAND_FLOAT * 11.0) * scale;
      float y = center.y - 104.0 * scale + ((float)i * 18.0 * scale);
      float x = center.x - width / 2.0 + sinf(jitterPhase + i) * 22.0 * scale;

      if((rand() % 100) < 35)
	{
	  [[NSColor colorWithCalibratedRed: 0.95 green: 0.04 blue: 0.38 alpha: 0.22] set];
	  NSRectFillUsingOperation(NSMakeRect(x + 8.0 * scale, y, width, height),
				   NSCompositeSourceOver);
	}
      [[NSColor colorWithCalibratedRed: 0.02 green: 0.90 blue: 0.86 alpha: 0.18] set];
      NSRectFillUsingOperation(NSMakeRect(x, y, width, height),
			       NSCompositeSourceOver);
    }
}

- (void)drawCaptionInBounds:(NSRect)bounds
{
  NSString *caption = captions[captionIndex];
  NSString *smallCaption = @"INNERSPACE VIDEO RELAY";
  NSSize captionSize = [caption sizeWithAttributes: captionAttributes];
  NSSize smallCaptionSize = [smallCaption sizeWithAttributes: smallCaptionAttributes];
  float glitchOffset = (((int)(phase * 12.0) % 9) == 0)
    ? (RAND_FLOAT * 10.0 - 5.0)
    : 0.0;
  NSPoint captionPoint = NSMakePoint((bounds.size.width - captionSize.width) / 2.0 + glitchOffset,
				     26.0);
  NSPoint smallPoint = NSMakePoint(bounds.size.width - smallCaptionSize.width - 18.0,
				   bounds.size.height - smallCaptionSize.height - 16.0);

  [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.62] set];
  NSRectFillUsingOperation(NSMakeRect(captionPoint.x - 14.0,
				      captionPoint.y - 7.0,
				      captionSize.width + 28.0,
				      captionSize.height + 12.0),
			   NSCompositeSourceOver);
  [caption drawAtPoint: captionPoint withAttributes: captionAttributes];
  [smallCaption drawAtPoint: smallPoint withAttributes: smallCaptionAttributes];
}

@end

@implementation StaticSignalHeadView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect: rects];
}
@end
