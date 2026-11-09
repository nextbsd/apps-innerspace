//  SpaceView.m
//
//  This class implements the flying starfield screen saver view.
//
//  Another variation on the space theme, slightly faster and different.


#import "Space2View.h"
#import <Foundation/Foundation.h>
#import <AppKit/PSOperators.h>
#import <AppKit/AppKit.h>
#import <math.h>

#define PI (3.141592653589)

static NSString *StarColorKey = @"Space2StarColor";
static NSString *NebulaKey = @"Space2ShowsNebula";

NSSize sizeArray[] = {{1,1},{2,1},{2,2},{3,2},{3,3},{4,3},{4,4}};

/* Seeded, smooth multiscale density fields produce unique gas and dust, without
   downloaded images or per-frame noise changes. Colors are exposure-enhanced. */
static double NebulaHash(int x, int y, unsigned int seed)
{
  unsigned int n = (unsigned int)x * 374761393u + (unsigned int)y * 668265263u + seed * 144269u;
  n = (n ^ (n >> 13)) * 1274126177u;
  return ((n ^ (n >> 16)) & 0xffffff) / 16777215.0;
}

static double NebulaNoise(double x, double y, unsigned int seed)
{
  int ix = (int)floor(x), iy = (int)floor(y);
  double fx = x - ix, fy = y - iy;
  double a, b;

  fx = fx * fx * (3 - 2 * fx);
  fy = fy * fy * (3 - 2 * fy);
  a = NebulaHash(ix, iy, seed) * (1 - fx) + NebulaHash(ix + 1, iy, seed) * fx;
  b = NebulaHash(ix, iy + 1, seed) * (1 - fx) + NebulaHash(ix + 1, iy + 1, seed) * fx;
  return a * (1 - fy) + b * fy;
}

static double NebulaFBM(double x, double y, unsigned int seed)
{
  int octave;
  double value = 0, amplitude = 0.55;

  for (octave = 0; octave < 5; octave++)
    {
      value += amplitude * NebulaNoise(x, y, seed + octave * 7919);
      x *= 2.07;
      y *= 2.07;
      amplitude *= 0.48;
    }
  return value;
}

static NSImage *CreateNebulaTexture(unsigned int seed)
{
  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: 128 pixelsHigh: 128
    bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
    colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: 512 bitsPerPixel: 32];
  NSImage *image = [[NSImage alloc] initWithSize: NSMakeSize(128, 128)];
  unsigned char *bytes = [rep bitmapData];
  int x, y;
  double elongation = 0.65 + NebulaHash(2, 7, seed) * 0.45;

  for (y = 0; y < 128; y++)
    for (x = 0; x < 128; x++)
      {
        double u = (x - 63.5) / 60.0, v = (y - 63.5) / 60.0;
        double warp = NebulaNoise(u * 2 + 8, v * 2 + 8, seed) - 0.5;
        double gas = NebulaFBM(u * 4 + 16 + warp, v * 4 + 16 - warp, seed);
        double r = hypot(u * elongation + warp * 0.3, v / elongation);
        double envelope = pow(MAX(0, 1 - r * r), 2);
        double dust = NebulaFBM(u * 7 + 30, v * 4 + 30, seed + 111);
        double lane = exp(-pow((v + 0.25 * sin(u * 5 + seed) + warp * 0.4) / 0.10, 2));
        double density = MAX(0, gas - 0.24) * 2.5 * envelope;
        double light = MIN(1, density * (1 - 0.8 * lane) * (1 - 0.65 * dust));
        double core = MAX(0, gas - 0.52) * 2;
        double blue = NebulaNoise(u * 2 + 5, v * 2 + 5, seed + 771);
        unsigned char *pixel = bytes + y * 512 + x * 4;

        /* Warm hydrogen emission with localized cool reflection/ionized gas;
           fine structure and absorption, not a uniform glowing ellipse. */
        pixel[0] = (unsigned char)(255 * MIN(1, 0.76 + core * 0.3 - blue * 0.3));
        pixel[1] = (unsigned char)(255 * MIN(1, 0.25 + core * 0.5 + blue * 0.16));
        pixel[2] = (unsigned char)(255 * MIN(1, 0.35 + core * 0.25 + blue * 0.45));
        pixel[3] = (unsigned char)(255 * MIN(0.9, light * 1.9));
        /* This bitmap initializer uses premultiplied alpha. Transparent
           pixels must carry no RGB energy, including the texture border. */
        pixel[0] = (unsigned char)(pixel[0] * pixel[3] / 255);
        pixel[1] = (unsigned char)(pixel[1] * pixel[3] / 255);
        pixel[2] = (unsigned char)(pixel[2] * pixel[3] / 255);
      }
  [image addRepresentation: rep];
  RELEASE(rep);
  return image;
}

