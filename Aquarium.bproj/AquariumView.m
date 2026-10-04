#include "AquariumView.h"
#include <math.h>

static NSColor *WaterColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a)
{
  return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
}

static void Oval(CGFloat x, CGFloat y, CGFloat w, CGFloat h, NSColor *color)
{
  [color set];
  [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x,y,w,h)] fill];
}

static void Gradient(NSBezierPath *path, NSColor *top, NSColor *bottom)
{
  NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:bottom endingColor:top];
  [gradient drawInBezierPath:path angle:90];
  [gradient release];
}

static NSBezierPath *Triangle(NSPoint a, NSPoint b, NSPoint c)
{
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path moveToPoint:a]; [path lineToPoint:b]; [path lineToPoint:c]; [path closePath];
  return path;
}

// All fish face right in their own coordinate system. The host transform mirrors
// the entire fish, including its fins and eye, for leftward swimming.
static void Fish(int species, double beat)
{
  NSColor *bright, *dark;
  if (species == 0) {
    bright=WaterColor(1,.66,.16,1); dark=WaterColor(.77,.16,.035,1);
  } else if (species == 1) {
    bright=WaterColor(.22,.81,.97,1); dark=WaterColor(.025,.19,.58,1);
  } else {
    bright=WaterColor(1,.9,.30,1); dark=WaterColor(.80,.43,.055,1);
  }
  CGFloat tall = species == 2 ? 27 : 19;
  CGFloat flutter = 5*sin(beat);
  NSBezierPath *tail=Triangle(NSMakePoint(-25,0),NSMakePoint(-53,22+flutter),NSMakePoint(-53,-22-flutter));
  Gradient(tail,bright,dark);
  [WaterColor(1,.9,.55,.32) set];
  for (int j=-2;j<=2;j++) {
    NSBezierPath *ray=[NSBezierPath bezierPath];
    [ray moveToPoint:NSMakePoint(-28,0)];
    [ray lineToPoint:NSMakePoint(-51,j*(9+flutter*.35))];
    [ray setLineWidth:.7]; [ray stroke];
  }
  NSBezierPath *fin=Triangle(NSMakePoint(-22,11),NSMakePoint(-11,tall+19),NSMakePoint(20,12));
  Gradient(fin,bright,dark);
  Gradient(Triangle(NSMakePoint(-12,-13),NSMakePoint(-20,-tall-12),NSMakePoint(18,-12)),bright,dark);
  NSBezierPath *body=[NSBezierPath bezierPath];
  [body moveToPoint:NSMakePoint(-32,0)];
  [body curveToPoint:NSMakePoint(36,1) controlPoint1:NSMakePoint(-15,tall*1.65) controlPoint2:NSMakePoint(25,tall*1.3)];
  [body curveToPoint:NSMakePoint(-32,0) controlPoint1:NSMakePoint(27,-tall*1.5) controlPoint2:NSMakePoint(-13,-tall*1.3)];
  [body closePath];
  Gradient(body,bright,dark);
  [NSGraphicsContext saveGraphicsState];
  [body addClip];
  if (species == 0) {
    for (int j=0;j<3;j++) {
      CGFloat x=-22+j*21;
      NSBezierPath *stripe=[NSBezierPath bezierPath];
      [stripe moveToPoint:NSMakePoint(x-2,-30)];
      [stripe curveToPoint:NSMakePoint(x,30) controlPoint1:NSMakePoint(x+9,-8) controlPoint2:NSMakePoint(x-6,10)];
      [WaterColor(.22,.12,.09,1) set]; [stripe setLineWidth:11]; [stripe stroke];
      [WaterColor(1,.96,.82,1) set]; [stripe setLineWidth:7]; [stripe stroke];
    }
  } else if (species == 1) {
    Oval(-23,-4,50,10,WaterColor(.025,.08,.23,.85));
    Oval(-21,3,42,3,WaterColor(.3,1,1,.8));
  } else {
    for (int j=0;j<4;j++) Oval(-21+j*12,-26,5,55,WaterColor(.42,.24,.035,.34));
  }
  Oval(-15,9,36,6,WaterColor(1,1,.9,.16));
  [NSGraphicsContext restoreGraphicsState];
  NSBezierPath *gill=[NSBezierPath bezierPath];
  [gill moveToPoint:NSMakePoint(15,11)];
  [gill curveToPoint:NSMakePoint(15,-11) controlPoint1:NSMakePoint(10,4) controlPoint2:NSMakePoint(11,-5)];
  [dark set]; [gill setLineWidth:1]; [gill stroke];
  [WaterColor(1,.86,.52,.55) set];
  [Triangle(NSMakePoint(9,-2),NSMakePoint(-8,-5-flutter),NSMakePoint(-3,-15)) fill];
  Oval(21,3,8,8,WaterColor(1,.96,.77,1));
  Oval(23,4,4.8,5.5,WaterColor(.015,.025,.035,1));
  Oval(25,7,1.6,1.6,[NSColor whiteColor]);
}

@implementation AquariumView
- (BOOL)isOpaque { return YES; }
- (BOOL)useBufferedWindow { return YES; }
- (NSTimeInterval)animationDelayTime { return 1.0/30.0; }
- (NSString *)windowTitle { return @"Aquarium"; }
- (void)oneStep
{
  elapsed += 1.0/30.0;
#if defined(__APPLE__) && !defined(GNUSTEP)
  [self drawRect:[self bounds]];
#else
  [self setNeedsDisplay:YES];
  [self display];
#endif
}

