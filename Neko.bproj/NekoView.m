#include "NekoView.h"
#include <math.h>
#include <stdlib.h>

#define RAND_FLOAT ((float)rand() / (float)RAND_MAX)
#define CAT_WIDTH 54.0
#define CAT_HEIGHT 38.0
#define WALK_SPEED 9.0
#define WANDER_SPEED 4.0
#define FOUND_DISTANCE 18.0
#define SLEEP_DELAY 18
#define WAKE_DELAY 90

@implementation NekoView

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if(self)
    {
      catPosition = NSMakePoint(80.0, 80.0);
      catVelocity = NSMakePoint(0.0, 0.0);
      targetPosition = catPosition;
      wanderTarget = catPosition;
      state = NekoStateWalking;
      sleepTicks = 0;
      blinkTicks = 0;
      facingLeft = NO;
      saverMode = NO;
      srand((unsigned int)[[NSDate date] timeIntervalSince1970]);
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
  return 0.055;
}

- (NSString *)windowTitle
{
  return @"Neko";
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame: frame];
  [self keepCatInBounds];
}

- (void)willEnterScreenSaverMode
{
  [self updateSaverMode];
  if(saverMode)
    {
      state = NekoStateWandering;
      [self chooseWanderTarget];
    }
}

- (void)willExitScreenSaverMode
{
  state = NekoStateWalking;
  sleepTicks = 0;
}

- (void)updateSaverMode
{
  NSWindow *hostWindow = [self window];

  saverMode = (hostWindow != nil && [hostWindow level] >= NSScreenSaverWindowLevel);
}

- (NSPoint)randomCatPosition
{
  NSRect bounds = [self bounds];
  float maxX = bounds.size.width - CAT_WIDTH;
  float maxY = bounds.size.height - CAT_HEIGHT;

  if(maxX < 0.0)
    {
      maxX = 0.0;
    }
  if(maxY < 0.0)
    {
      maxY = 0.0;
    }

  return NSMakePoint(RAND_FLOAT * maxX, RAND_FLOAT * maxY);
}

- (void)chooseWanderTarget
{
  wanderTarget = [self randomCatPosition];
}

- (void)keepCatInBounds
{
  NSRect bounds = [self bounds];
  float maxX = bounds.size.width - CAT_WIDTH;
  float maxY = bounds.size.height - CAT_HEIGHT;

  if(maxX < 0.0)
    {
      maxX = 0.0;
    }
  if(maxY < 0.0)
    {
      maxY = 0.0;
    }

  if(catPosition.x < 0.0)
    {
      catPosition.x = 0.0;
    }
  if(catPosition.y < 0.0)
    {
      catPosition.y = 0.0;
    }
  if(catPosition.x > maxX)
    {
      catPosition.x = maxX;
    }
  if(catPosition.y > maxY)
    {
      catPosition.y = maxY;
    }
}

- (NSPoint)mousePositionInView
{
  NSWindow *hostWindow = [self window];
  NSPoint point = [NSEvent mouseLocation];

  if(hostWindow != nil)
    {
      point = [hostWindow convertScreenToBase: point];
      point = [self convertPoint: point fromView: nil];
    }

  return NSMakePoint(point.x - (CAT_WIDTH / 2.0),
		     point.y - (CAT_HEIGHT / 2.0));
}

- (void)moveToward:(NSPoint)point speed:(float)speed
{
  float dx = point.x - catPosition.x;
  float dy = point.y - catPosition.y;
  float distance = sqrt((dx * dx) + (dy * dy));

  if(distance > 0.1)
    {
      float step = speed;

      if(distance < step)
	{
	  step = distance;
	}

      catVelocity = NSMakePoint((dx / distance) * step,
				(dy / distance) * step);
      catPosition.x += catVelocity.x;
      catPosition.y += catVelocity.y;
      facingLeft = (catVelocity.x < 0.0);
    }
  else
    {
      catVelocity = NSMakePoint(0.0, 0.0);
    }

  [self keepCatInBounds];
}

