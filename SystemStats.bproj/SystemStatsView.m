#include "SystemStatsView.h"
#include <sys/statvfs.h>
#include <dirent.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BYTES_PER_KIB 1024ULL
#define PROC_LINE_LENGTH 512
#define METER_HEIGHT 18.0
#define ROW_HEIGHT 34.0
#define PANEL_WIDTH 640.0

@implementation SystemStatsView

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if(self)
    {
      previousCpuTotal = 0ULL;
      previousCpuIdle = 0ULL;
      previousNetRx = 0ULL;
      previousNetTx = 0ULL;
      lastSampleDate = nil;
      cpuPercent = 0.0;
      memoryPercent = 0.0;
      swapPercent = 0.0;
      diskPercent = 0.0;
      netRxRate = 0.0;
      netTxRate = 0.0;
      loadAverage1 = 0.0;
      temperatureCelsius = -1.0;
      memoryUsed = 0ULL;
      memoryTotal = 0ULL;
      swapUsed = 0ULL;
      swapTotal = 0ULL;
      diskUsed = 0ULL;
      diskTotal = 0ULL;
      uptimeSeconds = 0ULL;
      processCount = 0;
      threadCount = 0;
      [self updateTextAttributes];
      [self sampleStats];
    }
  return self;
}

- (void)dealloc
{
  RELEASE(lastSampleDate);
  RELEASE(titleAttributes);
  RELEASE(labelAttributes);
  RELEASE(valueAttributes);
  RELEASE(smallAttributes);
  [super dealloc];
}

- (void)updateTextAttributes
{
  NSDictionary *newTitleAttributes;
  NSDictionary *newLabelAttributes;
  NSDictionary *newValueAttributes;
  NSDictionary *newSmallAttributes;

  newTitleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				       [NSFont boldSystemFontOfSize: 30.0], NSFontAttributeName,
				       [NSColor whiteColor], NSForegroundColorAttributeName,
				       nil];
  newLabelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				       [NSFont boldSystemFontOfSize: 14.0], NSFontAttributeName,
				       [NSColor colorWithCalibratedWhite: 0.90 alpha: 1.0], NSForegroundColorAttributeName,
				       nil];
  newValueAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				       [NSFont userFixedPitchFontOfSize: 14.0], NSFontAttributeName,
				       [NSColor colorWithCalibratedWhite: 0.82 alpha: 1.0], NSForegroundColorAttributeName,
				       nil];
  newSmallAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				       [NSFont userFixedPitchFontOfSize: 12.0], NSFontAttributeName,
				       [NSColor colorWithCalibratedWhite: 0.70 alpha: 1.0], NSForegroundColorAttributeName,
				       nil];

  ASSIGN(titleAttributes, newTitleAttributes);
  ASSIGN(labelAttributes, newLabelAttributes);
  ASSIGN(valueAttributes, newValueAttributes);
  ASSIGN(smallAttributes, newSmallAttributes);
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
  return 1.0;
}

- (NSString *)windowTitle
{
  return @"System Stats";
}

