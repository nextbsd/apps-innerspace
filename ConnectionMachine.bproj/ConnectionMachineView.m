#include "ConnectionMachineView.h"
#include "ConnectionMachineMetrics.h"
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if defined(__APPLE__)
#include <mach/mach.h>
#include <sys/sysctl.h>
#include "../SystemStats.bproj/SystemStatsNetwork.h"
#endif

static double CMTime(void)
{
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec + t.tv_nsec/1e9;
}
static NSColor *CMLightColor(CGFloat r, CGFloat g, CGFloat b)
{
  return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1];
}
static void CMText(NSString *text, CGFloat x, CGFloat y, CGFloat size, NSColor *color)
{
  [text drawAtPoint:NSMakePoint(x,y) withAttributes:
    [NSDictionary dictionaryWithObjectsAndKeys:[NSFont userFixedPitchFontOfSize:size],
      NSFontAttributeName,color,NSForegroundColorAttributeName,nil]];
}
static uint32_t CMHash(uint32_t x)
{
  x ^= x >> 16; x *= 0x7feb352d; x ^= x >> 15; x *= 0x846ca68b; return x ^ (x >> 16);
}

@implementation ConnectionMachineView
- (id)initWithFrame:(NSRect)rect
{
  if((self = [super initWithFrame:rect])) [self sampleActivity];
  return self;
}
- (BOOL)isOpaque { return YES; }
- (BOOL)useBufferedWindow { return YES; }
- (NSString *)windowTitle { return @"Connection Machine"; }
- (NSTimeInterval)animationDelayTime { return 1.0/24.0; }

- (void)sampleActivity
{
  double now=CMTime();
  uint64_t busy[CM_MAX_CPUS]={0}, total[CM_MAX_CPUS]={0}, rx=0, tx=0;
  NSUInteger count=0;
  BOOL gotNetwork=NO;
#if defined(__APPLE__)
  natural_t processors=0;
  processor_info_array_t info=NULL;
  mach_msg_type_number_t infoCount=0;
  mach_port_t host=mach_host_self();
  if(host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &processors, &info, &infoCount)==KERN_SUCCESS) {
    count=MIN(processors,CM_MAX_CPUS);
    for(NSUInteger i=0;i<count;i++) {
      // Mach ticks are unsigned 32-bit counters even though integer_t is signed.
      busy[i]=(uint32_t)info[i*CPU_STATE_MAX+CPU_STATE_USER]
        +(uint64_t)(uint32_t)info[i*CPU_STATE_MAX+CPU_STATE_SYSTEM]
        +(uint64_t)(uint32_t)info[i*CPU_STATE_MAX+CPU_STATE_NICE];
      total[i]=busy[i]+(uint64_t)(uint32_t)info[i*CPU_STATE_MAX+CPU_STATE_IDLE];
    }
    vm_deallocate(mach_task_self(),(vm_address_t)info,infoCount*sizeof(integer_t));
  }
  mach_port_deallocate(mach_task_self(),host);
  int mib[]={CTL_NET,PF_ROUTE,0,0,NET_RT_IFLIST2,0};
  size_t length=0;
  if(sysctl(mib,6,NULL,&length,NULL,0)==0 && length>0) {
    void *buffer=malloc(length);
    if(buffer && sysctl(mib,6,buffer,&length,NULL,0)==0) {
      unsigned long long received,sent;
      SystemStatsNetworkCounters(buffer,length,&received,&sent);
      rx=received; tx=sent; gotNetwork=YES;
    }
    free(buffer);
  }
#elif defined(__linux__)
  FILE *file=fopen("/proc/stat","r");
  char line[1024];
  if(file) {
    while(fgets(line,sizeof(line),file)) {
      unsigned int index;
      unsigned long long user,nice,system,idle,wait=0,irq=0,soft=0,steal=0;
      if(line[3]>='0' && line[3]<='9' && sscanf(line,"cpu%u %llu %llu %llu %llu %llu %llu %llu %llu",
          &index,&user,&nice,&system,&idle,&wait,&irq,&soft,&steal)>=5 && count<CM_MAX_CPUS) {
        busy[count]=user+nice+system+irq+soft+steal;
        total[count]=busy[count]+idle+wait; count++;
      }
    }
    fclose(file);
  }
  file=fopen("/proc/net/dev","r");
  if(file) {
    while(fgets(line,sizeof(line),file)) {
      char name[128]; unsigned long long received,sent;
      if(sscanf(line," %127[^:]: %llu %*u %*u %*u %*u %*u %*u %*u %llu",name,&received,&sent)==3) {
        if(strcmp(name,"lo")!=0) { rx+=received; tx+=sent; }
        gotNetwork=YES;
      }
    }
    fclose(file);
  }
