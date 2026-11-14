#include "TomorrowNeverKnowsView.h"
#include <math.h>
#include <string.h>

#if defined(__APPLE__)
#include <OpenGL/gl.h>
#else
#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <GL/glext.h>
#endif

@interface NSOpenGLContext (TomorrowNeverKnowsNextBSD)
- (BOOL)isFramePending;
- (NSSize)drawableSize;
- (void)setFrameCallbackTarget:(id)target selector:(SEL)selector;
@end

static const char *vertexShader =
  "attribute vec2 aPos;\n"
  "varying vec2 vUV;\n"
  "void main() {\n"
  "  vUV = aPos * 0.5 + 0.5;\n"
  "  gl_Position = vec4(aPos, 0.0, 1.0);\n"
  "}\n";

/* Six mirrored sectors turning slowly; the colour runs through warm
   orange, magenta, violet and green, and the whole pattern breathes. */
static const char *fragmentShader =
  "#ifdef GL_ES\n"
  "precision highp float;\n"
  "#endif\n"
  "varying vec2 vUV;\n"
  "uniform float uTime;\n"
  "uniform vec2 uAspect;\n"
  "uniform float uBreath;\n"
  "vec3 palette(float t) {\n"
  "  return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.00, 0.33, 0.67)\n"
  "      + vec3(0.10, 0.20, 0.30) * sin(uTime * 0.05)));\n"
  "}\n"
  "void main() {\n"
  "  vec2 q = (vUV - 0.5) * uAspect;\n"
  "  float a = atan(q.y, q.x), r = length(q);\n"
  "  a = abs(mod(a + uTime * 0.2, 1.0472) - 0.5236);\n"
  "  vec2 k = vec2(cos(a), sin(a)) * r * (5.0 + uBreath);\n"
  "  float swirl = sin(k.x * 1.7 + uTime) * cos(k.y * 1.3 - uTime * 0.7);\n"
  "  vec3 c = palette(r * 0.6 + swirl * 0.25 + uTime * 0.03);\n"
  "  c *= 0.75 + 0.25 * cos(uTime + k.x * 3.0 + k.y * 2.0);\n"
  "  gl_FragColor = vec4(c * smoothstep(1.25, 0.0, r), 1.0);\n"
  "}\n";

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
      NSLog(@"TomorrowNeverKnows: shader: %s", log);
      glDeleteShader(shader);
      return 0;
    }
  return shader;
}

@implementation TomorrowNeverKnowsView

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if (self != nil)
    start = [NSDate timeIntervalSinceReferenceDate];
  return self;
}

- (void)dealloc
{
  [self stopOpenGL];
  [super dealloc];
}

- (BOOL)useBufferedWindow
{
  return YES;
}

- (BOOL)isOpaque
{
  return YES;
}

- (NSTimeInterval)animationDelayTime
{
  return 0.03;
}

- (NSString *)windowTitle
{
  return @"Tomorrow Never Knows";
}

- (BOOL)wantsBestResolutionOpenGLSurface
{
  return YES;
}

- (void)stopOpenGL
{
  if (context != nil)
    {
      [context makeCurrentContext];
      if (program != 0)
        glDeleteProgram(program);
      program = 0;
      [NSOpenGLContext clearCurrentContext];
      [context clearDrawable];
      DESTROY(context);
    }
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
  if (newWindow != [self window])
    {
      [self stopOpenGL];
      tried = NO;
    }
  [super viewWillMoveToWindow: newWindow];
}

