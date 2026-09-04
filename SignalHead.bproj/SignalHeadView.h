#include <AppKit/AppKit.h>

#define SignalHeadBandCount 12
#define SignalHeadCaptionCount 6

@interface SignalHeadView : NSView
{
  float phase;
  float blinkPhase;
  float mouthPhase;
  float jitterPhase;
  float gridDrift;
  int captionIndex;
  int captionHold;
  NSDictionary *captionAttributes;
  NSDictionary *smallCaptionAttributes;
  NSString *captions[SignalHeadCaptionCount];
}
- (void)oneStep;
- (void)buildCaptions;
- (void)updateCaptionAttributes;
- (void)drawBackdropInBounds:(NSRect)bounds;
- (void)drawScanlinesInBounds:(NSRect)bounds;
- (void)drawHeadInBounds:(NSRect)bounds;
- (void)drawWireHeadAtCenter:(NSPoint)center scale:(float)scale;
- (void)drawJitterBandsAtCenter:(NSPoint)center scale:(float)scale;
- (void)drawCaptionInBounds:(NSRect)bounds;
@end

@interface StaticSignalHeadView : SignalHeadView
{
}
@end
