#import "Space2GLView.h"
#if defined(__APPLE__)
#include <OpenGL/gl.h>
#else
#include <GL/gl.h>
#endif

@implementation Space2GLView

- (id)initWithFrame:(NSRect)frame scene:(Space2View *)owner
{
  NSOpenGLPixelFormatAttribute attributes[] = {
    NSOpenGLPFADoubleBuffer, NSOpenGLPFAColorSize, 24,
    NSOpenGLPFAAlphaSize, 8, 0
  };
  NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes: attributes];

  if (format == nil)
    {
      RELEASE(self);
      return nil;
    }
  self = [super initWithFrame: frame pixelFormat: format];
  RELEASE(format);
  if (self != nil)
    {
      scene = owner;
      [self setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
    }
  return self;
}

- (void)invalidateRenderer
{
  NSOpenGLContext *context = [self pixelFormat] == nil ? nil : [self openGLContext];
  BOOL canDelete = [context view] != nil;
  int i;

  ready = NO;
  if (canDelete) [context makeCurrentContext];
  for (i = 0; i < MAXNEBULAE; i++)
    {
      if (canDelete && textures[i]) glDeleteTextures(1, &textures[i]);
      textures[i] = 0;
      DESTROY(textureSources[i]);
    }
}

- (void)dealloc
{
  [self invalidateRenderer];
  RELEASE(rendererName);
  [self clearGLContext];
  DEALLOC;
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame: frame];
  if (ready && [self window] != nil) [[self openGLContext] update];
}

- (BOOL)prepareRenderer
{
  NSOpenGLContext *context;
  const GLubyte *name;
  NSString *lower;
  BOOL software;
#if defined(__APPLE__)
  GLint interval = 1;
#else
  long interval = 1;
#endif

  if ([self window] == nil) return NO;
  context = [self openGLContext];
  if (context == nil) return NO;
  if ([context view] != self) [context setView: self];
  [context update];
  [context makeCurrentContext];
  name = glGetString(GL_RENDERER);
  if (name == NULL) return NO;
  ASSIGNCOPY(rendererName, [NSString stringWithUTF8String: (const char *)name]);
  lower = [rendererName lowercaseString];
  software = [lower rangeOfString: @"llvmpipe"].location != NSNotFound
    || [lower rangeOfString: @"softpipe"].location != NSNotFound
    || [lower rangeOfString: @"software"].location != NSNotFound
    || [lower rangeOfString: @"swiftshader"].location != NSNotFound;
  /* Permit software GL only for explicit diagnostic/regression runs. */
  if (software && ![[NSUserDefaults standardUserDefaults] boolForKey: @"Space2AllowSoftwareOpenGL"])
    return NO;
  @try
    {
      [context setValues: &interval forParameter: NSOpenGLCPSwapInterval];
    }
  @catch (NSException *exception)
    {
      /* Some GNUstep backends expose this selector without implementing it.
         The host timer still bounds frame submission. */
    }
  ready = YES;
  return YES;
}

- (NSString *)rendererName
{
  return rendererName;
}

- (BOOL)beginFrame
{
  NSRect bounds = [self bounds];
  NSRect pixels = bounds;

  if (!ready || [self window] == nil || bounds.size.width <= 0 || bounds.size.height <= 0)
    return NO;
  [[self openGLContext] makeCurrentContext];
#if defined(__APPLE__)
  pixels = [self convertRectToBacking: bounds];
#endif
  glViewport(0, 0, (GLsizei)pixels.size.width, (GLsizei)pixels.size.height);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glDisable(GL_SCISSOR_TEST);
  glClearColor(0, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(NSMinX(bounds), NSMaxX(bounds), NSMinY(bounds), NSMaxY(bounds), -1, 1);
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  return YES;
}

- (void)presentFrame
{
  [[self openGLContext] flushBuffer];
}

- (unsigned int)textureForImage:(NSImage *)image slot:(int)slot
{
  NSBitmapImageRep *bitmap = nil;
  NSArray *representations;
  NSUInteger i;

  if (textureSources[slot] == image && textures[slot]) return textures[slot];
  representations = [image representations];
  for (i = 0; i < [representations count]; i++)
    if ([[representations objectAtIndex: i] isKindOfClass: [NSBitmapImageRep class]])
      {
        bitmap = [representations objectAtIndex: i];
        break;
      }
  /* Our generated textures are tightly packed premultiplied RGBA bytes. */
  if (bitmap == nil || [bitmap samplesPerPixel] != 4 || [bitmap bitsPerSample] != 8
      || [bitmap bytesPerRow] != [bitmap pixelsWide] * 4) return 0;
  if (!textures[slot]) glGenTextures(1, &textures[slot]);
  glBindTexture(GL_TEXTURE_2D, textures[slot]);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)[bitmap pixelsWide],
               (GLsizei)[bitmap pixelsHigh], 0, GL_RGBA, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
  if (glGetError() != GL_NO_ERROR) return 0;
  ASSIGN(textureSources[slot], image);
  uploadCount++;
  return textures[slot];
}

