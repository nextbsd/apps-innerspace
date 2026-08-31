#include "KaleidoscopeView.h"
#include <math.h>
#include <stdlib.h>
#include <time.h>

#define RAND_FLOAT ((float)rand() / (float)RAND_MAX)
#define TWO_PI 6.28318530717958647692

@implementation KaleidoscopeView

- (id)initWithFrame:(NSRect)frameRect
{
  int i;

  self = [super initWithFrame: frameRect];
  if(self)
    {
      srand((unsigned int)time(NULL));
      animationPhase = 0.0;
      hasDrawnBackground = NO;
      for(i = 0; i < KaleidoscopeParticleCount; i++)
	{
	  [self resetParticle: i];
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
  return 0.03;
}

- (NSString *)windowTitle
{
  return @"Kaleidoscope";
}

- (void)setFrame:(NSRect)frame
{
  int i;

  [super setFrame: frame];
  hasDrawnBackground = NO;
  for(i = 0; i < KaleidoscopeParticleCount; i++)
    {
      [self resetParticle: i];
    }
}

- (void)resetParticle:(int)index
{
  NSRect bounds = [self bounds];
  KaleidoscopeParticle *particle = &particles[index];
  float span = bounds.size.width < bounds.size.height
    ? bounds.size.width
    : bounds.size.height;
  float angle;
  float speed;

  if(span < 1.0)
    {
      span = 480.0;
    }

  angle = RAND_FLOAT * TWO_PI;
  speed = 0.8 + (RAND_FLOAT * 2.6);
  particle->position = NSMakePoint((RAND_FLOAT - 0.5) * span * 0.42,
				   (RAND_FLOAT - 0.5) * span * 0.42);
  particle->velocity = NSMakePoint(cosf(angle) * speed, sinf(angle) * speed);
  particle->hue = RAND_FLOAT;
  particle->radius = 2.5 + (RAND_FLOAT * 7.0);
  particle->phase = RAND_FLOAT * TWO_PI;
}

- (void)drawRect:(NSRect)rects
{
  [[NSColor blackColor] set];
  NSRectFill(rects);
  hasDrawnBackground = YES;
}

- (void)oneStep
{
  NSRect bounds = [self bounds];
  int i;

  if(!hasDrawnBackground)
    {
      [[NSColor blackColor] set];
      NSRectFill(bounds);
      hasDrawnBackground = YES;
    }

  [[NSColor colorWithCalibratedWhite: 0.0 alpha: 0.12] set];
  NSRectFillUsingOperation(bounds, NSCompositeSourceOver);

  animationPhase += 0.035;
  for(i = 0; i < KaleidoscopeParticleCount; i++)
    {
      KaleidoscopeParticle *particle = &particles[i];
      float limit = ((bounds.size.width < bounds.size.height)
		     ? bounds.size.width
		     : bounds.size.height) * 0.46;
      float swirl = sinf(animationPhase + particle->phase) * 0.045;
      float vx = particle->velocity.x;
      float vy = particle->velocity.y;

      particle->velocity.x = (vx * cosf(swirl)) - (vy * sinf(swirl));
      particle->velocity.y = (vx * sinf(swirl)) + (vy * cosf(swirl));
      particle->position.x += particle->velocity.x;
      particle->position.y += particle->velocity.y;

      if(hypotf(particle->position.x, particle->position.y) > limit)
	{
	  float angle = atan2f(particle->position.y, particle->position.x);

	  particle->position.x = cosf(angle) * limit;
	  particle->position.y = sinf(angle) * limit;
	  particle->velocity.x -= cosf(angle) * 2.0 * fabs(particle->velocity.x);
	  particle->velocity.y -= sinf(angle) * 2.0 * fabs(particle->velocity.y);
	  particle->hue += 0.13;
	  if(particle->hue > 1.0)
	    {
	      particle->hue -= 1.0;
	    }
	}

      [self drawParticle: particle inBounds: bounds];
    }
}

- (NSColor *)colorForHue:(float)hue alpha:(float)alpha
{
  float r;
  float g;
  float b;

  r = 0.55 + (0.45 * sinf((hue * TWO_PI) + 0.0));
  g = 0.55 + (0.45 * sinf((hue * TWO_PI) + 2.0943951));
  b = 0.55 + (0.45 * sinf((hue * TWO_PI) + 4.1887902));

  return [NSColor colorWithCalibratedRed: r green: g blue: b alpha: alpha];
}

- (void)drawParticle:(KaleidoscopeParticle *)particle inBounds:(NSRect)bounds
{
  NSPoint center = NSMakePoint(NSMidX(bounds), NSMidY(bounds));
  float segmentAngle = TWO_PI / KaleidoscopeSegments;
  float pulse = 0.72 + (0.28 * sinf(animationPhase * 5.0 + particle->phase));
  int i;

  for(i = 0; i < KaleidoscopeSegments; i++)
    {
      int mirror;

      for(mirror = 0; mirror < 2; mirror++)
	{
	  NSAffineTransform *transform = [NSAffineTransform transform];
	  NSBezierPath *path;
	  float yScale = mirror ? -1.0 : 1.0;
	  float radius = particle->radius * pulse;

	  [NSGraphicsContext saveGraphicsState];
	  [transform translateXBy: center.x yBy: center.y];
	  [transform rotateByRadians: segmentAngle * i];
	  [transform scaleXBy: 1.0 yBy: yScale];
	  [transform concat];

	  [[self colorForHue: particle->hue + (i * 0.035) alpha: 0.72] set];
	  path = [NSBezierPath bezierPathWithOvalInRect:
	    NSMakeRect(particle->position.x - radius,
		       particle->position.y - radius,
		       radius * 2.0,
		       radius * 2.0)];
	  [path fill];

	  [[self colorForHue: particle->hue + 0.18 alpha: 0.45] set];
	  [path setLineWidth: 1.0];
	  [path stroke];

	  [NSGraphicsContext restoreGraphicsState];
	}
    }
}

@end

@implementation StaticKaleidoscopeView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect: rects];
}
@end
