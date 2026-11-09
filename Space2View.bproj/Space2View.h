#import <AppKit/AppKit.h>

#define NSTARS (200)
#define STARSPERIT (100)
#define MAXNEBULAE (32)

typedef struct STAR {
	float hue;
	float theta;	// angle
	float distance;
	float delta;	// change in distance
	float ddelta;
	float depth;	// camera-space depth for gentle perspective travel
	int changemode;

	
	NSRect draw;
	NSRect erase;
	
	} STAR;

typedef struct NEBULA {
  double x, y, z, radius, angle;
  unsigned int seed;
  int age;
  BOOL redCloud;
  NSImage *image;
} NEBULA;

@interface Space2View:NSView
{
	STAR stars[NSTARS];
	int nstars;
	int radius;			// min radius of this view

	NSRect b[NSTARS];
	NSRect w[NSTARS];
	float hues[NSTARS];
	int starColor;
	BOOL colorsChanged;
	BOOL showsNebula;
	BOOL cosmosMode;
	BOOL rotatesSpace;
	BOOL backgroundChanged;
	NEBULA nebulae[MAXNEBULAE];
	int nnebulae;
	NSView *inspectorView;
}

- convertToXY:(STAR *)p;
- oneStep;
- drawRect:(NSRect)rects;
- (void)setFrame: (NSRect)rect;
- addStar;
- replaceStarAt:(int)index;
- setRadius;
- (NSView *)inspector:(id)sender;
- (void)setStarColor:(id)sender;
- (void)setShowsNebula:(id)sender;
- (void)setCosmosMode:(id)sender;
- (void)setRotatesSpace:(id)sender;
- (NSRect)nebulaDamageRectAt:(int)index;
- (void)drawStars;
- (void)resetNebulae;
- (double)nebulaExpectedCount;
- (void)replaceNebulaAt:(int)index initial:(BOOL)initial;
- (NSRect)nebulaRectAt:(int)index;
- (void)advanceNebulae;
- (void)drawNebulae;
- (void)setDrawingColorForHue:(float)hue;

@end