- (void)sampleStats
{
  FILE *file;
  char line[PROC_LINE_LENGTH];
  unsigned long long user;
  unsigned long long nice;
  unsigned long long system;
  unsigned long long idle;
  unsigned long long iowait;
  unsigned long long irq;
  unsigned long long softirq;
  unsigned long long steal;
  unsigned long long total;
  unsigned long long idleAll;
  unsigned long long memTotal;
  unsigned long long memAvailable;
  unsigned long long swapTotalValue;
  unsigned long long swapFree;
  unsigned long long netRx;
  unsigned long long netTx;
  NSDate *now;
  NSTimeInterval elapsed;
  struct statvfs fs;

  now = [NSDate date];
  elapsed = (lastSampleDate == nil) ? 0.0 : [now timeIntervalSinceDate: lastSampleDate];

  file = fopen("/proc/stat", "r");
  if(file != NULL)
    {
      if(fgets(line, sizeof(line), file) != NULL)
	{
	  user = nice = system = idle = iowait = irq = softirq = steal = 0ULL;
	  if(sscanf(line, "cpu %llu %llu %llu %llu %llu %llu %llu %llu",
		    &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal) >= 4)
	    {
	      total = user + nice + system + idle + iowait + irq + softirq + steal;
	      idleAll = idle + iowait;
	      if(previousCpuTotal != 0ULL && total > previousCpuTotal)
		{
		  unsigned long long totalDelta = total - previousCpuTotal;
		  unsigned long long idleDelta = (idleAll > previousCpuIdle) ?
		    (idleAll - previousCpuIdle) : 0ULL;

		  if(totalDelta > 0ULL)
		    {
		      cpuPercent = 100.0 * (float)(totalDelta - idleDelta) / (float)totalDelta;
		    }
		}
	      previousCpuTotal = total;
	      previousCpuIdle = idleAll;
	    }
	}
      fclose(file);
    }

  memTotal = memAvailable = swapTotalValue = swapFree = 0ULL;
  file = fopen("/proc/meminfo", "r");
  if(file != NULL)
    {
      while(fgets(line, sizeof(line), file) != NULL)
	{
	  unsigned long long value = 0ULL;

	  if(sscanf(line, "MemTotal: %llu kB", &value) == 1)
	    {
	      memTotal = value * BYTES_PER_KIB;
	    }
	  else if(sscanf(line, "MemAvailable: %llu kB", &value) == 1)
	    {
	      memAvailable = value * BYTES_PER_KIB;
	    }
	  else if(sscanf(line, "SwapTotal: %llu kB", &value) == 1)
	    {
	      swapTotalValue = value * BYTES_PER_KIB;
	    }
	  else if(sscanf(line, "SwapFree: %llu kB", &value) == 1)
	    {
	      swapFree = value * BYTES_PER_KIB;
	    }
	}
      fclose(file);
    }
  memoryTotal = memTotal;
  memoryUsed = (memTotal > memAvailable) ? (memTotal - memAvailable) : 0ULL;
  memoryPercent = (memTotal == 0ULL) ? 0.0 : (100.0 * (float)memoryUsed / (float)memTotal);
  swapTotal = swapTotalValue;
  swapUsed = (swapTotalValue > swapFree) ? (swapTotalValue - swapFree) : 0ULL;
  swapPercent = (swapTotalValue == 0ULL) ? 0.0 : (100.0 * (float)swapUsed / (float)swapTotalValue);

  if(statvfs("/", &fs) == 0)
    {
      diskTotal = (unsigned long long)fs.f_blocks * (unsigned long long)fs.f_frsize;
      diskUsed = diskTotal - ((unsigned long long)fs.f_bavail * (unsigned long long)fs.f_frsize);
      diskPercent = (diskTotal == 0ULL) ? 0.0 : (100.0 * (float)diskUsed / (float)diskTotal);
    }

  netRx = netTx = 0ULL;
  file = fopen("/proc/net/dev", "r");
  if(file != NULL)
    {
      while(fgets(line, sizeof(line), file) != NULL)
	{
	  char *colon = strchr(line, ':');

	  if(colon != NULL)
	    {
	      char name[64];
	      unsigned long long rx = 0ULL;
	      unsigned long long tx = 0ULL;

	      if(sscanf(line, " %63[^:]:", name) == 1 && strcmp(name, "lo") != 0)
		{
		  if(sscanf(colon + 1, " %llu %*llu %*llu %*llu %*llu %*llu %*llu %*llu %llu",
			    &rx, &tx) == 2)
		    {
		      netRx += rx;
		      netTx += tx;
		    }
		}
	    }
	}
      fclose(file);
    }
  if(previousNetRx != 0ULL && elapsed > 0.0 && netRx >= previousNetRx && netTx >= previousNetTx)
    {
      netRxRate = (float)(netRx - previousNetRx) / (float)elapsed;
      netTxRate = (float)(netTx - previousNetTx) / (float)elapsed;
    }
  else
    {
      netRxRate = 0.0;
      netTxRate = 0.0;
    }
  previousNetRx = netRx;
  previousNetTx = netTx;

  loadAverage1 = 0.0;
  file = fopen("/proc/loadavg", "r");
  if(file != NULL)
    {
      fscanf(file, "%f", &loadAverage1);
      fclose(file);
    }

  uptimeSeconds = 0ULL;
  file = fopen("/proc/uptime", "r");
  if(file != NULL)
    {
      double uptime = 0.0;

      if(fscanf(file, "%lf", &uptime) == 1)
	{
	  uptimeSeconds = (unsigned long long)uptime;
	}
      fclose(file);
    }

  [self sampleProcessCounts];
  [self sampleTemperature];
  ASSIGN(lastSampleDate, now);
}