@implementation Space2View

extern float randBetween(float a, float b);

#ifdef WIN32
#define RAND ((float)rand()/(float)RAND_MAX)

float randBetween(float lower, float upper)
{
  float result = 0.0;

  if (lower > upper)
    {
      float temp = 0.0;
      temp = lower; lower = upper; upper = temp;
    }
  result = ((upper - lower) * RAND + lower);
  printf("upper = %f, lower = %f, result = %f\n",upper,lower,result);
  return result;
}
#endif


- (void)dealloc
{
  int i;

  for (i = 0; i < MAXNEBULAE; i++) RELEASE(nebulae[i].image);
  RELEASE(inspectorView);
  DEALLOC;
}

- (NSView *)inspector:(id)sender
{
  if (inspectorView == nil)
    {
      NSTextField *label;
      NSPopUpButton *popup;
      NSButton *checkbox;

      inspectorView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 220, 140)];
      label = AUTORELEASE([[NSTextField alloc]
        initWithFrame: NSMakeRect(10, 112, 200, 20)]);
      [label setStringValue: @"Star color"];
      [label setEditable: NO];
      [label setSelectable: NO];
      [label setBordered: NO];
      [label setDrawsBackground: NO];
      [inspectorView addSubview: label];
      popup = AUTORELEASE([[NSPopUpButton alloc]
        initWithFrame: NSMakeRect(10, 80, 200, 26) pullsDown: NO]);
      [popup addItemsWithTitles: [NSArray arrayWithObjects:
        @"White", @"Random", @"Blue", @"Red", @"Blue-white", @"Yellow", @"Orange", nil]];
      [popup selectItemAtIndex: starColor];
      [popup setTarget: self];
      [popup setAction: @selector(setStarColor:)];
      [inspectorView addSubview: popup];
      checkbox = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(10, 49, 200, 24)]);
      [checkbox setButtonType: NSSwitchButton];
      [checkbox setTitle: @"Show moving nebulae"];
      [checkbox setState: showsNebula ? NSOnState : NSOffState];
      [checkbox setTarget: self];
      [checkbox setAction: @selector(setShowsNebula:)];
      [inspectorView addSubview: checkbox];
      label = AUTORELEASE([[NSTextField alloc]
        initWithFrame: NSMakeRect(10, 4, 200, 40)]);
      [label setStringValue: @"Random gas clouds at varied distances"];
      [label setFont: [NSFont systemFontOfSize: 10]];
      [label setEditable: NO];
      [label setSelectable: NO];
      [label setBordered: NO];
      [label setDrawsBackground: NO];
      [inspectorView addSubview: label];
    }
  return inspectorView;
}

- (void)setStarColor:(id)sender
{
  starColor = [sender indexOfSelectedItem];
  [[NSUserDefaults standardUserDefaults] setObject: [sender titleOfSelectedItem]
                                         forKey: StarColorKey];
  colorsChanged = YES;
  [self setNeedsDisplay: YES];
}

- (void)setShowsNebula:(id)sender
{
  showsNebula = [sender state] == NSOnState;
  [[NSUserDefaults standardUserDefaults] setBool: showsNebula forKey: NebulaKey];
  backgroundChanged = YES;
  [self resetNebulae];
  [self setNeedsDisplay: YES];
}

