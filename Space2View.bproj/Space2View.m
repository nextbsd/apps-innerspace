//  SpaceView.m
//
//  This class implements the flying starfield screen saver view.
//
//  A quiet journey through a deep starfield with optional procedural nebulae.


#import "Space2View.h"
#import <Foundation/Foundation.h>
#import <AppKit/PSOperators.h>
#import <AppKit/AppKit.h>
#import <math.h>

#define PI (3.141592653589)
/* Shared camera motion: ~90 seconds to cross the depth range at 30 fps.
   Optional roll takes about 29 minutes per revolution at that frame rate. */
#define TRAVEL_STEP (0.002)
#define SPACE_ROLL (0.00012)

static NSString *StarColorKey = @"Space2StarColor";
static NSString *NebulaKey = @"Space2ShowsNebula";
static NSString *CosmosKey = @"Space2CosmosMode";
static NSString *RotationKey = @"Space2RotatesSpace";


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

static NSImage *CreateNebulaTexture(unsigned int seed, BOOL redCloud)
{
  int side = redCloud ? 256 : 128;
  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: side pixelsHigh: side
    bitsPerSample: 8 samplesPerPixel: 4 hasAlpha: YES isPlanar: NO
    colorSpaceName: NSDeviceRGBColorSpace bytesPerRow: side * 4 bitsPerPixel: 32];
  NSImage *image = [[NSImage alloc] initWithSize: NSMakeSize(side, side)];
  unsigned char *bytes = [rep bitmapData];
  int x, y;
  double elongation = 0.65 + NebulaHash(2, 7, seed) * 0.45;

  for (y = 0; y < side; y++)
    for (x = 0; x < side; x++)
      {
        double u = (x - (side - 1) * 0.5) / (side * 0.469), v = (y - (side - 1) * 0.5) / (side * 0.469);
        double warp = NebulaNoise(u * 2 + 8, v * 2 + 8, seed) - 0.5;
        double gas = NebulaFBM(u * 4 + 16 + warp, v * 4 + 16 - warp, seed);
        double r = hypot(u * elongation + warp * 0.3, v / elongation);
        double edge = MIN(1, MAX(0, (1.0 - MAX(fabs(u), fabs(v))) / 0.30));
        double envelope = pow(MAX(0, 1 - r * r), 1.7) * edge * edge * (3 - 2 * edge);
        double dust = NebulaFBM(u * 7 + 30, v * 4 + 30, seed + 111);
        double lane = exp(-pow((v + 0.25 * sin(u * 5 + seed) + warp * 0.4) / 0.10, 2));
        double density = MAX(0, gas - 0.24) * 2.5 * envelope;
        double light = MIN(1, density * (1 - 0.8 * lane) * (1 - 0.65 * dust));
        double core = MAX(0, gas - 0.52) * 2;
        double blue = NebulaNoise(u * 2 + 5, v * 2 + 5, seed + 771);
        unsigned char *pixel = bytes + y * side * 4 + x * 4;

        /* Warm hydrogen emission with localized cool reflection/ionized gas;
           fine structure and absorption, not a uniform glowing ellipse. */
        pixel[0] = (unsigned char)(255 * MIN(1, 0.70 + core * 0.25 - blue * 0.16));
        pixel[1] = (unsigned char)(255 * MIN(1, 0.42 + core * 0.35 + blue * 0.12));
        pixel[2] = (unsigned char)(255 * MIN(1, 0.48 + core * 0.20 + blue * 0.25));
        if (redCloud)
          {
            pixel[0] = (unsigned char)(255 * MIN(1, 0.80 + core * 0.2));
            pixel[1] = (unsigned char)(255 * (0.10 + core * 0.22));
            pixel[2] = (unsigned char)(255 * (0.13 + core * 0.18));
          }
        pixel[3] = (unsigned char)(255 * MIN(0.65, light * 1.45));
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

      inspectorView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 220, 200)];
      label = AUTORELEASE([[NSTextField alloc]
        initWithFrame: NSMakeRect(10, 172, 200, 20)]);
      [label setStringValue: @"Star color"];
      [label setEditable: NO];
      [label setSelectable: NO];
      [label setBordered: NO];
      [label setDrawsBackground: NO];
      [inspectorView addSubview: label];
      popup = AUTORELEASE([[NSPopUpButton alloc]
        initWithFrame: NSMakeRect(10, 140, 200, 26) pullsDown: NO]);
      [popup addItemsWithTitles: [NSArray arrayWithObjects:
        @"White", @"Random", @"Blue", @"Red", @"Blue-white", @"Yellow", @"Orange", nil]];
      [popup selectItemAtIndex: starColor];
      [popup setTarget: self];
      [popup setAction: @selector(setStarColor:)];
      [inspectorView addSubview: popup];
      checkbox = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(10, 109, 200, 24)]);
      [checkbox setButtonType: NSSwitchButton];
      [checkbox setTitle: @"Show moving nebulae"];
      [checkbox setState: showsNebula ? NSOnState : NSOffState];
      [checkbox setTarget: self];
      [checkbox setAction: @selector(setShowsNebula:)];
      [inspectorView addSubview: checkbox];
      checkbox = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(10, 79, 200, 24)]);
      [checkbox setButtonType: NSSwitchButton];
      [checkbox setTitle: @"Rotate space view"];
      [checkbox setState: rotatesSpace ? NSOnState : NSOffState];
      [checkbox setTarget: self];
      [checkbox setAction: @selector(setRotatesSpace:)];
      [inspectorView addSubview: checkbox];
      checkbox = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(10, 49, 200, 24)]);
      [checkbox setButtonType: NSSwitchButton];
      [checkbox setTitle: @"COSMOS mode"];
      [checkbox setState: cosmosMode ? NSOnState : NSOffState];
      [checkbox setTarget: self];
      [checkbox setAction: @selector(setCosmosMode:)];
      [inspectorView addSubview: checkbox];
      label = AUTORELEASE([[NSTextField alloc]
        initWithFrame: NSMakeRect(10, 4, 200, 40)]);
      [label setStringValue: @"COSMOS: slow travel through large red nebulae"];
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

