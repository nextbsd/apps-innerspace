#include <AppKit/AppKit.h>

@interface HAL9000View : NSView
{
  float phase;
  int frameCount;
  int screenMode;
  NSDictionary *titleAttributes;
  NSDictionary *labelAttributes;
  NSDictionary *smallAttributes;
  NSDictionary *greenAttributes;
  NSDictionary *amberAttributes;
}
- (void)oneStep;
- (void)drawDisplayInRect:(NSRect)rect;
- (void)drawPanelAtRow:(int)row column:(int)column inRect:(NSRect)rect;
- (void)drawHalEyeInRect:(NSRect)rect;
- (void)drawStatusMatrixInRect:(NSRect)rect;
- (void)drawSignalTraceInRect:(NSRect)rect;
- (void)drawScanLinesInRect:(NSRect)rect;
@end

@interface StaticHAL9000View : HAL9000View
{
}
@end
