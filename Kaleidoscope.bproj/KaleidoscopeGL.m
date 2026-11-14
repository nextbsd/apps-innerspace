#include "KaleidoscopeView.h"
#include "KaleidoscopeGL.h"
#include <math.h>
#include <stddef.h>
#include <string.h>

#if defined(__APPLE__)
#include <OpenGL/gl.h>
#else
#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <GL/glext.h>
#endif

#ifndef GL_VERTEX_PROGRAM_POINT_SIZE
#define GL_VERTEX_PROGRAM_POINT_SIZE 0x8642
#endif
#ifndef GL_POINT_SPRITE
#define GL_POINT_SPRITE 0x8861
#endif

/* KaleidoscopeView.h's segments, each drawn plain and mirrored. */
#define COPIES (KaleidoscopeSegments * 2)
#define DISCS KaleidoscopeParticleCount
#define RING_STEPS 64
/* A disc's colour is down to 0.88^36 * 0.72 * 255 < 2 after this many
   steps; the CPU version's 8-bit fade never takes the last few levels
   away either (pixman rounds 4 * 0.88 back up to 4). */
#define MAX_AGE 36.0
/* Steps are kept modulo this, so a float holds them exactly enough. */
#define CLOCK_WRAP 4096.0

/* Per vertex: the disc (x, y, radius, hue), then its step, its weight
   (1 for a step, less for the head), and which copy it is (segment * 2
   + mirrored). */
typedef struct
{
  GLfloat disc[4];
  GLfloat info[3];
} KaleidoscopeVertex;

/* Copies of the NSAffineTransform / NSBezierPath drawing in
   KaleidoscopeView.m: rotated by the segment, mirrored, a fill of
   alpha 0.72 in the segment's hue and a 1-point outline of alpha 0.45. */
static const char *vertexShader =
  "#ifdef GL_ES\n"
  "precision highp float;\n"
  "#endif\n"
  "attribute vec4 aDisc;\n"
  "attribute vec3 aInfo;\n"
  "uniform vec2 uHalfSize;\n"
  "uniform float uPixels;\n"
  "uniform float uNow;\n"
  "varying vec4 vFill;\n"
  "varying vec4 vStroke;\n"
  "varying vec2 vShape;\n"
  "const float TWO_PI = 6.28318530718;\n"
  "vec3 hueColor(float h)\n"
  "{\n"
  "  return 0.55 + 0.45 * sin(h * TWO_PI + vec3(0.0, 2.0943951, 4.1887902));\n"
  "}\n"
  "void main()\n"
  "{\n"
  "  float seg = floor(aInfo.z * 0.5 + 0.25);\n"
  "  float mirrored = aInfo.z - seg * 2.0;\n"
  "  vec2 p = vec2(aDisc.x, mirrored > 0.5 ? -aDisc.y : aDisc.y);\n"
  "  float a = seg * (TWO_PI / 8.0);\n"
  "  float c = cos(a);\n"
  "  float s = sin(a);\n"
  "  vec2 q = vec2(c * p.x - s * p.y, s * p.x + c * p.y);\n"
  "  float r = aDisc.z * uPixels;\n"
  "  float extent = r + 0.5 * uPixels + 1.0;\n"
  "  float age = mod(uNow - aInfo.x + 4096.0, 4096.0);\n"
  "  float fade = exp2(age * -0.184425);\n"	/* 0.88^age */
  "  float fill = 1.0 - pow(0.28, aInfo.y);\n"	/* alpha 0.72 a step */
  "  float stroke = 1.0 - pow(0.55, aInfo.y);\n"	/* alpha 0.45 */
  "  gl_Position = vec4(q / uHalfSize, 0.0, 1.0);\n"
  "  gl_PointSize = 2.0 * extent;\n"
  "  vShape = vec2(r, extent);\n"
  "  vFill = vec4(hueColor(aDisc.w + seg * 0.035) * fill * fade, fill);\n"
  "  vStroke = vec4(hueColor(aDisc.w + 0.18) * stroke * fade, stroke);\n"
  "}\n";