- (void)resetNebulae
{
  int i;
  double product = 1.0;
  double mean = [self nebulaExpectedCount];

  for (i = 0; i < MAXNEBULAE; i++) DESTROY(nebulae[i].image);
  nnebulae = 0;
  if (!showsNebula || mean <= 0) return;
  /* Poisson sky counts, capped only to bound rendering and memory costs. */
  do
    {
      product *= MAX(0.000001, randBetween(0, 1));
      if (product <= exp(-mean)) break;
      nnebulae++;
    }
  while (nnebulae < MAXNEBULAE);
  for (i = 0; i < nnebulae; i++) [self replaceNebulaAt: i initial: YES];
}

- (double)nebulaExpectedCount
{
  NSSize size = [self bounds].size;
  double aspect;

  if (size.width <= 0 || size.height <= 0) return 0;
  aspect = MAX(size.width, size.height) / MIN(size.width, size.height);
  /* WISE v2: ~8000 HII regions/candidates over 41253 square degrees.
     Illustrative field: 6 degrees on the short axis, long axis capped at 12.
     This is an all-sky infrared catalog average, not optical completeness
     or a physical nebula/star ratio. See README for selection limitations. */
  return (8000.0 / 41253.0) * 6.0 * MIN(12.0, 6.0 * aspect);
}

- (void)replaceNebulaAt:(int)index initial:(BOOL)initial
{
  NEBULA *p = &nebulae[index];
  NSSize size = [self bounds].size;
  double focal = MAX(1.0, MIN(size.width, size.height) * 0.65);

  DESTROY(p->image);
  p->seed = (unsigned int)randBetween(1, 1000000);
  p->z = initial ? cbrt(randBetween(1, 216)) : 6.0;
  p->x = randBetween(-0.46, 0.46) * size.width * p->z / focal;
  p->y = randBetween(-0.46, 0.46) * size.height * p->z / focal;
  p->radius = randBetween(0.12, 0.30);
  p->angle = randBetween(0, 2 * PI);
  p->age = initial ? 60 : 0;
  p->image = CreateNebulaTexture(p->seed);
}

- (NSRect)nebulaRectAt:(int)index
{
  NEBULA *p = &nebulae[index];
  NSRect bounds = [self bounds];
  double focal = MAX(1.0, MIN(bounds.size.width, bounds.size.height) * 0.65);
  double scale = focal / MAX(0.01, p->z);
  double diameter = 2 * p->radius * scale;

  return NSMakeRect(NSMidX(bounds) + p->x * scale - diameter / 2,
                    NSMidY(bounds) + p->y * scale - diameter / 2,
                    diameter, diameter);
}

- (void)advanceNebulae
{
  int i;
  double cosine = cos(0.012), sine = sin(0.012);

  for (i = 0; i < nnebulae; i++)
    {
      NEBULA *p = &nebulae[i];
      double x = p->x;
      /* The same roll and vanishing point as the stars; true 1/z projection
         makes nearby clouds expand and travel faster than distant clouds. */
      p->x = x * cosine - p->y * sine;
      p->y = x * sine + p->y * cosine;
      p->z -= 0.018;
      p->angle += 0.012;
      p->age++;
      if (p->z < 0.65 || !NSIntersectsRect([self nebulaRectAt: i], [self bounds]))
        [self replaceNebulaAt: i initial: NO];
    }
}