- (void)sampleProcessCounts
{
  DIR *procDir;
  struct dirent *entry;

  processCount = 0;
  threadCount = 0;
  procDir = opendir("/proc");
  if(procDir == NULL)
    {
      return;
    }

  while((entry = readdir(procDir)) != NULL)
    {
      char statusPath[256];
      FILE *statusFile;
      int isPid = 1;
      int i;

      for(i = 0; entry->d_name[i] != '\0'; i++)
	{
	  if(!isdigit((unsigned char)entry->d_name[i]))
	    {
	      isPid = 0;
	      break;
	    }
	}
      if(!isPid)
	{
	  continue;
	}

      processCount++;
      snprintf(statusPath, sizeof(statusPath), "/proc/%s/status", entry->d_name);
      statusFile = fopen(statusPath, "r");
      if(statusFile != NULL)
	{
	  char line[PROC_LINE_LENGTH];

	  while(fgets(line, sizeof(line), statusFile) != NULL)
	    {
	      int count = 0;

	      if(sscanf(line, "Threads: %d", &count) == 1)
		{
		  threadCount += count;
		  break;
		}
	    }
	  fclose(statusFile);
	}
    }
  closedir(procDir);
}

- (void)sampleTemperature
{
  DIR *thermalDir;
  struct dirent *entry;

  temperatureCelsius = -1.0;
  thermalDir = opendir("/sys/class/thermal");
  if(thermalDir == NULL)
    {
      return;
    }

  while((entry = readdir(thermalDir)) != NULL)
    {
      char tempPath[256];
      FILE *tempFile;
      int millidegrees = 0;

      if(strncmp(entry->d_name, "thermal_zone", 12) != 0)
	{
	  continue;
	}
      snprintf(tempPath, sizeof(tempPath), "/sys/class/thermal/%s/temp", entry->d_name);
      tempFile = fopen(tempPath, "r");
      if(tempFile != NULL)
	{
	  if(fscanf(tempFile, "%d", &millidegrees) == 1 && millidegrees > 0)
	    {
	      temperatureCelsius = (float)millidegrees / 1000.0;
	      fclose(tempFile);
	      break;
	    }
	  fclose(tempFile);
	}
    }
  closedir(thermalDir);
}

- (NSString *)sizeStringForBytes:(unsigned long long)bytes
{
  double value = (double)bytes;
  NSArray *units = [NSArray arrayWithObjects: @"B", @"KiB", @"MiB", @"GiB", @"TiB", nil];
  int unitIndex = 0;

  while(value >= 1024.0 && unitIndex < 4)
    {
      value /= 1024.0;
      unitIndex++;
    }
  return [NSString stringWithFormat: @"%.1f %@", value, [units objectAtIndex: unitIndex]];
}

- (NSString *)rateStringForBytesPerSecond:(float)bytesPerSecond
{
  return [NSString stringWithFormat: @"%@/s",
		   [self sizeStringForBytes: (unsigned long long)bytesPerSecond]];
}

- (NSString *)uptimeString
{
  unsigned long long days = uptimeSeconds / 86400ULL;
  unsigned long long hours = (uptimeSeconds / 3600ULL) % 24ULL;
  unsigned long long minutes = (uptimeSeconds / 60ULL) % 60ULL;

  if(days > 0ULL)
    {
      return [NSString stringWithFormat: @"%llud %lluh %llum", days, hours, minutes];
    }
  return [NSString stringWithFormat: @"%lluh %llum", hours, minutes];
}

- (void)drawRect:(NSRect)rects
{
  [[NSColor blackColor] set];
  NSRectFill(rects);
  [self drawStats];
}

