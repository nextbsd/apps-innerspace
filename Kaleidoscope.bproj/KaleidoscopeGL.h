#ifndef KALEIDOSCOPE_GL_H
#define KALEIDOSCOPE_GL_H

#include <AppKit/AppKit.h>

/* One particle as drawn at a step: where, how big (the pulse applied)
   and its hue. Points, from the centre of the view. */
typedef struct kaleidoscope_disc
{
  float x;
  float y;
  float radius;
  float hue;
} KaleidoscopeDisc;

/*
 * Kaleidoscope on the GPU, with an NSOpenGLContext on the view.
 *
 * The CPU version darkens the whole window by 12% every step and draws
 * the particles over it, so each disc fades by 0.88 a step. Fading
 * commutes with drawing over, so the same picture is every disc of the
 * last steps drawn oldest first over black, each with its colour (not
 * its coverage) scaled by 0.88 per step of age. The renderer keeps the
 * discs of the last 64 steps in a vertex buffer (a ring; each step adds
 * its 18 particles, in the 16 mirrored copies), and draws each frame
 * from scratch: no full-window fade, no copy of the last frame, nothing
 * read back. The discs are point sprites; the fragment shader draws the
 * antialiased fill and its 1-point outline.
 *
 * Between steps, the newest step's discs glide toward the next step's
 * with their opacity growing from nothing (the "head"), so frames
 * drawn at the display's rate move smoothly while the trails stay the
 * CPU version's.
 */
@interface KaleidoscopeGL : NSObject
{
  NSView *view;			/* not retained: it owns us */
  NSOpenGLContext *context;
  NSString *rendererName;
  unsigned int program;
  unsigned int ring;		/* vertex buffer of the steps' discs */
  unsigned int headBuffer;
  int uHalfSize, uPixels, uNow, uRing;
  int stamps;			/* steps in the ring */
  int newest;			/* slot of the newest */
  double stampStep[64];
  BOOL isES;
  NSTimeInterval lastFlush;
}

/* nil without hardware OpenGL (KaleidoscopeAllowSoftwareOpenGL
   allows a software renderer). */
- (id)initWithView:(NSView *)aView;
- (NSOpenGLContext *)context;
- (NSString *)rendererName;
/* Forget the trails (a new size). */
- (void)reset;
/* The discs of step `step`, count of them. */
- (void)addStep:(double)step discs:(const KaleidoscopeDisc *)discs
          count:(int)count;
/* Draw the steps up to `now` (in steps) and the head (weight 0..1 of a
   full step), and present the frame. NO if drawing failed. */
- (BOOL)drawAt:(double)now head:(const KaleidoscopeDisc *)head
         count:(int)count weight:(float)weight;
/* YES while the last frame isn't on screen yet (the NextBSD backend
   says; NO elsewhere). */
- (BOOL)framePending;
/* Have selector sent to target (with the context) once each presented
   frame is on screen, where the context can say (the NextBSD backend's
   frame callbacks); NO where it can't. A nil target stops it. */
- (BOOL)setFrameTarget:(id)target selector:(SEL)selector;
- (NSTimeInterval)lastFlush;
/* Leave the view (the GL objects go with the context). */
- (void)invalidate;
@end

#endif