- (float)distanceFromCatTo:(NSPoint)point
{
  float dx = point.x - catPosition.x;
  float dy = point.y - catPosition.y;

  return sqrt((dx * dx) + (dy * dy));
}

- (void)updateWalking
{
  targetPosition = [self mousePositionInView];

  if([self distanceFromCatTo: targetPosition] <= FOUND_DISTANCE)
    {
      sleepTicks++;
      catVelocity = NSMakePoint(0.0, 0.0);
      if(sleepTicks >= SLEEP_DELAY)
	{
	  state = NekoStateSleeping;
	}
    }
  else
    {
      sleepTicks = 0;
      [self moveToward: targetPosition speed: WALK_SPEED];
    }
}

- (void)updateSleeping
{
  targetPosition = [self mousePositionInView];
  catVelocity = NSMakePoint(0.0, 0.0);

  if([self distanceFromCatTo: targetPosition] > FOUND_DISTANCE * 2.0)
    {
      state = NekoStateWalking;
      sleepTicks = 0;
    }
}

- (void)updateWandering
{
  sleepTicks++;

  if([self distanceFromCatTo: wanderTarget] <= FOUND_DISTANCE || sleepTicks > WAKE_DELAY)
    {
      sleepTicks = 0;
      [self chooseWanderTarget];
    }

  [self moveToward: wanderTarget speed: WANDER_SPEED];
}

- (void)drawRect:(NSRect)rects
{
  [[NSColor blackColor] set];
  NSRectFill(rects);
  [self drawCat];
}

- (void)drawEarAt:(NSPoint)base left:(BOOL)left
{
  NSBezierPath *ear = [NSBezierPath bezierPath];
  float dir = left ? -1.0 : 1.0;

  [ear moveToPoint: NSMakePoint(base.x, base.y)];
  [ear lineToPoint: NSMakePoint(base.x + (dir * 8.0), base.y + 16.0)];
  [ear lineToPoint: NSMakePoint(base.x + (dir * 16.0), base.y)];
  [ear closePath];
  [[NSColor colorWithCalibratedRed: 0.92 green: 0.90 blue: 0.82 alpha: 1.0] set];
  [ear fill];
  [[NSColor blackColor] set];
  [ear stroke];
}

