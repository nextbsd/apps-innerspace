#import <AppKit/AppKit.h>
#import "../Space2GLView.h"
#import <objc/runtime.h>
#if defined(__APPLE__)
#include <OpenGL/gl.h>
#else
#include <GL/gl.h>
#endif

static IMP originalPresent;
static BOOL captureFrame;

static void PresentWithoutSwapWhenCapturing(id self, SEL selector)
{
  if (!captureFrame) ((void (*)(id, SEL))originalPresent)(self, selector);
}

static void Check(BOOL result, NSString *message)
{
  if (!result)
    {
      NSLog(@"FAIL: %@", message);
      exit(1);
    }
}

static NSBitmapImageRep *ReadFrame(int width, int height)
{
  NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: width pixelsHigh: height bitsPerSample: 8
    samplesPerPixel: 4 hasAlpha: YES isPlanar: NO colorSpaceName: NSDeviceRGBColorSpace
    bytesPerRow: width * 4 bitsPerPixel: 32]);
  unsigned char *row = malloc(width * 4);
  unsigned char *pixels = [rep bitmapData];
  int y;

  glReadBuffer(GL_BACK);
  glPixelStorei(GL_PACK_ALIGNMENT, 1);
  glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
  for (y = 0; y < height / 2; y++)
    {
      memcpy(row, pixels + y * width * 4, width * 4);
      memcpy(pixels + y * width * 4, pixels + (height - y - 1) * width * 4, width * 4);
      memcpy(pixels + (height - y - 1) * width * 4, row, width * 4);
    }
  free(row);
  return rep;
}

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSWindow *window, *second;
  Space2View *view;
  Class cls;
  NSButton *toggle;
  NSBitmapImageRep *rep;
  unsigned char *pixels;
  NSUInteger uploads;
  int i, red = 0, bright = 0;

  Check(argc == 2 || argc == 3, @"Pass the built module bundle and optional --expect-unavailable");
  [defaults setBool: YES forKey: @"Space2UseGPU"];
  [defaults setBool: YES forKey: @"Space2AllowSoftwareOpenGL"];
  [defaults setBool: YES forKey: @"Space2CosmosMode"];
  [defaults setBool: YES forKey: @"Space2ShowsNebula"];
  srand(12345);
  [NSApplication sharedApplication];
  cls = [[NSBundle bundleWithPath: [NSString stringWithUTF8String: argv[1]]] principalClass];
  Check(cls != Nil, @"Module loads");
  view = [[cls alloc] initWithFrame: NSMakeRect(0, 0, 640, 360)];
  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 640, 360)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setContentView: view];
  [window orderFront: nil];
  [window display];
  if (argc == 3)
    {
      NSImage *canvas = [[NSImage alloc] initWithSize: NSMakeSize(640, 360)];
      Check(![view renderAnimationFrame], @"Unavailable OpenGL selects CPU fallback");
      Check([view valueForKey: @"glRenderer"] == nil, @"Failed context is released");
      [canvas lockFocus];
      [view oneStep];
      [canvas unlockFocus];
      RELEASE(canvas);
      [window close];
      RELEASE(window);
      RELEASE(view);
      [defaults removeObjectForKey: @"Space2UseGPU"];
      [defaults removeObjectForKey: @"Space2AllowSoftwareOpenGL"];
      [defaults removeObjectForKey: @"Space2CosmosMode"];
      [defaults removeObjectForKey: @"Space2ShowsNebula"];
      NSLog(@"PASS: unavailable OpenGL safely falls back to CPU drawing");
      RELEASE(pool);
      return 0;
    }
  Check([view renderAnimationFrame], @"OpenGL presents directly");
  NSLog(@"Renderer: %@", [view valueForKey: @"gpuStatus"]);
  originalPresent = method_setImplementation(class_getInstanceMethod(
    [[view valueForKey: @"glRenderer"] class], @selector(presentFrame)),
    (IMP)PresentWithoutSwapWhenCapturing);
  uploads = [[[view valueForKey: @"glRenderer"] valueForKey: @"uploadCount"] unsignedIntegerValue];
  Check(uploads > 0, @"Nebula textures uploaded");
  for (i = 0; i < 120; i++)
    {
      CREATE_AUTORELEASE_POOL(framePool);
      Check([view renderAnimationFrame], @"Animated OpenGL frame");
      RELEASE(framePool);
    }
  Check([[[view valueForKey: @"glRenderer"] valueForKey: @"uploadCount"] unsignedIntegerValue] == uploads,
        @"Steady frames reuse GPU textures");
  captureFrame = YES;
  [view drawOpenGLScene];
  rep = ReadFrame(640, 360);
  captureFrame = NO;
  [[view valueForKey: @"glRenderer"] performSelector: @selector(presentFrame)];
  pixels = [rep bitmapData];
  for (i = 0; i < 640 * 360; i++)
    {
      if (pixels[i * 4] > 25 && pixels[i * 4] > pixels[i * 4 + 1] * 2) red++;
      if (pixels[i * 4] > 180 && pixels[i * 4 + 1] > 180) bright++;
    }
  Check(red > 1000 && bright > 20, @"GPU framebuffer contains red clouds and stars");
  Check(glGetError() == GL_NO_ERROR, @"No OpenGL errors");
  [[rep representationUsingType: NSPNGFileType properties: [NSDictionary dictionary]]
    writeToFile: @"/tmp/innerspace-opengl.png" atomically: YES];
  toggle = AUTORELEASE([[NSButton alloc] init]);
  [toggle setState: NSOffState];
  [view setCosmosMode: toggle];
  Check([view renderAnimationFrame], @"Ordinary mode renders with OpenGL");
  [toggle setState: NSOnState];
  [view setCosmosMode: toggle];
  Check([view renderAnimationFrame], @"COSMOS restores with OpenGL");
  Check([[[view valueForKey: @"glRenderer"] valueForKey: @"uploadCount"] unsignedIntegerValue] > uploads,
        @"Mode changes replace stale GPU textures");
  [window setContentSize: NSMakeSize(800, 450)];
  [window display];
  Check([view renderAnimationFrame], @"Resize keeps rendering");
  {
    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    Check(viewport[2] == 800 && viewport[3] == 450, @"Viewport follows resized drawable");
  }
  second = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 800, 450)
    styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO];
  [second setReleasedWhenClosed: NO];
  [view removeFromSuperview];
  [second setContentView: view];
  [second orderFront: nil];
  [second display];
  Check([view renderAnimationFrame], @"Window transition recreates context");
  toggle = AUTORELEASE([[NSButton alloc] init]);
  [toggle setState: NSOffState];
  [view setUsesGPU: toggle];
  {
    Space2View *restored = [[cls alloc] initWithFrame: NSMakeRect(0, 0, 640, 360)];
    Check(![[restored valueForKey: @"gpuEnabled"] boolValue], @"GPU setting persists");
    RELEASE(restored);
  }
  Check(![view renderAnimationFrame] && [view valueForKey: @"glRenderer"] == nil,
        @"GPU disabling selects CPU fallback and frees renderer");
  [defaults setBool: NO forKey: @"Space2AllowSoftwareOpenGL"];
  [toggle setState: NSOnState];
  [view setUsesGPU: toggle];
  if (![view renderAnimationFrame])
    Check([[view valueForKey: @"gpuStatus"] rangeOfString: @"CPU fallback"].location != NSNotFound,
          @"Software/unavailable driver produces explicit fallback");
  [second close];
  [window close];
  RELEASE(second);
  RELEASE(window);
  RELEASE(view);
  [defaults removeObjectForKey: @"Space2UseGPU"];
  [defaults removeObjectForKey: @"Space2AllowSoftwareOpenGL"];
  [defaults removeObjectForKey: @"Space2CosmosMode"];
  [defaults removeObjectForKey: @"Space2ShowsNebula"];
  NSLog(@"PASS: direct rendering, framebuffer, texture reuse, resize, window transition, fallback");
  RELEASE(pool);
  return 0;
}
