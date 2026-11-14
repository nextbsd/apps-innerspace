#ifndef TOMORROW_NEVER_KNOWS_VIEW_H
#define TOMORROW_NEVER_KNOWS_VIEW_H

#include <AppKit/AppKit.h>


/*
 * Tomorrow Never Knows: turn off your mind, relax and float
 * downstream. A kaleidoscope of six mirrored sectors whose colours
 * swirl through a 1966 palette, breathing slowly in and out, drawn
 * entirely by a fragment shader on the GPU: nothing is drawn on the CPU
 * and nothing is kept between frames. Without hardware OpenGL it shows
 * a still, so it never costs the CPU a whole screen per frame.
 */
@interface TomorrowNeverKnowsView : NSView
{
  NSOpenGLContext *context;
  unsigned int program;
  int uTime, uAspect, uBreath;
  BOOL tried;
  BOOL isES;
  NSTimeInterval start;
  id frameTarget;
  SEL frameAction;
}
@end

#endif