- (void)setCosmosMode:(id)sender
{
  int i;

  cosmosMode = [sender state] == NSOnState;
  [[NSUserDefaults standardUserDefaults] setBool: cosmosMode forKey: CosmosKey];
  /* Rebuild only when switching styles; each style reuses textures in flight. */
  for (i = 0; i < MAXNEBULAE; i++) DESTROY(nebulae[i].image);
  backgroundChanged = YES;
  nstars = 0;
  [self resetNebulae];
  [self setNeedsDisplay: YES];
}

- (void)setRotatesSpace:(id)sender
{
  rotatesSpace = [sender state] == NSOnState;
  [[NSUserDefaults standardUserDefaults] setBool: rotatesSpace forKey: RotationKey];
}

- (void)resetNebulae
{
  int i;
  double product = 1.0;
  double mean = [self nebulaExpectedCount];

  /* Keep the bounded texture pool across recycling, toggles, and resizing. */
  nnebulae = 0;
  if ((!showsNebula && !cosmosMode) || mean <= 0) return;
  if (!showsNebula) mean = 0;
  /* Poisson sky counts, capped only to bound rendering and memory costs. */
  do
    {
      product *= MAX(0.000001, randBetween(0, 1));
      if (product <= exp(-mean)) break;
      nnebulae++;
    }
  while (nnebulae < MAXNEBULAE - 2);
  if (cosmosMode) nnebulae += 2;
  for (i = 0; i < nnebulae; i++)
    {
      BOOL red = cosmosMode && i >= nnebulae - 2;
      if (nebulae[i].redCloud != red) DESTROY(nebulae[i].image);
      nebulae[i].redCloud = red;
      [self replaceNebulaAt: i initial: YES];
    }
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
  unsigned int seed = (unsigned int)randBetween(1, 1000000);

  p->z = initial ? cbrt(randBetween(1, 216)) : 6.0;
  p->x = randBetween(-0.46, 0.46) * size.width * p->z / focal;
  p->y = randBetween(-0.46, 0.46) * size.height * p->z / focal;
  p->radius = randBetween(0.12, 0.30);
  if (p->redCloud)
    {
      p->z = initial ? randBetween(2.5, 4.0) : 6.0;
      p->radius = randBetween(1.9, 2.8);
      p->x = randBetween(-0.28, 0.28) * size.width * p->z / focal;
      p->y = randBetween(-0.25, 0.25) * size.height * p->z / focal;
    }
  p->angle = randBetween(0, 2 * PI);
  p->age = initial ? 180 : 0;
  if (p->image == nil)
    {
      p->seed = seed;
      p->image = CreateNebulaTexture(p->seed, p->redCloud);
    }
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

- (NSRect)nebulaDamageRectAt:(int)index
{
  NSRect rect = [self nebulaRectAt: index];
  double angle = nebulae[index].angle;
  double extent = rect.size.width * (fabs(cos(angle)) + fabs(sin(angle)));

  /* Include rotated corners and a pixel fringe for filtering, then align to
     pixel boundaries so repeated erasure leaves no partially cleared edges. */
  rect = NSIntegralRect(NSMakeRect(NSMidX(rect) - extent / 2 - 2,
                                   NSMidY(rect) - extent / 2 - 2,
                                   extent + 4, extent + 4));
  return NSIntersectionRect(rect, [self bounds]);
}

- (void)advanceNebulae
{
  int i;
  double roll = rotatesSpace ? (cosmosMode ? SPACE_ROLL : 0.012) : 0;
  double cosine = cos(roll), sine = sin(roll);

  for (i = 0; i < nnebulae; i++)
    {
      NEBULA *p = &nebulae[i];
      double x = p->x;
      /* The same roll and vanishing point as the stars; true 1/z projection
         makes nearby clouds expand and travel faster than distant clouds. */
      p->x = x * cosine - p->y * sine;
      p->y = x * sine + p->y * cosine;
      p->z -= cosmosMode ? TRAVEL_STEP : 0.018;
      p->angle += roll;
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
      CGFloat opacity = MIN(1.0, p->age / 180.0) * MIN(1.0, (p->z - 0.65) / 0.4);

      [NSGraphicsContext saveGraphicsState];
      NSRectClip([self nebulaDamageRectAt: order[i]]);
      [transform translateXBy: NSMidX(rect) yBy: NSMidY(rect)];
      [transform rotateByRadians: p->angle];
      [transform concat];
      [p->image drawInRect: NSMakeRect(-rect.size.width / 2, -rect.size.height / 2,
                                      rect.size.width, rect.size.height)
                 fromRect: NSMakeRect(0, 0, [p->image size].width, [p->image size].height)
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
        [[NSColor colorWithCalibratedRed: (cosmosMode ? 0.62 : 0.3) green: (cosmosMode ? 0.73 : 0.55) blue: (cosmosMode ? 0.94 : 1.0)
                                  alpha: 1.0] set];
        break;
      case 3:
        [[NSColor colorWithCalibratedRed: (cosmosMode ? 0.92 : 1.0) green: (cosmosMode ? 0.65 : 0.3) blue: (cosmosMode ? 0.58 : 0.3)
                                  alpha: 1.0] set];
        break;
      case 4:
        [[NSColor colorWithCalibratedRed: (cosmosMode ? 0.77 : 0.72) green: 0.83 blue: (cosmosMode ? 0.94 : 1.0)
                                  alpha: 1.0] set];
        break;
      case 5:
        [[NSColor colorWithCalibratedRed: (cosmosMode ? 0.94 : 1.0) green: (cosmosMode ? 0.88 : 0.9) blue: (cosmosMode ? 0.69 : 0.55)
                                  alpha: 1.0] set];
        break;
      case 6:
        [[NSColor colorWithCalibratedRed: (cosmosMode ? 0.94 : 1.0) green: (cosmosMode ? 0.75 : 0.6) blue: (cosmosMode ? 0.56 : 0.3)
                                  alpha: 1.0] set];
        break;
      default:
        [[NSColor colorWithCalibratedWhite: (cosmosMode ? 0.86 : 1.0) alpha: 1.0] set];
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
  int i, starsInArray = 0;
  STAR *p;
  NSRect bounds = [self bounds];

  NSRect damage[NSTARS + 2 * MAXNEBULAE];
  int damageCount = 0;

  if (showsNebula || cosmosMode)
    {
      /* Clear previous star positions and both previous/current cloud bounds.
         All current clouds are fully cleared before alpha compositing once. */
      for (i = 0; i < nstars; i++) damage[damageCount++] = stars[i].draw;
      for (i = 0; i < nnebulae; i++) damage[damageCount++] = [self nebulaDamageRectAt: i];
      [self advanceNebulae];
      for (i = 0; i < nnebulae; i++) damage[damageCount++] = [self nebulaDamageRectAt: i];
    }
  if (cosmosMode)
    {
      while (nstars < NSTARS) [self addStar];
    }
  else if (nstars < NSTARS) [self addStar];
  
  for (i=0; i<nstars; i++)
    {
      p = &stars[i];
      /* Perspective velocity depends on depth, not runaway acceleration.
         Distant stars barely drift; nearby stars pass gradually outward. */
      if (cosmosMode)
        {
          p->delta = p->distance * TRAVEL_STEP / MAX(0.01, p->depth - TRAVEL_STEP);
          p->depth -= TRAVEL_STEP;
        }
      else p->delta *= p->ddelta;
      p->distance += p->delta;
      if (rotatesSpace) p->theta += cosmosMode ? SPACE_ROLL : 0.012;
      if (p->theta > (2*PI)) p->theta -= (2*PI);
      
      [self convertToXY:p];
      
      // only draw the star if it moved > 1 pixel
      if (colorsChanged || (cosmosMode && p->depth < 0.8) || p->draw.origin.x != p->erase.origin.x ||
	  p->draw.origin.y != p->erase.origin.y)
	{
	  // add star to the erasure array
	  b[starsInArray] = p->erase;
	  
          {
            double size = cosmosMode ? (p->depth < 2.0 ? 2 : 1)
                                     : MIN(4, 1 + floor(p->delta / 2));
            p->draw.size = NSMakeSize(size, size);
          }

	  // clipping is off, so we must not draw outside view.
	  // replace stars that go too far...
	  if ((cosmosMode && p->depth < 0.8) || p->draw.origin.x < 0 ||
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
  
  if (backgroundChanged)
    {
      /* Restore the entire background before drawing every current star. */
      [self drawRect: bounds];
      backgroundChanged = NO;
    }
  else if (showsNebula || cosmosMode)
    {
      [[NSColor blackColor] set];
      NSRectFillList(damage, damageCount);
      [self drawNebulae];
      [self drawStars];
    }
  else if (starsInArray)
    {
      /* Erase all old positions first, then restore even stationary stars
         that shared a pixel with a moving one. */
      PSsetgray(0.0);
      NSRectFillList(b, starsInArray);
      [self drawStars];
    }

  colorsChanged = NO;
  return self;
}

- initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  if (self == nil) return nil;
  cosmosMode = [[NSUserDefaults standardUserDefaults] boolForKey: CosmosKey];
  showsNebula = [[NSUserDefaults standardUserDefaults] boolForKey: NebulaKey];
  rotatesSpace = [[NSUserDefaults standardUserDefaults] boolForKey: RotationKey];
  backgroundChanged = YES;
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

- (void)drawStars
{
  int i;
  NSRect rects[NSTARS];

  if (starColor != 1)
    {
      [self setDrawingColorForHue: 0];
      for (i = 0; i < nstars; i++) rects[i] = stars[i].draw;
      if (nstars) NSRectFillList(rects, nstars);
    }
  else
    {
      for (i = 0; i < nstars; i++)
        {
          [self setDrawingColorForHue: stars[i].hue];
          NSRectFill(stars[i].draw);
        }
    }
}

- drawRect:(NSRect)rects
{
  [NSGraphicsContext saveGraphicsState];
  NSRectClip(rects);
  [[NSColor blackColor] set];
  NSRectFill(rects);
  if (showsNebula || cosmosMode) [self drawNebulae];
  [self drawStars];
  [NSGraphicsContext restoreGraphicsState];
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
  /* Fill the initial view across depths; recycled stars arrive far away. */
  p->depth = backgroundChanged ? cbrt(randBetween(1, 216)) : 6.0;
  p->draw.size = NSMakeSize(p->depth < 2.0 ? 2 : 1, p->depth < 2.0 ? 2 : 1);
  p->delta = cosmosMode ? p->distance * TRAVEL_STEP / p->depth : 0.3;
  p->ddelta = randBetween(1.0, 1.15);
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
