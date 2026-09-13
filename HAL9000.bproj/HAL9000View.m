#include "HAL9000View.h"
#include <math.h>

static NSColor *HALColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a)
{
  return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
}

static void HALFill(NSRect rect, NSColor *color)
{
  [color set];
  NSRectFill(rect);
}

static void HALLine(CGFloat x, CGFloat y, CGFloat xx, CGFloat yy)
{
  NSBezierPath *path = [NSBezierPath bezierPath];
  [path moveToPoint:NSMakePoint(x, y)];
  [path lineToPoint:NSMakePoint(xx, yy)];
  [path setLineWidth:0.7];
  [path stroke];
}

static void HALEllipse(CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
  NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(x,y,w,h)];
  [path setLineWidth:0.7];
  [path stroke];
}

@implementation HAL9000View

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    NSFont *font = [NSFont userFixedPitchFontOfSize:8];
    if (!font) font = [NSFont systemFontOfSize:8];
    smallAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
      HALColor(0.91,0.95,0.90,0.9), NSForegroundColorAttributeName, nil] retain];
    titleAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
      [NSFont boldSystemFontOfSize:48], NSFontAttributeName,
      HALColor(0.96,0.97,0.93,1), NSForegroundColorAttributeName,
      [NSNumber numberWithFloat:9], NSKernAttributeName, nil] retain];
  }
  return self;
}

- (void)dealloc
{
  [smallAttributes release];
  [titleAttributes release];
  [super dealloc];
}
- (BOOL)useBufferedWindow { return YES; }
- (BOOL)isOpaque { return YES; }
- (NSTimeInterval)animationDelayTime { return 0.05; }
- (NSString *)windowTitle { return @"HAL 9000"; }
- (void)oneStep
{
  frameCount = (frameCount + 1) % 28800;
  phase = frameCount * (2.0 * M_PI / 2400.0);
#if defined(__APPLE__) && !defined(GNUSTEP)
  // The Cocoa host supplies its persistent bitmap context on every step.
  [self drawRect:[self bounds]];
#else
  [self setNeedsDisplay:YES];
  [self display];
#endif
}
- (void)drawRect:(NSRect)rect
{
  HALFill(rect, HALColor(0.018,0.019,0.021,1));
  [self drawDisplayInRect:[self bounds]];
}

- (void)drawDisplayInRect:(NSRect)rect
{
  if (rect.size.width <= 0 || rect.size.height <= 0) return;
  // A fixed console coordinate system keeps typography and plots aligned at any size.
  CGFloat scale = MIN(rect.size.width / 1200.0, rect.size.height / 650.0);
  [NSGraphicsContext saveGraphicsState];
  NSAffineTransform *transform = [NSAffineTransform transform];
  [transform translateXBy:NSMidX(rect)-600*scale yBy:NSMidY(rect)-325*scale];
  [transform scaleBy:scale];
  [transform concat];
  HALFill(NSMakeRect(22,39,1156,572), HALColor(0.035,0.036,0.039,1));
  for (int i=0; i<8; i++) {
    int column = i % 4;
    CGFloat x = 44 + column * 252 + (column >= 2 ? 110 : 0);
    [self drawMonitor:i inRect:NSMakeRect(x, i<4 ? 332 : 76, 230,240)];
  }
  [self drawHalEyeInRect:NSMakeRect(551,176,98,290)];
  [@"D I S C O V E R Y   O N E" drawAtPoint:NSMakePoint(44,592) withAttributes:smallAttributes];
  [@"MISSION OPERATIONS / 9000 SERIES" drawAtPoint:NSMakePoint(922,592) withAttributes:smallAttributes];
  [@"ONBOARD SYSTEMS     /     CONTINUOUS TELEMETRY" drawAtPoint:NSMakePoint(44,51) withAttributes:smallAttributes];
  [NSGraphicsContext restoreGraphicsState];
}

