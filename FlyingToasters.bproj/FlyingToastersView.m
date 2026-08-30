#include "FlyingToastersView.h"
#include <math.h>
#include <stdlib.h>
#include <time.h>

#define RAND_FLOAT ((float)rand() / (float)RAND_MAX)
#define ToasterBaseWidth 96.0
#define ToasterBaseHeight 58.0

@implementation FlyingToastersView

- (id)initWithFrame:(NSRect)frameRect
{
  int i;

  self = [super initWithFrame: frameRect];
  if(self)
    {
      srand((unsigned int)time(NULL));
      animationPhase = 0.0;
      for(i = 0; i < FlyingToastersCount; i++)
	{
	  [self resetToaster: i offscreen: NO];
	  toasters[i].position.x = RAND_FLOAT * frameRect.size.width;
	}
    }
  return self;
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
  return @"Flying Toasters";
}

- (void)setFrame:(NSRect)frame
{
  int i;

  [super setFrame: frame];
  for(i = 0; i < FlyingToastersCount; i++)
    {
      if(toasters[i].position.y > frame.size.height + 60.0)
	{
	  toasters[i].position.y = RAND_FLOAT * frame.size.height;
	}
    }
}

- (void)resetToaster:(int)index offscreen:(BOOL)offscreen
{
  NSRect bounds = [self bounds];
  FlyingToaster *toaster = &toasters[index];
  float height = bounds.size.height;

  if(height < 1.0)
    {
      height = 480.0;
    }

  toaster->scale = 0.55 + (RAND_FLOAT * 0.65);
  toaster->speed = 2.2 + (RAND_FLOAT * 3.8);
  toaster->drift = -0.55 + (RAND_FLOAT * 1.10);
  toaster->phase = RAND_FLOAT * 6.28318;
  toaster->flapSpeed = 0.65 + (RAND_FLOAT * 0.55);
  toaster->position.x = offscreen
    ? bounds.size.width + (RAND_FLOAT * 220.0) + (ToasterBaseWidth * toaster->scale)
    : RAND_FLOAT * bounds.size.width;
  toaster->position.y = RAND_FLOAT * height;
}

- (void)drawRect:(NSRect)rects
{
  [[NSColor blackColor] set];
  NSRectFill(rects);
}

- (void)oneStep
{
  NSRect bounds = [self bounds];
  int i;

  [[NSColor blackColor] set];
  NSRectFill(bounds);

  animationPhase += 0.32;
  for(i = 0; i < FlyingToastersCount; i++)
    {
      FlyingToaster *toaster = &toasters[i];
      float margin = ToasterBaseWidth * toaster->scale;

      toaster->position.x -= toaster->speed;
      toaster->position.y += toaster->drift + (sinf(animationPhase * 0.25 + toaster->phase) * 0.18);

      if(toaster->position.x < -margin ||
	 toaster->position.y < -80.0 ||
	 toaster->position.y > bounds.size.height + 80.0)
	{
	  [self resetToaster: i offscreen: YES];
	}

      [self drawToaster: toaster];
    }
}