- (void)drawStats
{
  NSRect bounds = [self bounds];
  float panelWidth = MIN(PANEL_WIDTH, bounds.size.width - 48.0);
  float startX = (bounds.size.width - panelWidth) / 2.0;
  float y = bounds.size.height - 74.0;
  NSString *subtitle;
  NSString *cpuValue;
  NSString *memoryValue;
  NSString *swapValue;
  NSString *diskValue;
  NSString *netValue;
  NSString *otherValue;

  if(panelWidth < 260.0)
    {
      panelWidth = bounds.size.width - 20.0;
      startX = 10.0;
    }

  [@"System Stats" drawAtPoint: NSMakePoint(startX, y) withAttributes: titleAttributes];
  y -= 28.0;

  subtitle = [NSString stringWithFormat: @"Load %.2f   Uptime %@   Processes %d   Threads %d",
		       loadAverage1, [self uptimeString], processCount, threadCount];
  [subtitle drawAtPoint: NSMakePoint(startX, y) withAttributes: smallAttributes];
  y -= 44.0;

  cpuValue = [NSString stringWithFormat: @"%.0f%%   load %.2f", cpuPercent, loadAverage1];
  [self drawMeterAtY: y label: @"CPU" value: cpuValue percent: cpuPercent
	      color: [NSColor colorWithCalibratedRed: 0.13 green: 0.62 blue: 0.89 alpha: 1.0]];
  y -= ROW_HEIGHT;

  memoryValue = [NSString stringWithFormat: @"%@ / %@   %.0f%%",
			  [self sizeStringForBytes: memoryUsed],
			  [self sizeStringForBytes: memoryTotal],
			  memoryPercent];
  [self drawMeterAtY: y label: @"Memory" value: memoryValue percent: memoryPercent
	      color: [NSColor colorWithCalibratedRed: 0.32 green: 0.78 blue: 0.45 alpha: 1.0]];
  y -= ROW_HEIGHT;

  swapValue = (swapTotal == 0ULL) ? @"not configured" :
    [NSString stringWithFormat: @"%@ / %@   %.0f%%",
	      [self sizeStringForBytes: swapUsed],
	      [self sizeStringForBytes: swapTotal],
	      swapPercent];
  [self drawMeterAtY: y label: @"Swap" value: swapValue percent: swapPercent
	      color: [NSColor colorWithCalibratedRed: 0.89 green: 0.68 blue: 0.20 alpha: 1.0]];
  y -= ROW_HEIGHT;

  diskValue = [NSString stringWithFormat: @"%@ / %@   %.0f%%",
			[self sizeStringForBytes: diskUsed],
			[self sizeStringForBytes: diskTotal],
			diskPercent];
  [self drawMeterAtY: y label: @"Disk /" value: diskValue percent: diskPercent
	      color: [NSColor colorWithCalibratedRed: 0.72 green: 0.48 blue: 0.92 alpha: 1.0]];
  y -= ROW_HEIGHT;

  netValue = [NSString stringWithFormat: @"down %@   up %@",
		       [self rateStringForBytesPerSecond: netRxRate],
		       [self rateStringForBytesPerSecond: netTxRate]];
  [self drawMeterAtY: y label: @"Network" value: netValue percent: 0.0
	      color: [NSColor colorWithCalibratedRed: 0.94 green: 0.30 blue: 0.25 alpha: 1.0]];
  y -= ROW_HEIGHT;

  if(temperatureCelsius >= 0.0)
    {
      otherValue = [NSString stringWithFormat: @"Temperature %.1f C", temperatureCelsius];
    }
  else
    {
      otherValue = @"Temperature unavailable";
    }
  [otherValue drawAtPoint: NSMakePoint(startX, y) withAttributes: valueAttributes];
}

- (void)drawMeterAtY:(float)y
	       label:(NSString *)label
	       value:(NSString *)value
	     percent:(float)percent
	      color:(NSColor *)color
{
  NSRect bounds = [self bounds];
  float panelWidth = MIN(PANEL_WIDTH, bounds.size.width - 48.0);
  float startX = (bounds.size.width - panelWidth) / 2.0;
  float labelWidth = 110.0;
  float valueWidth = 250.0;
  float meterX;
  float meterWidth;
  NSRect meterRect;
  NSRect fillRect;

  if(panelWidth < 260.0)
    {
      panelWidth = bounds.size.width - 20.0;
      startX = 10.0;
      labelWidth = 82.0;
      valueWidth = 160.0;
    }

  meterX = startX + labelWidth;
  meterWidth = panelWidth - labelWidth - valueWidth - 12.0;
  if(meterWidth < 80.0)
    {
      meterWidth = panelWidth - labelWidth;
      valueWidth = 0.0;
    }

  [label drawAtPoint: NSMakePoint(startX, y + 1.0) withAttributes: labelAttributes];

  meterRect = NSMakeRect(meterX, y, meterWidth, METER_HEIGHT);
  [[NSColor colorWithCalibratedWhite: 0.16 alpha: 1.0] set];
  NSRectFill(meterRect);

  if(percent > 100.0)
    {
      percent = 100.0;
    }
  if(percent < 0.0)
    {
      percent = 0.0;
    }
  fillRect = meterRect;
  fillRect.size.width = meterRect.size.width * percent / 100.0;
  [color set];
  NSRectFill(fillRect);

  [[NSColor colorWithCalibratedWhite: 0.36 alpha: 1.0] set];
  NSFrameRect(meterRect);

  if(valueWidth > 0.0)
    {
      [value drawAtPoint: NSMakePoint(meterX + meterWidth + 12.0, y + 1.0)
	  withAttributes: valueAttributes];
    }
  else
    {
      [value drawAtPoint: NSMakePoint(startX, y - 17.0)
	  withAttributes: smallAttributes];
    }
}

- (void)oneStep
{
  [self sampleStats];
  [self setNeedsDisplay: YES];
  [self display];
}

@end

@implementation StaticSystemStatsView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect: rects];
}
@end
