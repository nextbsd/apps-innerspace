#include <AppKit/AppKit.h>
#include <stdint.h>

#define CM_MAX_CPUS 256
@interface ConnectionMachineView : NSView
{
  uint64_t previousBusy[CM_MAX_CPUS], previousTotal[CM_MAX_CPUS];
  double cpu[CM_MAX_CPUS], rxRate, txRate;
  NSUInteger cpuCount;
  uint64_t previousRx, previousTx;
  BOOL cpuReady, networkReady, cpuAvailable, networkAvailable;
  double lastSample, lastNetworkSample, lastFrame;
  unsigned int frameNumber;
  float lights[4096];
}
- (void)oneStep;
- (void)sampleActivity;
@end