/* A context on the view, and the program: NO without hardware OpenGL. */
- (BOOL)startOpenGL
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

  format = [[NSOpenGLPixelFormat alloc] initWithAttributes: attributes];
  if (format != nil)
    context = [[NSOpenGLContext alloc] initWithFormat: format
                                         shareContext: nil];
  RELEASE(format);
  if (context == nil)
    return NO;
  [context setView: self];
  [context makeCurrentContext];
  name = glGetString(GL_RENDERER);
  version = glGetString(GL_VERSION);
  if (name == NULL || version == NULL)
    {
      [self stopOpenGL];
      return NO;
    }
  lower = [[NSString stringWithUTF8String: (const char *)name]
            lowercaseString];
  if ([lower rangeOfString: @"llvmpipe"].location != NSNotFound
      || [lower rangeOfString: @"softpipe"].location != NSNotFound
      || [lower rangeOfString: @"software"].location != NSNotFound)
    {
      /* a whole screen of shader per frame on the CPU: no */
      [self stopOpenGL];
      return NO;
    }
  isES = strncmp((const char *)version, "OpenGL ES", 9) == 0;
  vs = compile(GL_VERTEX_SHADER, vertexShader, isES);
  fs = compile(GL_FRAGMENT_SHADER, fragmentShader, isES);
  if (vs != 0 && fs != 0)
    {
      program = glCreateProgram();
      glAttachShader(program, vs);
      glAttachShader(program, fs);
      glBindAttribLocation(program, 0, "aPos");
      glLinkProgram(program);
      glGetProgramiv(program, GL_LINK_STATUS, &ok);
    }
  if (vs != 0)
    glDeleteShader(vs);
  if (fs != 0)
    glDeleteShader(fs);
  if (!ok)
    {
      [self stopOpenGL];
      return NO;
    }
  uTime = glGetUniformLocation(program, "uTime");
  uAspect = glGetUniformLocation(program, "uAspect");
  uBreath = glGetUniformLocation(program, "uBreath");
  NS_DURING
    [context setValues: &interval forParameter: NSOpenGLCPSwapInterval];
  NS_HANDLER
  NS_ENDHANDLER
  NSLog(@"TomorrowNeverKnows: drawing with OpenGL on %s", name);
  return YES;
}

- (BOOL)renderAnimationFrame
{
  static const GLfloat quad[] = { -1, -1, 1, -1, -1, 1, 1, 1 };
  NSRect bounds = [self bounds];
  NSSize pixels = bounds.size;
  double t;

  if ([self window] == nil || NSWidth(bounds) < 1 || NSHeight(bounds) < 1)
    return NO;
  if (context == nil)
    {
      if (tried)
        return NO;
      tried = YES;
      if (![self startOpenGL])
        return NO;
    }
  /* the last frame isn't on screen yet: let it be */
  if ([context respondsToSelector: @selector(isFramePending)]
      && [context isFramePending])
    return YES;
  [context makeCurrentContext];
  if ([context respondsToSelector: @selector(drawableSize)])
    {
      NSSize s = [context drawableSize];

      if (s.width > 0 && s.height > 0)
        pixels = s;
    }
  t = [NSDate timeIntervalSinceReferenceDate] - start;
  glViewport(0, 0, (GLsizei)pixels.width, (GLsizei)pixels.height);
  glDisable(GL_BLEND);
  glUseProgram(program);
  glUniform1f(uTime, (GLfloat)fmod(t, 3600.0));
  glUniform2f(uAspect, NSWidth(bounds) / NSHeight(bounds), 1.0f);
  glUniform1f(uBreath, (GLfloat)(1.5 * sin(t * 0.25)));
  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, quad);
  glEnableVertexAttribArray(0);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glDisableVertexAttribArray(0);
  [context flushBuffer];
  if (glGetError() == GL_OUT_OF_MEMORY)
    {
      [self stopOpenGL];
      return NO;
    }
  return YES;
}

/* Paced by the display where the backend says when a frame is shown. */
- (BOOL)setAnimationFrameTarget:(id)target action:(SEL)action
{
  frameTarget = target;
  frameAction = action;
  if (![context respondsToSelector:
                  @selector(setFrameCallbackTarget:selector:)])
    return NO;
  [context setFrameCallbackTarget: target != nil ? self : nil
                         selector: @selector(frameShown:)];
  return YES;
}

- (void)frameShown:(id)sender
{
  if (frameTarget != nil && context != nil)
    [frameTarget performSelector: frameAction withObject: self];
}

/* Without OpenGL: a still, deep violet, once. */
- (void)drawRect:(NSRect)rect
{
  [[NSColor colorWithCalibratedRed: 0.18 green: 0.05 blue: 0.28 alpha: 1]
    set];
  NSRectFill(rect);
}

- (void)oneStep
{
}

@end
