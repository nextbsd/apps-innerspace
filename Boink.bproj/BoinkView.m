#include "BoinkView.h"
#include <math.h>

#define BoinkBallRadius 64.0
#define BoinkMinimumRadius 24.0
#define BoinkPi 3.14159265358979323846

@implementation BoinkView

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if(self)
    {
      ballRadius = BoinkBallRadius;
      if(frameRect.size.width < ballRadius * 2.0 ||
	 frameRect.size.height < ballRadius * 2.0)
	{
	  ballRadius = MAX(BoinkMinimumRadius,
			   MIN(frameRect.size.width, frameRect.size.height) * 0.18);
	}

      ballPosition = NSMakePoint(NSMidX(frameRect), NSMidY(frameRect));
      ballVelocity = NSMakePoint(6.5, 5.0);
      rotation = 0.0;
      [self keepBallInBounds];
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
  return 0.03;
}

- (NSString *)windowTitle
{
  return @"Boink";
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame: frame];
  if(frame.size.width < ballRadius * 2.0 ||
     frame.size.height < ballRadius * 2.0)
    {
      ballRadius = MAX(BoinkMinimumRadius,
		       MIN(frame.size.width, frame.size.height) * 0.18);
    }
  else
    {
      ballRadius = BoinkBallRadius;
    }
  [self keepBallInBounds];
}

- (void)drawRect:(NSRect)rects
{
  [[NSColor blackColor] set];
  NSRectFill(rects);
}

- (void)oneStep
{
  NSRect bounds = [self bounds];

  [[NSColor blackColor] set];
  NSRectFill(bounds);

  ballPosition.x += ballVelocity.x;
  ballPosition.y += ballVelocity.y;

  if(ballPosition.x + ballRadius >= NSMaxX(bounds))
    {
      ballPosition.x = NSMaxX(bounds) - ballRadius;
      ballVelocity.x = -fabs(ballVelocity.x);
    }
  else if(ballPosition.x - ballRadius <= NSMinX(bounds))
    {
      ballPosition.x = NSMinX(bounds) + ballRadius;
      ballVelocity.x = fabs(ballVelocity.x);
    }

  if(ballPosition.y + ballRadius >= NSMaxY(bounds))
    {
      ballPosition.y = NSMaxY(bounds) - ballRadius;
      ballVelocity.y = -fabs(ballVelocity.y);
    }
  else if(ballPosition.y - ballRadius <= NSMinY(bounds))
    {
      ballPosition.y = NSMinY(bounds) + ballRadius;
      ballVelocity.y = fabs(ballVelocity.y);
    }

  rotation += ballVelocity.x * 1.6;
  [self drawBall];
}

- (void)keepBallInBounds
{
  NSRect bounds = [self bounds];

  if(ballPosition.x + ballRadius > NSMaxX(bounds))
    {
      ballPosition.x = NSMaxX(bounds) - ballRadius;
    }
  if(ballPosition.x - ballRadius < NSMinX(bounds))
    {
      ballPosition.x = NSMinX(bounds) + ballRadius;
    }
  if(ballPosition.y + ballRadius > NSMaxY(bounds))
    {
      ballPosition.y = NSMaxY(bounds) - ballRadius;
    }
  if(ballPosition.y - ballRadius < NSMinY(bounds))
    {
      ballPosition.y = NSMinY(bounds) + ballRadius;
    }
}