- (void)drawWingWithScale:(float)scale flap:(float)flap mirrored:(BOOL)mirrored
{
  NSBezierPath *wing;
  NSBezierPath *feather;
  float side = mirrored ? -1.0 : 1.0;
  float lift = flap * 16.0 * scale;
  int i;

  wing = [NSBezierPath bezierPath];
  [wing moveToPoint: NSMakePoint(side * 12.0 * scale, 8.0 * scale)];
  [wing curveToPoint: NSMakePoint(side * 58.0 * scale, (34.0 * scale) + lift)
       controlPoint1: NSMakePoint(side * 22.0 * scale, (30.0 * scale) + lift)
       controlPoint2: NSMakePoint(side * 42.0 * scale, (42.0 * scale) + lift)];
  [wing curveToPoint: NSMakePoint(side * 32.0 * scale, (-6.0 * scale) + (lift * 0.25))
       controlPoint1: NSMakePoint(side * 62.0 * scale, (13.0 * scale) + lift)
       controlPoint2: NSMakePoint(side * 49.0 * scale, (-2.0 * scale) + (lift * 0.2))];
  [wing curveToPoint: NSMakePoint(side * 12.0 * scale, 8.0 * scale)
       controlPoint1: NSMakePoint(side * 24.0 * scale, (-1.0 * scale) + (lift * 0.1))
       controlPoint2: NSMakePoint(side * 16.0 * scale, 3.0 * scale)];

  [[NSColor colorWithCalibratedWhite: 0.92 alpha: 1.0] set];
  [wing fill];
  [[NSColor colorWithCalibratedWhite: 0.70 alpha: 1.0] set];
  [wing setLineWidth: 1.4 * scale];
  [wing stroke];

  [[NSColor colorWithCalibratedWhite: 0.76 alpha: 1.0] set];
  for(i = 0; i < 4; i++)
    {
      float x1 = side * (22.0 + (i * 8.0)) * scale;
      float x2 = side * (35.0 + (i * 7.5)) * scale;
      float y1 = (8.0 - (i * 1.8)) * scale + (lift * 0.10);
      float y2 = (22.0 + (i * 2.7)) * scale + (lift * 0.55);

      feather = [NSBezierPath bezierPath];
      [feather moveToPoint: NSMakePoint(x1, y1)];
      [feather lineToPoint: NSMakePoint(x2, y2)];
      [feather setLineWidth: 1.0 * scale];
      [feather stroke];
    }
}

- (void)drawToaster:(FlyingToaster *)toaster
{
  NSAffineTransform *transform = [NSAffineTransform transform];
  NSBezierPath *body;
  NSBezierPath *slot;
  NSRect bodyRect;
  float scale = toaster->scale;
  float flap = sinf((animationPhase * toaster->flapSpeed) + toaster->phase);

  [NSGraphicsContext saveGraphicsState];
  [transform translateXBy: toaster->position.x yBy: toaster->position.y];
  [transform concat];

  [self drawWingWithScale: scale flap: flap mirrored: YES];
  [self drawWingWithScale: scale flap: flap mirrored: NO];

  bodyRect = NSMakeRect(-29.0 * scale, -17.0 * scale, 58.0 * scale, 34.0 * scale);
  body = [NSBezierPath bezierPathWithRoundedRect: bodyRect
					 xRadius: 9.0 * scale
					 yRadius: 9.0 * scale];
  [[NSColor colorWithCalibratedRed: 0.84 green: 0.86 blue: 0.88 alpha: 1.0] set];
  [body fill];
  [[NSColor colorWithCalibratedWhite: 0.35 alpha: 1.0] set];
  [body setLineWidth: 1.8 * scale];
  [body stroke];

  slot = [NSBezierPath bezierPathWithRoundedRect:
	  NSMakeRect(-18.0 * scale, 9.5 * scale, 36.0 * scale, 5.0 * scale)
				      xRadius: 2.5 * scale
				      yRadius: 2.5 * scale];
  [[NSColor colorWithCalibratedWhite: 0.18 alpha: 1.0] set];
  [slot fill];

  [[NSColor colorWithCalibratedRed: 0.96 green: 0.72 blue: 0.38 alpha: 1.0] set];
  NSRectFill(NSMakeRect(-18.0 * scale, -15.0 * scale, 36.0 * scale, 5.5 * scale));

  [[NSColor colorWithCalibratedWhite: 0.24 alpha: 1.0] set];
  NSRectFill(NSMakeRect(28.0 * scale, 0.0 * scale, 7.0 * scale, 3.0 * scale));
  NSRectFill(NSMakeRect(34.0 * scale, -3.5 * scale, 3.0 * scale, 10.0 * scale));
  NSRectFill(NSMakeRect(-21.0 * scale, -21.0 * scale, 8.0 * scale, 4.0 * scale));
  NSRectFill(NSMakeRect(13.0 * scale, -21.0 * scale, 8.0 * scale, 4.0 * scale));

  [[NSColor colorWithCalibratedWhite: 1.0 alpha: 0.35] set];
  NSRectFill(NSMakeRect(-20.0 * scale, 1.0 * scale, 16.0 * scale, 9.0 * scale));

  [NSGraphicsContext restoreGraphicsState];
}

@end

@implementation StaticFlyingToastersView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect: rects];
}
@end