- (void)drawMonitor:(int)index inRect:(NSRect)rect
{
  static const CGFloat palette[8][3] = {
    {0.30,0.19,0.36}, {0.16,0.36,0.39}, {0.15,0.28,0.43}, {0.24,0.30,0.57},
    {0.25,0.25,0.29}, {0.20,0.25,0.48}, {0.53,0.12,0.17}, {0.40,0.27,0.13}
  };
  NSString *codes[] = {@"NAV",@"ATM",@"MEM",@"SRV",@"POD",@"NUC",@"ECS",@"PWR"};
  NSString *ids[] = {@"STA: 35-05",@"MRN: 80-EJ",@"MEM: 09-64",@"URN: BC-EJ",
    @"POD: 0820",@"AE: 35-19",@"ECS: 0607",@"PWR: RNGR"};
  HALFill(NSInsetRect(rect,-5,-5), [NSColor blackColor]);
  [NSGraphicsContext saveGraphicsState];
  NSAffineTransform *transform = [NSAffineTransform transform];
  [transform translateXBy:rect.origin.x yBy:rect.origin.y];
  [transform concat];
  NSRectClip(NSMakeRect(0,0,230,240));
  HALFill(NSMakeRect(0,0,230,240), HALColor(palette[index][0],palette[index][1],palette[index][2],1));
  // Stagger changes; detailed plots and quiet identification cards always coexist.
  BOOL graphic = (index==1 || index==4 || index==6 ||
    ((index==0 || index==2 || index==3) && ((frameCount/240 + index)%3 != 0)));
  if (graphic) {
    [ids[index] drawAtPoint:NSMakePoint(13,219) withAttributes:smallAttributes];
    [codes[index] drawAtPoint:NSMakePoint(195,219) withAttributes:smallAttributes];
    [HALColor(0.89,0.95,0.9,0.65) set];
    HALLine(13,211,217,211);
    [self drawGraphic:index];
    [[NSString stringWithFormat:@"SEQ %04u    CH %02d   /   ONLINE",frameCount/20,index+1]
      drawAtPoint:NSMakePoint(13,13) withAttributes:smallAttributes];
  } else {
    [ids[index] drawAtPoint:NSMakePoint(22,135) withAttributes:smallAttributes];
    [codes[index] drawAtPoint:NSMakePoint(22,75) withAttributes:titleAttributes];
  }
  [HALColor(0,0,0,0.08) set];
  for (int y=0;y<240;y+=3) NSRectFillUsingOperation(NSMakeRect(0,y,230,0.5), NSCompositeSourceOver);
  [NSGraphicsContext restoreGraphicsState];
}