- (void)drawRect:(NSRect)dirtyRect
{
  NSRect bounds=[self bounds];
  if (NSWidth(bounds)<=0 || NSHeight(bounds)<=0) return;
  [NSGraphicsContext saveGraphicsState];
  NSRectClip(bounds);
  CGFloat scale=NSHeight(bounds)/600.0, width=NSWidth(bounds)/scale;
  NSAffineTransform *scene=[NSAffineTransform transform];
  [scene translateXBy:NSMinX(bounds) yBy:NSMinY(bounds)];
  [scene scaleBy:scale]; [scene concat];
  Gradient([NSBezierPath bezierPathWithRect:NSMakeRect(0,0,width,600)],
    WaterColor(.035,.32,.39,1),WaterColor(.008,.035,.10,1));

  // Translucent shafts of surface light drift very slowly over the tank.
  for (int i=0;i<7;i++) {
    CGFloat x=width*(i/6.0)+22*sin(elapsed*.16+i);
    [WaterColor(.43,.93,.86,.035) set];
    [Triangle(NSMakePoint(x,620),NSMakePoint(x-190,45),NSMakePoint(x+60,45)) fill];
  }
  for (int i=0;i<55;i++) {
    CGFloat x=fmod(i*137.31+elapsed*(1+i%3),width+20)-10;
    CGFloat y=65+fmod(i*73.13+elapsed*(2+i%4),535);
    Oval(x,y,1.5,1.5,WaterColor(.60,.94,.88,.20));
  }
  NSBezierPath *sand=[NSBezierPath bezierPath];
  [sand moveToPoint:NSMakePoint(0,0)]; [sand lineToPoint:NSMakePoint(0,47)];
  for (CGFloat x=0;x<=width+20;x+=20)
    [sand lineToPoint:NSMakePoint(x,43+7*sin(x*.008)+3*sin(x*.024))];
  [sand lineToPoint:NSMakePoint(width+20,0)]; [sand closePath];
  Gradient(sand,WaterColor(.39,.39,.26,1),WaterColor(.12,.17,.16,1));
  for (int i=0;i<160;i++) {
    CGFloat x=fmod(i*71.71,width), y=5+fmod(i*13.37,29);
    Oval(x,y,2+i%3,1.2,WaterColor(.73,.70,.46,.25));
  }

  // Rooted ribbon plants sway more at their tips than at the gravel line.
  for (int clump=0;clump<7;clump++) {
    CGFloat root=width*(clump/6.0)+15*sin(clump*23);
    for (int leaf=0;leaf<7;leaf++) {
      CGFloat x=root+(leaf-3)*12, height=75+100*(.5+.5*sin(clump*7+leaf*3.8));
      CGFloat sway=17*sin(elapsed*.65+clump+leaf*.5);
      NSBezierPath *blade=[NSBezierPath bezierPath];
      [blade moveToPoint:NSMakePoint(x-5,32)];
      [blade curveToPoint:NSMakePoint(x+sway,32+height) controlPoint1:NSMakePoint(x-20,60+height*.3) controlPoint2:NSMakePoint(x+sway-18,height)];
      [blade curveToPoint:NSMakePoint(x+5,32) controlPoint1:NSMakePoint(x+sway+7,height*.8) controlPoint2:NSMakePoint(x+14,65)];
      [blade closePath];
      Gradient(blade,WaterColor(.16,.48+leaf*.018,.29,1),WaterColor(.025,.16,.14,1));
    }
    for (int stone=0;stone<3;stone++) {
      NSBezierPath *rock=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(root-32+stone*23,24,38+stone*6,20+stone*7)];
      Gradient(rock,WaterColor(.26,.34,.32,1),WaterColor(.075,.12,.15,1));
    }
  }

  // Distribute independent swimming lanes across the full aspect ratio.
  int count=MIN(24,MAX(7,(int)(width/95)));
  for (int i=0;i<count;i++) {
    CGFloat size=.52+.12*(i%5), speed=14+(i%4)*6;
    CGFloat x=fmod(width*(i+.5)/count+elapsed*speed,width+180)-90;
    BOOL left=(i%3==0);
    if (left) x=width-x;
    CGFloat y=145+fmod(i*113.7,370)+10*sin(elapsed*.65+i*2);
    [NSGraphicsContext saveGraphicsState];
    NSAffineTransform *swim=[NSAffineTransform transform];
    [swim translateXBy:x yBy:y];
    [swim scaleXBy:left ? -size : size yBy:size];
    [swim rotateByDegrees:2*sin(elapsed*1.2+i)]; [swim concat];
    Fish(i%3,elapsed*(4+i%3)+i);
    [NSGraphicsContext restoreGraphicsState];
  }
  for (int i=0;i<30;i++) {
    CGFloat y=40+fmod(i*37.7+elapsed*(24+i%5*5),590);
    CGFloat x=width*(i%2 ? .86 : .13)+8*sin(y*.025+i)+i%4*5;
    CGFloat radius=2+i%4;
    NSBezierPath *bubble=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x,y,radius*2,radius*2)];
    [WaterColor(.60,.91,.94,.32) set]; [bubble setLineWidth:.8]; [bubble stroke];
    Oval(x+radius*.4,y+radius*1.2,1.5,1.5,WaterColor(.85,1,1,.65));
  }
  [NSGraphicsContext restoreGraphicsState];
}
@end

@implementation StaticAquariumView
@end