/* Premultiplied: the outline over the fill, the colours (not the
   coverage) faded by age. */
static const char *fragmentShader =
  "#ifdef GL_ES\n"
  "precision mediump float;\n"
  "#endif\n"
  "uniform float uRing;\n"
  "varying vec4 vFill;\n"
  "varying vec4 vStroke;\n"
  "varying vec2 vShape;\n"
  "void main()\n"
  "{\n"
  "  float d = length(gl_PointCoord * 2.0 - 1.0) * vShape.y;\n"
  "  float f = clamp(vShape.x - d + 0.5, 0.0, 1.0);\n"
  "  vec4 s = vStroke * clamp(uRing - abs(d - vShape.x), 0.0, 1.0);\n"
  "  gl_FragColor = s + vFill * (f * (1.0 - s.a));\n"
  "}\n";

@interface NSOpenGLContext (KaleidoscopeNextBSD)
- (NSSize)drawableSize;
- (BOOL)isFramePending;
- (void)setFrameCallbackTarget:(id)target selector:(SEL)selector;
@end

/* GLSL 1.20 (desktop OpenGL 2.1) or GLSL ES 1.00: both have
   gl_PointCoord. */
static GLuint
compile(GLenum type, const char *source, BOOL es)
{
  GLuint shader = glCreateShader(type);
  const char *sources[2] = { es ? "#version 100\n" : "#version 120\n",
                             source };
  GLint ok = 0;
  char log[512];

  glShaderSource(shader, 2, sources, NULL);
  glCompileShader(shader);
  glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
  if (!ok)
    {
      glGetShaderInfoLog(shader, sizeof(log), NULL, log);
      NSLog(@"Kaleidoscope: shader: %s", log);
      glDeleteShader(shader);
      return 0;
    }
  return shader;
}

@implementation KaleidoscopeGL

