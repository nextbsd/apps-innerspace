#ifndef KALEIDOSCOPE_VIEW_H
#define KALEIDOSCOPE_VIEW_H

#include <AppKit/AppKit.h>
#include "KaleidoscopeGL.h"

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

@class KaleidoscopeGL;

@interface KaleidoscopeView : NSView
{
  KaleidoscopeParticle particles[KaleidoscopeParticleCount];
  float animationPhase;
  BOOL hasDrawnBackground;
  /* OpenGL (KaleidoscopeGL.h), when it can be had */
  KaleidoscopeGL *gl;
  BOOL glTried;
  id frameTarget;		/* the host, not retained */
  SEL frameAction;
  double glClock;		/* steps, from the wall clock */
  double glStep;		/* the newest step drawn as a stamp */
  NSTimeInterval glLastTime;
  KaleidoscopeDisc glFrom[KaleidoscopeParticleCount];	/* step glStep */
  KaleidoscopeDisc glTo[KaleidoscopeParticleCount];	/* the next step */
}
- (void)oneStep;
- (void)resetParticle:(int)index;
- (void)drawParticle:(KaleidoscopeParticle *)particle inBounds:(NSRect)bounds;
/* One step of the particles' motion. */
- (void)advanceParticles;
/* Draw a frame with OpenGL and present it; NO draws on the CPU. */
- (BOOL)renderAnimationFrame;
- (BOOL)setAnimationFrameTarget:(id)target action:(SEL)action;
@end

@interface StaticKaleidoscopeView : KaleidoscopeView
{
}
@end

#endif
