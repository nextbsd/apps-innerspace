#include <stdint.h>
#include <math.h>

// Counter resets and first samples must never look like a burst of activity.
static double CMBusyFraction(uint64_t busy, uint64_t total,
                             uint64_t oldBusy, uint64_t oldTotal)
{
  if(total <= oldTotal || busy < oldBusy) return 0;
  return fmin(1.0, (double)(busy-oldBusy)/(double)(total-oldTotal));
}
static double CMByteRate(uint64_t value, uint64_t previous, double seconds)
{
  return seconds > 0 && value >= previous ? (value-previous)/seconds : 0;
}
static double CMNetworkIntensity(double rate)
{
  // Fixed logarithmic scale: quiet interfaces stay dark, 1 MiB/s fills a panel.
  return fmin(1.0, log1p(fmax(0, rate)/1024.0)/log(1025.0));
}
