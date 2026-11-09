#import <AppKit/AppKit.h>
#import "Space2View.h"

@interface Space2GLView : NSOpenGLView
{
  Space2View *scene;
  unsigned int textures[MAXNEBULAE];
  NSImage *textureSources[MAXNEBULAE];
  NSString *rendererName;
  BOOL ready;
  NSUInteger uploadCount;
}

- (id)initWithFrame:(NSRect)frame scene:(Space2View *)owner;
- (BOOL)prepareRenderer;
- (void)invalidateRenderer;
- (NSString *)rendererName;
- (BOOL)beginFrame;
- (void)presentFrame;
- (unsigned int)textureForImage:(NSImage *)image slot:(int)slot;
- (void)releaseUnusedTexturesFrom:(int)count;

@end

@interface Space2View (OpenGL)

- (void)drawOpenGLScene;

@end