- (void)releaseUnusedTexturesFrom:(int)count
{
  int i;

  for (i = count; i < MAXNEBULAE; i++)
    {
      if (textures[i]) glDeleteTextures(1, &textures[i]);
      textures[i] = 0;
      DESTROY(textureSources[i]);
    }
}

- (void)drawRect:(NSRect)rect
{
  if (ready) [scene drawOpenGLScene];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
  return YES;
}

- (void)mouseDown:(NSEvent *)event
{
  [scene mouseDown: event];
}

@end

@implementation Space2View (OpenGL)

- (void)drawOpenGLScene
{
  int i, j, order[MAXNEBULAE];
  GLfloat positions[NSTARS * 6 * 2];
  GLubyte colors[NSTARS * 6 * 4];
  Space2GLView *renderer = glRenderer;

  if (![renderer beginFrame]) return;
  [renderer releaseUnusedTexturesFrom: nnebulae];
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
  glEnable(GL_TEXTURE_2D);
  glEnable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
  for (i = 0; i < nnebulae; i++)
    {
      int index = order[i];
      NEBULA *p = &nebulae[index];
      NSRect rect = [self nebulaRectAt: index];
      GLfloat half = rect.size.width / 2;
      GLfloat opacity = MAX(0, MIN(1.0, p->age / 180.0) * MIN(1.0, (p->z - 0.65) / 0.4));
      GLuint texture = [renderer textureForImage: p->image slot: index];

      if (!texture) continue;
      glBindTexture(GL_TEXTURE_2D, texture);
      glColor4f(opacity, opacity, opacity, opacity);
      glPushMatrix();
      glTranslatef(NSMidX(rect), NSMidY(rect), 0);
      glRotatef(p->angle * 180.0 / 3.141592653589, 0, 0, 1);
      glBegin(GL_QUADS);
      glTexCoord2f(0, 1); glVertex2f(-half, -half);
      glTexCoord2f(1, 1); glVertex2f(half, -half);
      glTexCoord2f(1, 0); glVertex2f(half, half);
      glTexCoord2f(0, 0); glVertex2f(-half, half);
      glEnd();
      glPopMatrix();
    }
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_BLEND);
  for (i = 0; i < nstars; i++)
    {
      NSRect rect = stars[i].draw;
      CGFloat red, green, blue, alpha;
      GLfloat vertices[12] = {NSMinX(rect), NSMinY(rect), NSMaxX(rect), NSMinY(rect),
        NSMaxX(rect), NSMaxY(rect), NSMinX(rect), NSMinY(rect),
        NSMaxX(rect), NSMaxY(rect), NSMinX(rect), NSMaxY(rect)};
      NSColor *color = [[self colorForHue: stars[i].hue] colorUsingColorSpaceName: NSDeviceRGBColorSpace];

      [color getRed: &red green: &green blue: &blue alpha: &alpha];
      for (j = 0; j < 12; j++) positions[i * 12 + j] = vertices[j];
      for (j = 0; j < 6; j++)
        {
          colors[i * 24 + j * 4] = red * 255;
          colors[i * 24 + j * 4 + 1] = green * 255;
          colors[i * 24 + j * 4 + 2] = blue * 255;
          colors[i * 24 + j * 4 + 3] = 255;
        }
    }
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_COLOR_ARRAY);
  glVertexPointer(2, GL_FLOAT, 0, positions);
  glColorPointer(4, GL_UNSIGNED_BYTE, 0, colors);
  glDrawArrays(GL_TRIANGLES, 0, nstars * 6);
  glDisableClientState(GL_COLOR_ARRAY);
  glDisableClientState(GL_VERTEX_ARRAY);
  [renderer presentFrame];
}

@end
