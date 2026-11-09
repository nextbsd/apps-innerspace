#include "BoxesView.h"
#include <stdlib.h>

#define RAND  ((float)rand()/(float)RAND_MAX)

@implementation BoxesView

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self != nil)
    {
      randomAngles = [[NSUserDefaults standardUserDefaults]
        boolForKey: @"BoxesRandomAngles"];
    }
  return self;
}

- (void)dealloc
{
  RELEASE(inspectorView);
  DEALLOC;
}

- (NSView *)inspector:(id)sender
{
  if (inspectorView == nil)
    {
      NSButton *button;

      inspectorView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 220, 50)];
      button = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(10, 14, 200, 22)]);
      [button setButtonType: NSSwitchButton];
      [button setTitle: @"Random angles"];
      [button setState: randomAngles ? NSOnState : NSOffState];
      [button setTarget: self];
      [button setAction: @selector(setRandomAngles:)];
      [inspectorView addSubview: button];
    }
  return inspectorView;
}

- (void)setRandomAngles:(id)sender
{
  randomAngles = [sender state] == NSOnState;
  [[NSUserDefaults standardUserDefaults] setBool: randomAngles
                                         forKey: @"BoxesRandomAngles"];
}

//
// Initialization
//
- (BOOL)useBufferedWindow
{
  return NO;
}

//
// The Graphics Code
//
- (void)drawRect:(NSRect)rects
{
  [[NSColor blackColor] set];
  NSRectFill(rects);
}

- (void)oneStep
{
  float x = 0, y = 0, w = 0, h = 0;
  float r = 0, g = 0, b = 0, a = 0;
  NSRect rect; 
#if defined(__APPLE__) && !defined(GNUSTEP)
  NSRect frame = [self bounds];
#else
  NSRect frame = [[NSScreen mainScreen] frame];
#endif
  
  // size and position...
  x = RAND * frame.size.width;
  y = RAND * frame.size.height;
  w = RAND * (frame.size.width - x);
  h = RAND * (frame.size.height - y);

  // color and opacity...
  r = RAND; // 0..1
  g = RAND; // 0..1
  b = RAND; // 0..1
  a = RAND; // 0..1
  // NSLog(@"%f %f %f %f     %f %f %f %f",x,y,w,h,r,g,b,a);
  rect = NSMakeRect(x,y,w,h);
  [[NSColor colorWithCalibratedRed: r green: g blue: b alpha: a] set];
  if (randomAngles)
    {
      NSBezierPath *path = [NSBezierPath bezierPathWithRect: rect];
      NSAffineTransform *transform = [NSAffineTransform transform];

      [transform translateXBy: NSMidX(rect) yBy: NSMidY(rect)];
      [transform rotateByDegrees: RAND * 360.0];
      [transform translateXBy: -NSMidX(rect) yBy: -NSMidY(rect)];
      [path transformUsingAffineTransform: transform];
      [path fill];
    }
  else
    {
      NSRectFill(rect);
    }
}

@end

//
// Static view...
//
@implementation StaticBoxesView

- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect:rects];
}

@end
