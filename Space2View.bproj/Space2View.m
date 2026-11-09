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

NSSize sizeArray[] = {{1,1},{2,1},{2,2},{3,2},{3,3},{4,3},{4,4}};

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
  RELEASE(inspectorView);
  DEALLOC;
}

- (NSView *)inspector:(id)sender
{
  if (inspectorView == nil)
    {
      NSTextField *label;
      NSPopUpButton *popup;

      inspectorView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 220, 70)];
      label = AUTORELEASE([[NSTextField alloc]
        initWithFrame: NSMakeRect(10, 42, 200, 20)]);
      [label setStringValue: @"Star color"];
      [label setEditable: NO];
      [label setSelectable: NO];
      [label setBordered: NO];
      [label setDrawsBackground: NO];
      [inspectorView addSubview: label];
      popup = AUTORELEASE([[NSPopUpButton alloc]
        initWithFrame: NSMakeRect(10, 10, 200, 26) pullsDown: NO]);
      [popup addItemsWithTitles: [NSArray arrayWithObjects:
        @"White", @"Random", @"Blue", @"Red", nil]];
      [popup selectItemAtIndex: starColor];
      [popup setTarget: self];
      [popup setAction: @selector(setStarColor:)];
      [inspectorView addSubview: popup];
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

- (void)setDrawingColorForHue:(float)hue
{
  switch (starColor)
    {
      case 1:
        [[NSColor colorWithCalibratedHue: hue saturation: 0.65
                             brightness: 1.0 alpha: 1.0] set];
        break;
      case 2:
        [[NSColor colorWithCalibratedRed: 0.3 green: 0.55 blue: 1.0
                                  alpha: 1.0] set];
        break;
      case 3:
        [[NSColor colorWithCalibratedRed: 1.0 green: 0.3 blue: 0.3
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
  
  if (starsInArray)
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
  {
    NSString *color = [[NSUserDefaults standardUserDefaults]
      stringForKey: StarColorKey];
    if ([color isEqualToString: @"Random"]) starColor = 1;
    else if ([color isEqualToString: @"Blue"]) starColor = 2;
    else if ([color isEqualToString: @"Red"]) starColor = 3;
  }
  // [self allocateGState];		// For faster lock/unlockFocus
  // [self setClipping:NO];		// even faster...
  [self setRadius];
  
  return self;
}

- drawRect:(NSRect)rects 
{
  int i;

  [[NSColor blackColor] set];
  NSRectFill(rects);
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