#endif
  cpuAvailable=count>0;
  for(NSUInteger i=0;i<count;i++) {
    cpu[i]=cpuReady && count==cpuCount ? CMBusyFraction(busy[i],total[i],previousBusy[i],previousTotal[i]) : 0;
    previousBusy[i]=busy[i]; previousTotal[i]=total[i];
  }
  cpuCount=count; cpuReady=cpuAvailable;
  networkAvailable=gotNetwork;
  rxRate=txRate=0;
  if(gotNetwork) {
    if(networkReady) {
      rxRate=CMByteRate(rx,previousRx,now-lastNetworkSample);
      txRate=CMByteRate(tx,previousTx,now-lastNetworkSample);
    }
    previousRx=rx; previousTx=tx; lastNetworkSample=now;
  }
  networkReady=gotNetwork;
  lastSample=now;
}
- (void)oneStep
{
  double now=CMTime();
  if(now-lastSample>=0.5) [self sampleActivity];
  double dt=lastFrame>0 ? fmin(now-lastFrame,1.0) : 1.0/24.0;
  lastFrame=now; frameNumber++;
  float decay=exp(-dt/0.10);
  for(unsigned int i=0;i<4096;i++) {
    unsigned int panel=i/512, row=(i%512)/32;
    double activity=panel<6 ? (cpuCount ? cpu[(panel*16+row)%cpuCount] : 0)
      : CMNetworkIntensity(panel==6 ? rxRate : txRate);
    // A measured duty cycle, with a shuffled spatial pattern and LED persistence.
    double threshold=(CMHash(i ^ (frameNumber*0x9e3779b9U))&0xffff)/65536.0;
    lights[i]=threshold<activity ? 1.0 : lights[i]*decay;
  }
#if defined(__APPLE__) && !defined(GNUSTEP)
  [self drawRect:[self bounds]];
#else
  [self setNeedsDisplay:YES];
#endif
}
- (void)drawRect:(NSRect)dirty
{
  [[NSColor blackColor] set]; NSRectFill([self bounds]);
  NSRect bounds=[self bounds];
  CGFloat scale=MIN(bounds.size.width/1100.0,bounds.size.height/660.0);
  if(scale<=0) return;
  [NSGraphicsContext saveGraphicsState];
  NSAffineTransform *transform=[NSAffineTransform transform];
  [transform translateXBy:NSMidX(bounds)-550*scale yBy:NSMidY(bounds)-330*scale];
  [transform scaleBy:scale]; [transform concat];
  CMText(@"CONNECTION MACHINE",38,602,22,CMLightColor(.76,.77,.76));
  CMText(@"LIVE SYSTEM ACTIVITY  /  4096 INDICATORS",40,582,10,CMLightColor(.38,.40,.41));
  for(unsigned int panel=0;panel<8;panel++) {
    CGFloat x=38+(panel%4)*258, y=72+(1-panel/4)*252;
    [CMLightColor(.055,.057,.06) set]; NSRectFill(NSMakeRect(x,y,250,240));
    [CMLightColor(.16,.17,.18) set]; NSFrameRect(NSMakeRect(x,y,250,240));
    [CMLightColor(.012,.013,.015) set]; NSRectFill(NSMakeRect(x+8,y+33,234,195));
    NSString *label=panel<6 ? [NSString stringWithFormat:@"%02u  PROCESSOR ARRAY",panel+1]
      : (panel==6 ? @"07  NETWORK / RECEIVE" : @"08  NETWORK / TRANSMIT");
    CMText(label,x+13,y+13,10,CMLightColor(.43,.44,.44));
    for(unsigned int row=0;row<16;row++) for(unsigned int col=0;col<32;col++) {
      unsigned int i=panel*512+row*32+col;
      CGFloat px=x+17+col*7, py=y+46+(15-row)*11;
      float light=lights[i];
      if(light>.08) {
        [CMLightColor(.10+light*.16,.012,.008) set];
        NSRectFill(NSMakeRect(px-1.5,py-1.5,6,6));
      }
      [CMLightColor(.075+light*.925,.008+light*.13,.005+light*.055) set];
      NSRectFill(NSMakeRect(px,py,3,3));
    }
  }
  double mean=0; for(NSUInteger i=0;i<cpuCount;i++) mean+=cpu[i];
  NSString *cpuText=cpuAvailable ? [NSString stringWithFormat:@"CPU %5.1f%% / %lu CORES",100*mean/cpuCount,(unsigned long)cpuCount] : @"CPU UNAVAILABLE";
  NSString *networkText=networkAvailable ? [NSString stringWithFormat:@"RX %.1f KiB/s   TX %.1f KiB/s",rxRate/1024,txRate/1024] : @"NETWORK UNAVAILABLE";
  CMText([NSString stringWithFormat:@"%@     %@",cpuText,networkText],40,41,12,CMLightColor(.58,.59,.60));
  CMText(@"CPU ROWS FOLLOW LOGICAL CORES / NETWORK BRIGHTNESS USES A LOG SCALE",40,22,9,CMLightColor(.30,.32,.33));
  [NSGraphicsContext restoreGraphicsState];
}
@end