- (void)drawGraphic:(int)kind
{
  [HALColor(0.88,0.96,0.9,0.65) set];
  if (kind==0) {
    // Inclined orbital paths, tracking reticle, and a moving spacecraft.
    for (int i=0;i<5;i++) HALEllipse(27+i*13,45+i*12,174-i*26,144-i*24);
    HALLine(18,117,211,117); HALLine(114,35,114,199);
    HALLine(34,49,194,185); HALLine(34,185,194,49);
    CGFloat x=114+74*cos(phase), y=117+59*sin(phase);
    HALEllipse(x-4,y-4,8,8); HALLine(x-9,y,x+9,y); HALLine(x,y-9,x,y+9);
    [@"ECLIPTIC / 003.42" drawAtPoint:NSMakePoint(22,31) withAttributes:smallAttributes];
  } else if (kind==1 || kind==3) {
    // Multi-channel atmospheric and survey oscillograms on calibrated grids.
    [HALColor(0.8,0.94,0.9,0.18) set];
    for (int x=18;x<=214;x+=14) HALLine(x,36,x,199);
    for (int y=36;y<=199;y+=13) HALLine(18,y,214,y);
    for (int channel=0;channel<4;channel++) {
      [HALColor(0.9,0.98,0.94,0.8) set];
      NSBezierPath *path=[NSBezierPath bezierPath];
      for (int i=0;i<=196;i++) {
        double t=i/196.0;
        double wave=sin(t*(19+channel*9)+phase*(channel+1))*9;
        wave+=sin(t*61-phase*2)*3;
        NSPoint p=NSMakePoint(18+i,57+channel*39+wave);
        if (!i) [path moveToPoint:p]; else [path lineToPoint:p];
      }
      [path setLineWidth:0.85]; [path stroke];
    }
  } else if (kind==2) {
    // Addressable memory banks with slowly changing occupied cells.
    for (int row=0;row<15;row++) {
      [[NSString stringWithFormat:@"%03X",row*64] drawAtPoint:NSMakePoint(13,190-row*10) withAttributes:smallAttributes];
      for (int col=0;col<24;col++) {
        double value=sin(row*7.3+col*2.1+floor(frameCount/20.0)*0.13);
        HALFill(NSMakeRect(43+col*7,192-row*10,4,5), HALColor(0.9,0.96,0.94,value>0.1 ? 0.8:0.15));
      }
    }
  } else if (kind==4) {
    // Rotating wireframe pod: latitude rings joined by longitudinal struts.
    double angle=phase*0.5;
    for (int ring=0;ring<9;ring++) {
      double latitude=-M_PI/2+0.08+ring*(M_PI-0.16)/8;
      NSBezierPath *path=[NSBezierPath bezierPath];
      for (int j=0;j<=64;j++) {
        double a=j*2*M_PI/64+angle;
        double x=cos(latitude)*cos(a), z=cos(latitude)*sin(a), y=sin(latitude);
        NSPoint p=NSMakePoint(115+77*x,119+70*(y*0.86+z*0.4));
        if (!j) [path moveToPoint:p]; else [path lineToPoint:p];
      }
      [path setLineWidth:0.65]; [path stroke];
    }
    for (int j=0;j<16;j++) {
      NSBezierPath *path=[NSBezierPath bezierPath];
      for (int i=0;i<=32;i++) {
        double lat=-M_PI/2+i*M_PI/32, a=j*M_PI/8+angle;
        NSPoint p=NSMakePoint(115+77*cos(lat)*cos(a),119+70*(sin(lat)*0.86+cos(lat)*sin(a)*0.4));
        if (!i) [path moveToPoint:p]; else [path lineToPoint:p];
      }
      [path setLineWidth:0.65]; [path stroke];
    }
    HALLine(20,119,210,119); HALLine(115,33,115,203);
  } else {
    // Perspective field of intersecting telemetry curves.
    for (int line=0;line<18;line++) {
      NSBezierPath *path=[NSBezierPath bezierPath];
      for (int i=0;i<=80;i++) {
        double t=i/80.0;
        NSPoint p=NSMakePoint(18+t*194,38+line*7+sin(t*5+phase+line*0.14)*t*32);
        if (!i) [path moveToPoint:p]; else [path lineToPoint:p];
      }
      [path setLineWidth:0.65]; [path stroke];
    }
    for (int i=0;i<17;i++) HALLine(18+i*12,38,32+i*11,188);
    [@"THERMAL BALANCE / 1.000" drawAtPoint:NSMakePoint(18,195) withAttributes:smallAttributes];
  }
}

- (void)drawHalEyeInRect:(NSRect)rect
{
  HALFill(NSInsetRect(rect,-3,-3), HALColor(0.38,0.39,0.4,1));
  HALFill(rect, HALColor(0.045,0.047,0.05,1));
  HALFill(NSMakeRect(rect.origin.x+6,NSMaxY(rect)-34,86,25), HALColor(0.12,0.25,0.35,1));
  [@"HAL 9000" drawAtPoint:NSMakePoint(rect.origin.x+26,NSMaxY(rect)-26) withAttributes:smallAttributes];
  CGFloat cx=NSMidX(rect), cy=NSMidY(rect)+12;
  for (int i=0;i<40;i++) {
    CGFloat radius=43-i;
    NSColor *color;
    if (i<4) color=HALColor(0.36-i*0.07,0.37-i*0.07,0.38-i*0.07,1);
    else {
      CGFloat glow=pow(i/39.0,3);
      color=HALColor(0.12+0.88*glow,0.005+0.4*pow(glow,6),0.004,1);
    }
    [color set];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx-radius,cy-radius,radius*2,radius*2)] fill];
  }
  [HALColor(1,0.83+0.08*sin(phase),0.32,1) set];
  [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx-2,cy-2,4,4)] fill];
  for (int y=0;y<26;y++) {
    [HALColor(0.3,0.31,0.32,1) set];
    HALLine(rect.origin.x+10,rect.origin.y+12+y*2,NSMaxX(rect)-10,rect.origin.y+12+y*2);
  }
}
@end

@implementation StaticHAL9000View
- (void)drawRect:(NSRect)rect
{
  NSRectClip(rect);
  [super drawRect:rect];
}
@end