- (void)drawCat
{
  NSRect body = NSMakeRect(catPosition.x + 8.0, catPosition.y + 2.0, 36.0, 22.0);
  NSRect head = NSMakeRect(catPosition.x + 12.0, catPosition.y + 18.0, 30.0, 22.0);
  NSBezierPath *tail;
  NSBezierPath *mouth;
  NSString *sleepText;
  NSDictionary *attrs;
  float eyeY = catPosition.y + 29.0;
  float leftEyeX = catPosition.x + 22.0;
  float rightEyeX = catPosition.x + 32.0;
  float tailBaseX = facingLeft ? catPosition.x + 11.0 : catPosition.x + 43.0;
  float tailTipX = facingLeft ? catPosition.x + 1.0 : catPosition.x + 53.0;
  float legOffset = (fabs(catVelocity.x) + fabs(catVelocity.y) > 0.1 && blinkTicks % 10 < 5) ? 3.0 : 0.0;

  [[NSColor colorWithCalibratedRed: 0.92 green: 0.90 blue: 0.82 alpha: 1.0] set];
  [[NSBezierPath bezierPathWithOvalInRect: body] fill];
  [[NSBezierPath bezierPathWithOvalInRect: head] fill];

  [self drawEarAt: NSMakePoint(catPosition.x + 21.0, catPosition.y + 34.0) left: YES];
  [self drawEarAt: NSMakePoint(catPosition.x + 33.0, catPosition.y + 34.0) left: NO];

  [[NSColor colorWithCalibratedRed: 0.73 green: 0.55 blue: 0.32 alpha: 1.0] set];
  NSRectFill(NSMakeRect(catPosition.x + 20.0, catPosition.y + 36.0, 5.0, 2.0));
  NSRectFill(NSMakeRect(catPosition.x + 29.0, catPosition.y + 36.0, 5.0, 2.0));
  NSRectFill(NSMakeRect(catPosition.x + 26.0, catPosition.y + 20.0, 4.0, 15.0));

  tail = [NSBezierPath bezierPath];
  [tail setLineWidth: 5.0];
  [tail moveToPoint: NSMakePoint(tailBaseX, catPosition.y + 13.0)];
  [tail curveToPoint: NSMakePoint(tailTipX, catPosition.y + 31.0)
       controlPoint1: NSMakePoint(tailTipX, catPosition.y + 13.0)
       controlPoint2: NSMakePoint(tailTipX, catPosition.y + 28.0)];
  [[NSColor colorWithCalibratedRed: 0.92 green: 0.90 blue: 0.82 alpha: 1.0] set];
  [tail stroke];

  [[NSColor blackColor] set];
  NSRectFill(NSMakeRect(catPosition.x + 16.0, catPosition.y + 1.0 + legOffset, 6.0, 4.0));
  NSRectFill(NSMakeRect(catPosition.x + 34.0, catPosition.y + 1.0 - legOffset, 6.0, 4.0));

  if(state == NekoStateSleeping)
    {
      NSRectFill(NSMakeRect(leftEyeX - 3.0, eyeY, 6.0, 1.5));
      NSRectFill(NSMakeRect(rightEyeX - 3.0, eyeY, 6.0, 1.5));
    }
  else
    {
      [[NSBezierPath bezierPathWithOvalInRect:
			 NSMakeRect(leftEyeX - 2.0, eyeY - 2.0, 4.0, 4.0)] fill];
      [[NSBezierPath bezierPathWithOvalInRect:
			 NSMakeRect(rightEyeX - 2.0, eyeY - 2.0, 4.0, 4.0)] fill];
    }

  NSRectFill(NSMakeRect(catPosition.x + 27.0, catPosition.y + 24.0, 3.0, 2.0));
  mouth = [NSBezierPath bezierPath];
  [mouth setLineWidth: 1.0];
  [mouth moveToPoint: NSMakePoint(catPosition.x + 28.0, catPosition.y + 24.0)];
  [mouth lineToPoint: NSMakePoint(catPosition.x + 24.0, catPosition.y + 21.0)];
  [mouth moveToPoint: NSMakePoint(catPosition.x + 29.0, catPosition.y + 24.0)];
  [mouth lineToPoint: NSMakePoint(catPosition.x + 33.0, catPosition.y + 21.0)];
  [mouth stroke];

  if(state == NekoStateSleeping)
    {
      sleepText = @"Z";
      attrs = [NSDictionary dictionaryWithObjectsAndKeys:
			      [NSFont boldSystemFontOfSize: 14.0], NSFontAttributeName,
			      [NSColor whiteColor], NSForegroundColorAttributeName,
			      nil];
      [sleepText drawAtPoint: NSMakePoint(catPosition.x + 43.0,
					  catPosition.y + 34.0)
	      withAttributes: attrs];
    }

  blinkTicks++;
}

- (void)oneStep
{
  [self updateSaverMode];

  if(saverMode)
    {
      if(state != NekoStateWandering)
	{
	  state = NekoStateWandering;
	  sleepTicks = 0;
	  [self chooseWanderTarget];
	}
      [self updateWandering];
    }
  else if(state == NekoStateSleeping)
    {
      [self updateSleeping];
    }
  else
    {
      state = NekoStateWalking;
      [self updateWalking];
    }

  [[NSColor blackColor] set];
  NSRectFill([self bounds]);
  [self drawCat];
}

@end
