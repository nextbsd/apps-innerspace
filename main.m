#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

#if defined(_WIN32) || defined(WIN32)

#include <windows.h>

#else

#include <errno.h>
#include <sys/resource.h>
#include <string.h>

#endif

#define APP_NAME @"InnerSpace"

static void
InnerSpaceSetLowPriority(void)
{
#if defined(_WIN32) || defined(WIN32)
  SetPriorityClass(GetCurrentProcess(), IDLE_PRIORITY_CLASS);
  SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_IDLE);
#else
  if (setpriority(PRIO_PROCESS, 0, 19) != 0 && errno != EACCES)
    {
      NSLog(@"Unable to lower InnerSpace priority: %s", strerror(errno));
    }
#endif
}

/*
 * Initialise and go!
 */

int main(int argc, const char *argv[]) 
{
  InnerSpaceSetLowPriority();
  return NSApplicationMain (argc, argv);
}
