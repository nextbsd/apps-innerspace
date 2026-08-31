#include <AppKit/AppKit.h>

#define KaleidoscopeParticleCount 18
#define KaleidoscopeSegments 8

typedef struct kaleidoscope_particle
{
  NSPoint position;
  NSPoint velocity;
  float hue;
  float radius;
  float phase;
} KaleidoscopeParticle;

@interface KaleidoscopeView : NSView
{
  KaleidoscopeParticle particles[KaleidoscopeParticleCount];
  float animationPhase;
  BOOL hasDrawnBackground;
}
- (void)oneStep;
- (void)resetParticle:(int)index;
- (void)drawParticle:(KaleidoscopeParticle *)particle inBounds:(NSRect)bounds;
@end

@interface StaticKaleidoscopeView : KaleidoscopeView
{
}
@end