- (void)drawNebulae
{
  int i, j, order[MAXNEBULAE];

  /* Composite farther clouds first. Drawing never advances simulation state. */
  for (i = 0; i < nnebulae; i++)
    {
      order[i] = i;
      for (j = i; j > 0 && nebulae[order[j]].z > nebulae[order[j - 1]].z; j--)
        {
          int swap = order[j];
          order[j] = order[j - 1];
          order[j - 1] = swap;
        }
    }
  for (i = 0; i < nnebulae; i++)
    {
      NEBULA *p = &nebulae[order[i]];
      NSRect rect = [self nebulaRectAt: order[i]];
      NSAffineTransform *transform = [NSAffineTransform transform];
      CGFloat opacity = MIN(1.0, p->age / 45.0) * MIN(1.0, (p->z - 0.65) / 0.4);

      [NSGraphicsContext saveGraphicsState];
      [transform translateXBy: NSMidX(rect) yBy: NSMidY(rect)];
      [transform rotateByRadians: p->angle];
      [transform concat];
      [p->image drawInRect: NSMakeRect(-rect.size.width / 2, -rect.size.height / 2,
                                      rect.size.width, rect.size.height)
                 fromRect: NSMakeRect(0, 0, 128, 128)
                operation: NSCompositeSourceOver fraction: MAX(0, opacity)];
      [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)setDrawingColorForHue:(float)hue
{
  int selectedColor = starColor;

  /* Illustrative display weights, not a measured apparent-magnitude sample:
     red 70%, orange 15%, yellow 8%, white 5%, blue-white 1.8%, blue 0.2%.
     Keep the stored uniform sample so each star retains its color. */
  if (selectedColor == 1)
    {
      if (hue < 0.70f) selectedColor = 3;
      else if (hue < 0.85f) selectedColor = 6;
      else if (hue < 0.93f) selectedColor = 5;
      else if (hue < 0.98f) selectedColor = 0;
      else if (hue < 0.998f) selectedColor = 4;
      else selectedColor = 2;
    }

  switch (selectedColor)
    {
      case 2:
        [[NSColor colorWithCalibratedRed: 0.3 green: 0.55 blue: 1.0
                                  alpha: 1.0] set];
        break;
      case 3:
        [[NSColor colorWithCalibratedRed: 1.0 green: 0.3 blue: 0.3
                                  alpha: 1.0] set];
        break;
      case 4:
        [[NSColor colorWithCalibratedRed: 0.72 green: 0.83 blue: 1.0
                                  alpha: 1.0] set];
        break;
      case 5:
        [[NSColor colorWithCalibratedRed: 1.0 green: 0.9 blue: 0.55
                                  alpha: 1.0] set];
        break;
      case 6:
        [[NSColor colorWithCalibratedRed: 1.0 green: 0.6 blue: 0.3
                                  alpha: 1.0] set];
        break;
      default:
        [[NSColor whiteColor] set];
        break;
    }
}

//takes theta and distance and stuffs it into x &y for *p
- convertToXY:(STAR *)p
{
  NSRect bounds = [self bounds];
  p->draw.origin.x = floor(bounds.size.width / 2 + (p->distance * cos(p-> theta)));
  p->draw.origin.y = floor(bounds.size.height / 2 + (p->distance * sin(p-> theta)));
  return self;
}


- oneStep
{
  int i, count, starsInArray = 0;
  STAR *p;
  NSRect bounds = [self bounds];

  if (showsNebula) [self advanceNebulae];
  if (nstars < NSTARS) [self addStar];
  
  for (i=0; i<nstars; i++)
    {
      p = &stars[i];
      p->distance += p->delta;
      p->delta *= p->ddelta;
      p->theta += 0.012;
      if (p->theta > (2*PI)) p->theta -= (2*PI);
      
      [self convertToXY:p];
      
      // only draw the star if it moved > 1 pixel
      if (colorsChanged || p->draw.origin.x != p->erase.origin.x ||
	  p->draw.origin.y != p->erase.origin.y)
	{
	  // add star to the erasure array
	  b[starsInArray] = p->erase;
	  
	  if (p->changemode < 5 &&
            p->distance > p->changepoint[p->changemode])
	    {
	      (p->changemode)++;
	      p->draw.size = sizeArray[p->changemode];
	    }
	  
	  // clipping is off, so we must not draw outside view.
	  // replace stars that go too far...
	  if (p->draw.origin.x < 0 ||
	      p->draw.origin.y < 0 ||
	      p->draw.origin.x + 4 > bounds.size.width ||
	      p->draw.origin.y + 4 > bounds.size.height)
	    {
	      [self replaceStarAt:i];
	    }
	  
	  hues[starsInArray] = p->hue;
	  w[starsInArray++] = p->draw;
	  
	  p->erase = p->draw;
	}
    }
  
  if (showsNebula || backgroundChanged)
    {
      /* Restore the entire background before drawing every current star. */
      [self drawRect: bounds];
      backgroundChanged = NO;
    }
  else if (starsInArray)
    {
      count = 0;
      while (count < starsInArray)
	{
	  // You get the best performance if you put out all the stars
	  // at once.  This causes noticable flicker, so I put out 
	  // 100 of the stars per iteration.  This gives reasonable speed
	  // and flicker is hardly noticable.  Besides, stars
	  // _should_ flicker a little...
	  
	  int t = (starsInArray - count);
	  i = (t < STARSPERIT)?t:STARSPERIT;
	  
	  PSsetgray(0.0);
	  NSRectFillList(&b[count],i);
	  
	  if (starColor == 1)
            {
              int j;
              for (j = count; j < count + i; j++)
                {
                  [self setDrawingColorForHue: hues[j]];
                  NSRectFill(w[j]);
                }
            }
          else
            {
              [self setDrawingColorForHue: 0];
              NSRectFillList(&w[count], i);
            }
	  
	  count += STARSPERIT;
	}
    }
  
  colorsChanged = NO;
  return self;
}

- initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  if (self == nil) return nil;
  showsNebula = [[NSUserDefaults standardUserDefaults] boolForKey: NebulaKey];
  {
    NSString *color = [[NSUserDefaults standardUserDefaults]
      stringForKey: StarColorKey];
    if ([color isEqualToString: @"Random"]) starColor = 1;
    else if ([color isEqualToString: @"Blue"]) starColor = 2;
    else if ([color isEqualToString: @"Red"]) starColor = 3;
    else if ([color isEqualToString: @"Blue-white"]) starColor = 4;
    else if ([color isEqualToString: @"Yellow"]) starColor = 5;
    else if ([color isEqualToString: @"Orange"]) starColor = 6;
  }
  // [self allocateGState];		// For faster lock/unlockFocus
  // [self setClipping:NO];		// even faster...
  [self setRadius];
  [self resetNebulae];
  
  return self;
}

- drawRect:(NSRect)rects 
{
  int i;

  [[NSColor blackColor] set];
  NSRectFill(rects);
  if (showsNebula) [self drawNebulae];
  for (i = 0; i < nstars; i++)
    {
      [self setDrawingColorForHue: stars[i].hue];
      NSRectFill(stars[i].draw);
    }
  return self;
}

- (void) setFrame:(NSRect)rect
{
  // if (bounds.size.width == width && bounds.size.height == height) return self;
  
  [super setFrame: rect];
  [self resetNebulae];
  backgroundChanged = YES;
  [self setRadius];
  nstars = 0;
}

// only call addStar if there is room in the stars array!
- addStar
{
  [self replaceStarAt:nstars++];
  return self;
}

- replaceStarAt:(int)index
{
  float dist, t;
  int tries = 0;
  STAR *p = &stars[index];
  BOOL inBounds;
  NSRect bounds = [self bounds];
  
  do {
    p->theta = randBetween(0,(2*PI));
    
    if (tries++ < 3) p->distance = randBetween(1, radius);
    else p->distance = randBetween(1, p->distance);
    
    inBounds = YES;
    [self convertToXY:p];
    
    if (p->draw.origin.x < 0 || p->draw.origin.y < 0 ||
	p->draw.origin.x + 4 > bounds.size.width ||
	p->draw.origin.y + 4 > bounds.size.height)
      {
	inBounds = NO;
      }
  } while (!inBounds);
  
  p->hue = randBetween(0, 1);
  p->draw.size = sizeArray[0];
  
  p->delta = (0.3);
  
  //	p->ddelta = randBetween(1.0, 1.1);
  p->ddelta = randBetween(1.0, 1.15);
  
  t = randBetween(0, (0.42*radius));
  dist = MAX(20,t);
  p->changepoint[0] = p->distance + 5;			// 2nd
  p->changepoint[1] = p->changepoint[0] - 5 + dist + dist;	// 3rd
  
  p->changepoint[2] = p->changepoint[1] + dist;		// 4th
  p->changepoint[3] = p->changepoint[2] + dist;		// 5th
  p->changepoint[4] = p->changepoint[3] + dist;		// 6th
  p->changepoint[5] = 100000;				// never change to 7th
  
  p->changemode = 0;
  
  p->erase = p->draw;
  
  return self;
}

- setRadius
{
  NSRect bounds = [self bounds];

  float x = bounds.size.width;
  float y = bounds.size.height;
  radius = (sqrt(x*x + y*y))/2;
  return self;
}

@end