- (void)drawBall
{
  NSBezierPath *sphere;
  NSBezierPath *shadow;
  NSBezierPath *highlight;
  NSBezierPath *rim;
  NSRect ballRect;
  NSRect shadowRect;

  shadowRect = NSMakeRect(ballPosition.x - (ballRadius * 0.72),
			  ballPosition.y - (ballRadius * 1.08),
			  ballRadius * 1.44,
			  ballRadius * 0.25);
  shadow = [NSBezierPath bezierPathWithOvalInRect: shadowRect];
  [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.45] set];
  [shadow fill];

  ballRect = NSMakeRect(ballPosition.x - ballRadius,
			ballPosition.y - ballRadius,
			ballRadius * 2.0,
			ballRadius * 2.0);
  sphere = [NSBezierPath bezierPathWithOvalInRect: ballRect];

  [[NSColor colorWithCalibratedWhite: 1.0 alpha: 1.0] set];
  [sphere fill];

  [NSGraphicsContext saveGraphicsState];
  [sphere addClip];
  [self drawCheckerCellsWithRadius: ballRadius];

  [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.20] set];
  NSRectFillUsingOperation(NSMakeRect(ballPosition.x - ballRadius,
				      ballPosition.y - ballRadius,
				      ballRadius * 0.55,
				      ballRadius * 2.0),
			   NSCompositeSourceOver);
  [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.12] set];
  NSRectFillUsingOperation(NSMakeRect(ballPosition.x - (ballRadius * 0.05),
				      ballPosition.y - ballRadius,
				      ballRadius * 1.05,
				      ballRadius * 0.55),
			   NSCompositeSourceOver);
  [NSGraphicsContext restoreGraphicsState];

  highlight = [NSBezierPath bezierPathWithOvalInRect:
	       NSMakeRect(ballPosition.x - (ballRadius * 0.45),
			  ballPosition.y + (ballRadius * 0.18),
			  ballRadius * 0.62,
			  ballRadius * 0.45)];
  [[NSColor colorWithCalibratedWhite: 1.0 alpha: 0.42] set];
  [highlight fill];

  rim = [NSBezierPath bezierPathWithOvalInRect: ballRect];
  [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.58] set];
  [rim setLineWidth: 2.0];
  [rim stroke];
}

- (void)drawCheckerCellsWithRadius:(float)radius
{
  int latCount = 8;
  int lonCount = 16;
  int lat;
  int lon;

  for(lat = 0; lat < latCount; lat++)
    {
      float theta1 = -BoinkPi / 2.0 + ((float)lat / (float)latCount) * BoinkPi;
      float theta2 = -BoinkPi / 2.0 + ((float)(lat + 1) / (float)latCount) * BoinkPi;
      float y1 = sin(theta1) * radius;
      float y2 = sin(theta2) * radius;
      float bandScale1 = cos(theta1);
      float bandScale2 = cos(theta2);

      for(lon = 0; lon < lonCount; lon++)
	{
	  float phi1 = (((float)lon / (float)lonCount) * 2.0 * BoinkPi) +
	    (rotation * BoinkPi / 180.0);
	  float phi2 = (((float)(lon + 1) / (float)lonCount) * 2.0 * BoinkPi) +
	    (rotation * BoinkPi / 180.0);
	  float x11 = sin(phi1) * radius * bandScale1;
	  float x12 = sin(phi2) * radius * bandScale1;
	  float x21 = sin(phi2) * radius * bandScale2;
	  float x22 = sin(phi1) * radius * bandScale2;
	  float z = (cos(phi1) + cos(phi2)) * 0.5;
	  float shade = 0.75 + (0.25 * z);
	  NSBezierPath *cell;

	  if(cos(phi1) < -0.12 && cos(phi2) < -0.12)
	    {
	      continue;
	    }

	  cell = [NSBezierPath bezierPath];
	  [cell moveToPoint: NSMakePoint(ballPosition.x + x11, ballPosition.y + y1)];
	  [cell lineToPoint: NSMakePoint(ballPosition.x + x12, ballPosition.y + y1)];
	  [cell lineToPoint: NSMakePoint(ballPosition.x + x21, ballPosition.y + y2)];
	  [cell lineToPoint: NSMakePoint(ballPosition.x + x22, ballPosition.y + y2)];
	  [cell closePath];

	  if(((lat + lon) % 2) == 0)
	    {
	      [[NSColor colorWithCalibratedRed: 0.92 * shade
					 green: 0.04 * shade
					  blue: 0.02 * shade
					 alpha: 1.0] set];
	    }
	  else
	    {
	      [[NSColor colorWithCalibratedWhite: 0.96 * shade alpha: 1.0] set];
	    }
	  [cell fill];

	  [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.18] set];
	  [cell setLineWidth: 0.5];
	  [cell stroke];
	}
    }
}

@end

@implementation StaticBoinkView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect: rects];
}
@end
