#include "NekoView.h"
#include <math.h>
#include <stdlib.h>

#define RAND_FLOAT ((float)rand() / (float)RAND_MAX)
#define SPRITE_SIZE 32
#define CAT_WIDTH 64.0
#define CAT_HEIGHT 64.0
#define WALK_SPEED 9.0
#define WANDER_SPEED 4.0
#define FOUND_DISTANCE 18.0
#define SLEEP_DELAY 18
#define WAKE_DELAY 90

@implementation NekoView

- (void)setAnimationHostView:(NSView *)host { animationHostView = host; }

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
      animationTicks = 0;
      [self loadSpriteSheet];
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
  NSView *coordinateView = animationHostView ? animationHostView : self;
  NSWindow *hostWindow = [coordinateView window];

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
  NSView *coordinateView = animationHostView ? animationHostView : self;
  NSWindow *hostWindow = [coordinateView window];
  NSPoint point = [NSEvent mouseLocation];

  if(hostWindow != nil)
    {
      point = [hostWindow convertScreenToBase: point];
      point = [coordinateView convertPoint: point fromView: nil];
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

// Frames are numbered left-to-right, top-to-bottom in the 4 by 3 sheet.
- (void)loadSpriteSheet
{
  NSString *path = [[NSBundle bundleForClass: [NekoView class]]
                    pathForResource: @"neko_animation_steps" ofType: @"png"];
  NSData *data = path ? [NSData dataWithContentsOfFile: path] : nil;
  NSBitmapImageRep *source = data ? [NSBitmapImageRep imageRepWithData: data] : nil;
  if(source == nil || [source pixelsWide] != 128 || [source pixelsHigh] != 96)
    {
      NSLog(@"Neko: missing or invalid neko_animation_steps.png (expected 128x96)");
      return;
    }

  // Keep the supplied asset intact; remove only its red color key at load time.
  NSBitmapImageRep *rgba = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: 128 pixelsHigh: 96
    bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
    colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: 0 bitsPerPixel: 0];
  int x, y;
  for(y = 0; y < 96; y++)
    {
      for(x = 0; x < 128; x++)
        {
          NSColor *color = [[source colorAtX: x y: y]
                            colorUsingColorSpaceName: NSDeviceRGBColorSpace];
          if([color redComponent] > 0.99 &&
             [color greenComponent] < 0.01 && [color blueComponent] < 0.01)
            color = [NSColor clearColor];
          [rgba setColor: color atX: x y: y];
        }
    }
  spriteSheet = [[NSImage alloc] initWithSize: NSMakeSize(128, 96)];
  [spriteSheet addRepresentation: rgba];
  [rgba release];
}

- (void)dealloc
{
  [spriteSheet release];
  [super dealloc];
}

- (int)spriteFrame
{
  if(state == NekoStateSleeping)
    return 6 + (animationTicks / 10) % 4;
  if(fabs(catVelocity.x) + fabs(catVelocity.y) > 0.1)
    return (animationTicks / 3) % 2 == 0 ? 1 : 3;
  if(sleepTicks >= SLEEP_DELAY / 2)
    return (animationTicks / 3) % 2 == 0 ? 2 : 4;
  static const int idleFrames[] = { 0, 5, 10 };
  return idleFrames[(animationTicks / 3) % 3];
}

- (void)drawCat
{
  int frame = [self spriteFrame];
  NSRect source = NSMakeRect((frame % 4) * SPRITE_SIZE,
                            (2 - frame / 4) * SPRITE_SIZE,
                            SPRITE_SIZE, SPRITE_SIZE);
  NSAffineTransform *transform = [NSAffineTransform transform];
  [NSGraphicsContext saveGraphicsState];
  [[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationNone];
  [transform translateXBy: floor(catPosition.x) yBy: floor(catPosition.y)];
  // The side-facing poses in the source look left.
  if(!facingLeft && fabs(catVelocity.x) + fabs(catVelocity.y) > 0.1)
    {
      [transform translateXBy: CAT_WIDTH yBy: 0];
      [transform scaleXBy: -1 yBy: 1];
    }
  [transform concat];
  [spriteSheet drawInRect: NSMakeRect(0, 0, CAT_WIDTH, CAT_HEIGHT)
                fromRect: source operation: NSCompositeSourceOver fraction: 1.0];
  [NSGraphicsContext restoreGraphicsState];
}

- (void)oneStep
{
  animationTicks = (animationTicks + 1) % 120;
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
