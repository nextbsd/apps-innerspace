#include <AppKit/AppKit.h>

@interface SystemStatsView : NSView
{
  unsigned long long previousCpuTotal;
  unsigned long long previousCpuIdle;
  unsigned long long previousNetRx;
  unsigned long long previousNetTx;
  NSDate *lastSampleDate;
  NSDictionary *titleAttributes;
  NSDictionary *labelAttributes;
  NSDictionary *valueAttributes;
  NSDictionary *smallAttributes;
  float cpuPercent;
  float memoryPercent;
  float swapPercent;
  float diskPercent;
  float netRxRate;
  float netTxRate;
  float loadAverage1;
  float temperatureCelsius;
  unsigned long long memoryUsed;
  unsigned long long memoryTotal;
  unsigned long long swapUsed;
  unsigned long long swapTotal;
  unsigned long long diskUsed;
  unsigned long long diskTotal;
  unsigned long long uptimeSeconds;
  int processCount;
  int threadCount;
}
- (void)oneStep;
- (void)updateTextAttributes;
- (void)sampleStats;
- (void)sampleProcessCounts;
- (void)sampleTemperature;
- (void)drawStats;
- (NSString *)uptimeString;
- (void)drawMeterAtY:(float)y
	       label:(NSString *)label
	       value:(NSString *)value
	     percent:(float)percent
	      color:(NSColor *)color;
- (NSString *)sizeStringForBytes:(unsigned long long)bytes;
- (NSString *)rateStringForBytesPerSecond:(float)bytesPerSecond;
@end

@interface StaticSystemStatsView : SystemStatsView
{
}
@end