- (id)initWithView:(NSView *)aView
{
  NSOpenGLPixelFormatAttribute attributes[] = {
    NSOpenGLPFADoubleBuffer, NSOpenGLPFAColorSize, 24, 0
  };
  NSOpenGLPixelFormat *format;
  const GLubyte *name, *version;
  NSString *lower;
  GLuint vs, fs;
  GLint ok = 0;
#if defined(__APPLE__)
  GLint interval = 1;
#else
  long interval = 1;
#endif

  self = [super init];
  if (self == nil)
    return nil;
  view = aView;
  format = [[NSOpenGLPixelFormat alloc] initWithAttributes: attributes];
  if (format != nil)
    context = [[NSOpenGLContext alloc] initWithFormat: format
                                         shareContext: nil];
  RELEASE(format);
  if (context == nil)
    {
      RELEASE(self);
      return nil;
    }
  [context setView: view];
  [context makeCurrentContext];
  name = glGetString(GL_RENDERER);
  version = glGetString(GL_VERSION);
  if (name == NULL || version == NULL)
    {
      [self invalidate];
      RELEASE(self);
      return nil;
    }
  ASSIGN(rendererName, [NSString stringWithUTF8String: (const char *)name]);
  lower = [rendererName lowercaseString];
  if (([lower rangeOfString: @"llvmpipe"].location != NSNotFound
       || [lower rangeOfString: @"softpipe"].location != NSNotFound
       || [lower rangeOfString: @"software"].location != NSNotFound
       || [lower rangeOfString: @"swiftshader"].location != NSNotFound)
      && ![[NSUserDefaults standardUserDefaults]
            boolForKey: @"KaleidoscopeAllowSoftwareOpenGL"])
    {
      NSLog(@"Kaleidoscope: %@ isn't hardware OpenGL; drawing on the CPU",
            rendererName);
      [self invalidate];
      RELEASE(self);
      return nil;
    }
  isES = strncmp((const char *)version, "OpenGL ES", 9) == 0;

  vs = compile(GL_VERTEX_SHADER, vertexShader, isES);
  fs = compile(GL_FRAGMENT_SHADER, fragmentShader, isES);
  if (vs != 0 && fs != 0)
    {
      program = glCreateProgram();
      glAttachShader(program, vs);
      glAttachShader(program, fs);
      glBindAttribLocation(program, 0, "aDisc");
      glBindAttribLocation(program, 1, "aInfo");
      glLinkProgram(program);
      glGetProgramiv(program, GL_LINK_STATUS, &ok);
    }
  if (vs != 0)
    glDeleteShader(vs);
  if (fs != 0)
    glDeleteShader(fs);
  if (!ok)
    {
      NSLog(@"Kaleidoscope: can't build the OpenGL program");
      [self invalidate];
      RELEASE(self);
      return nil;
    }
  uHalfSize = glGetUniformLocation(program, "uHalfSize");
  uPixels = glGetUniformLocation(program, "uPixels");
  uNow = glGetUniformLocation(program, "uNow");
  uRing = glGetUniformLocation(program, "uRing");

  glGenBuffers(1, &ring);
  glBindBuffer(GL_ARRAY_BUFFER, ring);
  glBufferData(GL_ARRAY_BUFFER, sizeof(KaleidoscopeVertex) * RING_STEPS
               * DISCS * COPIES, NULL, GL_DYNAMIC_DRAW);
  glGenBuffers(1, &headBuffer);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  if (glGetError() != GL_NO_ERROR)
    {
      NSLog(@"Kaleidoscope: OpenGL setup failed");
      [self invalidate];
      RELEASE(self);
      return nil;
    }
  /* Desktop OpenGL sizes points from the shader only when asked to, and
     its compatibility profile has point sprites to enable; OpenGL ES
     always does both (and knows neither enum). */
  if (!isES)
    {
      glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
      glEnable(GL_POINT_SPRITE);
      (void)glGetError();
    }
  NS_DURING
    [context setValues: &interval forParameter: NSOpenGLCPSwapInterval];
  NS_HANDLER
  NS_ENDHANDLER
  NSLog(@"Kaleidoscope: drawing with OpenGL on %@", rendererName);
  return self;
}

- (void)dealloc
{
  [self invalidate];
  RELEASE(rendererName);
  [super dealloc];
}

- (void)invalidate
{
  if (context == nil)
    return;
  if ([context view] != nil)
    {
      [context makeCurrentContext];
      if (program != 0)
        glDeleteProgram(program);
      if (ring != 0)
        glDeleteBuffers(1, &ring);
      if (headBuffer != 0)
        glDeleteBuffers(1, &headBuffer);
    }
  program = ring = headBuffer = 0;
  [self setFrameTarget: nil selector: NULL];
  [NSOpenGLContext clearCurrentContext];
  [context clearDrawable];
  DESTROY(context);
}

- (NSOpenGLContext *)context
{
  return context;
}

- (NSString *)rendererName
{
  return rendererName;
}

- (void)reset
{
  stamps = 0;
}

static void
fillVertices(KaleidoscopeVertex *v, const KaleidoscopeDisc *discs, int count,
             GLfloat birth, GLfloat weight)
{
  int i, c;

  for (i = 0; i < count; i++)
    {
      for (c = 0; c < COPIES; c++, v++)
        {
          v->disc[0] = discs[i].x;
          v->disc[1] = discs[i].y;
          v->disc[2] = discs[i].radius;
          v->disc[3] = discs[i].hue;
          v->info[0] = birth;
          v->info[1] = weight;
          v->info[2] = (GLfloat)c;
        }
    }
}

