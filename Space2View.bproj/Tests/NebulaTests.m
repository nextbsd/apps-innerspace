#import <AppKit/AppKit.h>
#import "../Space2View.h"
#import <objc/runtime.h>

static void Check(BOOL condition, NSString *message)
{
  if (!condition)
    {
      NSLog(@"FAIL: %@", message);
      exit(1);
    }
}

static NSBitmapImageRep *Snapshot(NSImage *image)
{
  NSBitmapImageRep *rep;
  [image lockFocus];
  rep = AUTORELEASE([[NSBitmapImageRep alloc] initWithFocusedViewRect:
    NSMakeRect(0, 0, [image size].width, [image size].height)]);
  [image unlockFocus];
  return rep;
}

static BOOL SamePixels(NSBitmapImageRep *a, NSBitmapImageRep *b)
{
  NSInteger x, y;
  if ([a pixelsWide] != [b pixelsWide] || [a pixelsHigh] != [b pixelsHigh])
    return NO;
  for (y = 0; y < [a pixelsHigh]; y++)
    for (x = 0; x < [a pixelsWide]; x++)
      if (![[a colorAtX: x y: y] isEqual: [b colorAtX: x y: y]]) return NO;
  return YES;
}

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSBundle *bundle;
  Class viewClass;
  Space2View *view, *restored;
  NSView *inspector;
  NSButton *checkbox = nil;
  NSButton *rotation = nil;
  NSButton *cosmos = nil;
  NSPopUpButton *popup = nil;
  NSWindow *window;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSImage *canvas;
  NSBitmapImageRep *black, *nebula, *animated, *redrawn;
  NSRect frame = NSMakeRect(0, 0, 640, 360);
  NSUInteger i;

  Check(argc == 2, @"Pass the built Space2View.InnerSpace bundle path");
  [defaults removeObjectForKey: @"Space2ShowsNebula"];
  [defaults removeObjectForKey: @"Space2RotatesSpace"];
  [defaults removeObjectForKey: @"Space2CosmosMode"];
  srand(12345);
  [NSApplication sharedApplication];
  bundle = [NSBundle bundleWithPath: [NSString stringWithUTF8String: argv[1]]];
  viewClass = [bundle principalClass];
  Check(viewClass != Nil, @"Load the built bundle");
  view = [[viewClass alloc] initWithFrame: frame];
  inspector = [view inspector: nil];
  for (i = 0; i < [[inspector subviews] count]; i++)
    {
      id control = [[inspector subviews] objectAtIndex: i];
      if ([control isKindOfClass: [NSPopUpButton class]]) popup = control;
      if ([control isKindOfClass: [NSButton class]] &&
          [NSStringFromSelector([control action]) isEqualToString: @"setCosmosMode:"]) cosmos = control;
      if ([control isKindOfClass: [NSButton class]] &&
          [NSStringFromSelector([control action]) isEqualToString: @"setShowsNebula:"]) checkbox = control;
      if ([control isKindOfClass: [NSButton class]] &&
          [NSStringFromSelector([control action]) isEqualToString: @"setRotatesSpace:"]) rotation = control;
    }
  Check(cosmos != nil && [cosmos state] == NSOffState, @"COSMOS defaults off");
  Check(checkbox != nil && [checkbox state] == NSOffState, @"Default is off");
  Check(rotation != nil && [rotation state] == NSOffState, @"Calm journey defaults to no rotation");
  [rotation performClick: nil];
  Check([popup numberOfItems] == 7, @"Six fixed colors plus Random");
  for (i = 4; i <= 6; i++)
    {
      [popup selectItemAtIndex: i];
      [view setStarColor: popup];
      restored = [[viewClass alloc] initWithFrame: frame];
      Check([[restored valueForKey: @"starColor"] integerValue] == i,
            @"New color choices persist");
      RELEASE(restored);
    }
  [popup selectItemAtIndex: 0];
  [view setStarColor: popup];
  canvas = [[NSImage alloc] initWithSize: frame.size];
  [canvas lockFocus];
  [view drawRect: frame];
  [canvas unlockFocus];
  black = Snapshot(canvas);
  [cosmos performClick: nil];
  Check([defaults boolForKey: @"Space2CosmosMode"], @"COSMOS preference persists");
  Check([[view valueForKey: @"nnebulae"] intValue] == 2,
        @"COSMOS includes red clouds even without small nebulae");
  {
    NEBULA *clouds = (NEBULA *)((char *)view + ivar_getOffset(class_getInstanceVariable(viewClass, "nebulae")));
    Check(clouds[0].redCloud && [view nebulaRectAt: 0].size.width > 200,
          @"COSMOS red clouds span a substantial part of the view");
  }
  [checkbox performClick: nil];
  Check([defaults boolForKey: @"Space2ShowsNebula"], @"Enabling persists");
  [canvas lockFocus];
  [view drawRect: frame];
  [canvas unlockFocus];
  nebula = Snapshot(canvas);
  Check(!SamePixels(black, nebula), @"Procedural nebulae render");
  {
    NSRect before = [view nebulaRectAt: 0];
    NSRect after;
    double count = [[view valueForKey: @"nnebulae"] intValue];
    Check(count > 1 && count <= MAXNEBULAE, @"Multiple sparse clouds");
    Check(fabs([view nebulaExpectedCount] - 12.41) < 0.1, @"Catalog density and angular field");
    [view advanceNebulae];
    after = [view nebulaRectAt: 0];
    Check(after.size.width > before.size.width, @"Approaching cloud grows in perspective");
    Check(!NSEqualPoints(before.origin, after.origin), @"Cloud moves with starfield");
  }
  restored = [[viewClass alloc] initWithFrame: frame];
  Check([[restored valueForKey: @"cosmosMode"] boolValue], @"COSMOS restored on new view");
  Check([[restored valueForKey: @"showsNebula"] boolValue], @"New view restores setting");
  RELEASE(restored);
  [canvas lockFocus];
  for (i = 0; i < 600; i++)
    {
      [view oneStep];
      if (i % 30 == 0)
        {
          [canvas unlockFocus];
          animated = Snapshot(canvas);
          [canvas lockFocus];
          [view drawRect: frame];
          [canvas unlockFocus];
          Check(SamePixels(animated, Snapshot(canvas)), @"Incremental frames match full redraw");
          [canvas lockFocus];
        }
    }
  [canvas unlockFocus];
  animated = Snapshot(canvas);
  [canvas lockFocus];
  [view drawRect: frame];
  [canvas unlockFocus];
  redrawn = Snapshot(canvas);
  Check(SamePixels(animated, redrawn), @"Animation matches full redraw without trails");
  [[redrawn representationUsingType: NSPNGFileType properties: [NSDictionary dictionary]]
    writeToFile: @"/tmp/innerspace-nebula.png" atomically: YES];
  {
    STAR *stars = (STAR *)((char *)view + ivar_getOffset(class_getInstanceVariable(viewClass, "stars")));
    NEBULA *clouds = (NEBULA *)((char *)view + ivar_getOffset(class_getInstanceVariable(viewClass, "nebulae")));
    double theta, distance, angle, z;
    NSImage *texture = clouds[0].image;
    int index = 0;

    [view replaceNebulaAt: 0 initial: YES];
    Check(clouds[0].image == texture, @"Recycled clouds reuse cached textures");
    [rotation performClick: nil];
    Check(![defaults boolForKey: @"Space2RotatesSpace"], @"Rotation choice persists");
    restored = [[viewClass alloc] initWithFrame: frame];
    Check(![[restored valueForKey: @"rotatesSpace"] boolValue], @"Rotation restored off");
    RELEASE(restored);
    while (index < NSTARS - 1 && stars[index].delta > 0.5) index++;
    theta = stars[index].theta;
    distance = stars[index].distance;
    angle = clouds[0].angle;
    z = clouds[0].z;
    [canvas lockFocus];
    [view drawRect: frame];
    [view oneStep];
    [canvas unlockFocus];
    Check(stars[index].theta == theta && stars[index].distance > distance,
          @"Stars travel outward without rotation");
    Check(clouds[0].angle == angle && clouds[0].z < z,
          @"Clouds approach without rotation");
    animated = Snapshot(canvas);
    [canvas lockFocus];
    [view drawRect: frame];
    [canvas unlockFocus];
    Check(SamePixels(animated, Snapshot(canvas)), @"Rotation-off incremental redraw is clean");
    [rotation performClick: nil];
    [canvas lockFocus];
    [view oneStep];
    [canvas unlockFocus];
    Check(clouds[0].angle > angle && clouds[0].angle - angle < 0.001,
          @"Rotation resumes as a gentle roll");
    Check(fabs(z - clouds[0].z - 0.004) < 0.00001,
          @"Cloud travel stays slow across two frames");
    Check(stars[index].delta < 2.0, @"No runaway star acceleration");
  }
  [view setFrame: NSMakeRect(0, 0, 360, 640)];
  RELEASE(canvas);
  canvas = [[NSImage alloc] initWithSize: NSMakeSize(360, 640)];
  [canvas lockFocus];
  [view oneStep];
  [canvas unlockFocus];
  Check([[view valueForKey: @"nnebulae"] intValue] <= MAXNEBULAE,
        @"Resize maintains bounded cloud population");
  [checkbox performClick: nil];
  Check(![defaults boolForKey: @"Space2ShowsNebula"], @"Disabling persists");
  Check([[view valueForKey: @"nnebulae"] intValue] == 2, @"Red clouds remain in COSMOS");
  [cosmos performClick: nil];
  Check(![defaults boolForKey: @"Space2CosmosMode"], @"COSMOS disabling persists");
  Check([[view valueForKey: @"nnebulae"] intValue] == 0, @"All clouds cleared outside COSMOS");
  [canvas lockFocus];
  [view oneStep];
  [canvas unlockFocus];
  animated = Snapshot(canvas);
  [canvas lockFocus];
  [view drawRect: [view bounds]];
  [canvas unlockFocus];
  Check(SamePixels(animated, Snapshot(canvas)), @"Disabling removes all clouds");
  RELEASE(canvas);
  window = [[NSWindow alloc] initWithContentRect: [inspector bounds]
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setContentView: inspector];
  [window orderFront: nil];
  [window display];
  redrawn = [inspector bitmapImageRepForCachingDisplayInRect: [inspector bounds]];
  [inspector cacheDisplayInRect: [inspector bounds] toBitmapImageRep: redrawn];
  [[redrawn representationUsingType: NSPNGFileType properties: [NSDictionary dictionary]]
    writeToFile: @"/tmp/innerspace-nebula-inspector.png" atomically: YES];
  [window close];
  RELEASE(window);
  RELEASE(view);
  [defaults removeObjectForKey: @"Space2ShowsNebula"];
  [defaults removeObjectForKey: @"Space2StarColor"];
  [defaults removeObjectForKey: @"Space2RotatesSpace"];
  [defaults removeObjectForKey: @"Space2CosmosMode"];
  NSLog(@"PASS: default, toggle, persistence, 600 frames, resize, cloud removal, perspective, density, expanded palette, cached textures, and rotation");
  RELEASE(pool);
  return 0;
}