- (void)addStep:(double)step discs:(const KaleidoscopeDisc *)discs
          count:(int)count
{
  KaleidoscopeVertex v[DISCS * COPIES];
  size_t size = sizeof(KaleidoscopeVertex) * DISCS * COPIES;

  if (context == nil || count > DISCS)
    return;
  [context makeCurrentContext];
  memset(v, 0, sizeof(v));	/* unused slots: zero-sized discs */
  fillVertices(v, discs, count, (GLfloat)fmod(step, CLOCK_WRAP), 1.0f);
  newest = (newest + 1) % RING_STEPS;
  stampStep[newest] = step;
  if (stamps < RING_STEPS)
    stamps++;
  glBindBuffer(GL_ARRAY_BUFFER, ring);
  glBufferSubData(GL_ARRAY_BUFFER, size * newest, size, v);
}

static void
setAttributes(void)
{
  glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, sizeof(KaleidoscopeVertex),
                        (const void *)0);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(KaleidoscopeVertex),
                        (const void *)offsetof(KaleidoscopeVertex, info));
}

- (BOOL)drawAt:(double)now head:(const KaleidoscopeDisc *)head
         count:(int)count weight:(float)weight
{
  KaleidoscopeVertex v[DISCS * COPIES];
  NSRect bounds = [view bounds];
  NSSize pixels = bounds.size;
  int live = 0, first, n;

  if (context == nil || [view window] == nil || NSWidth(bounds) < 1
      || NSHeight(bounds) < 1 || count > DISCS)
    return NO;
  [context makeCurrentContext];
  if ([context respondsToSelector: @selector(drawableSize)])
    {
      NSSize s = [context drawableSize];

      if (s.width > 0 && s.height > 0)
        pixels = s;
    }
  glViewport(0, 0, (GLsizei)pixels.width, (GLsizei)pixels.height);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_SCISSOR_TEST);
  glClearColor(0, 0, 0, 1);
  glClear(GL_COLOR_BUFFER_BIT);

  glUseProgram(program);
  glUniform2f(uHalfSize, NSWidth(bounds) / 2, NSHeight(bounds) / 2);
  glUniform1f(uPixels, pixels.width / NSWidth(bounds));
  /* the 1-point outline's half width, and half a pixel to antialias */
  glUniform1f(uRing, 0.5 * pixels.width / NSWidth(bounds) + 0.5);
  glUniform1f(uNow, (GLfloat)fmod(now, CLOCK_WRAP));
  glEnable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);

  /* The steps that still show, oldest first. */
  while (live < stamps
         && now - stampStep[(newest - live + RING_STEPS) % RING_STEPS]
            < MAX_AGE)
    live++;
  glBindBuffer(GL_ARRAY_BUFFER, ring);
  setAttributes();
  first = (newest - live + 1 + RING_STEPS) % RING_STEPS;
  n = MIN(live, RING_STEPS - first);
  if (n > 0)
    glDrawArrays(GL_POINTS, first * DISCS * COPIES, n * DISCS * COPIES);
  if (live - n > 0)
    glDrawArrays(GL_POINTS, 0, (live - n) * DISCS * COPIES);

  /* The head, on its way to the next step. */
  if (weight > 0.001f && count > 0)
    {
      fillVertices(v, head, count, (GLfloat)fmod(now, CLOCK_WRAP), weight);
      glBindBuffer(GL_ARRAY_BUFFER, headBuffer);
      glBufferData(GL_ARRAY_BUFFER, sizeof(KaleidoscopeVertex) * count
                   * COPIES, v, GL_STREAM_DRAW);
      setAttributes();
      glDrawArrays(GL_POINTS, 0, count * COPIES);
    }
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);
  glDisable(GL_BLEND);
  [context flushBuffer];
  lastFlush = [NSDate timeIntervalSinceReferenceDate];
  return glGetError() != GL_OUT_OF_MEMORY;
}

- (BOOL)framePending
{
  return [context respondsToSelector: @selector(isFramePending)]
    && [context isFramePending];
}

- (NSTimeInterval)lastFlush
{
  return lastFlush;
}

- (BOOL)setFrameTarget:(id)target selector:(SEL)selector
{
  if (![context respondsToSelector:
                  @selector(setFrameCallbackTarget:selector:)])
    return NO;
  [context setFrameCallbackTarget: target selector: selector];
  return YES;
}

@end
