/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "SaverWindow.h"
#import "ModuleView.h"

@interface InnerSpaceController : NSObject
{
  // interface vars.
  id window;
  id moduleList;
  id inBackground;
  id locker;
  id saver;
  id run;
  id controlsView;

  // internal vars.
  SaverWindow *saverWindow;
  NSTimer *timer;
  ModuleView *currentModule;
  NSMutableArray *modules;
  
  // booleans...
  BOOL isSaver;
  BOOL isLocker;
  BOOL isInBackground;
}
// methods called from interface
- (void) selectSaver: (id)sender;
- (void) inBackground: (id)sender;
- (void) locker: (id)sender;
- (void) saver: (id)sender;
- (void) doSaver: (id)sender;

// internal methods
- (NSArray *) modules;
- (void) createSaverWindow: (BOOL)desktop;
- (void) startTimer;
- (void) stopTimer;
- (void) runAnimation: (NSTimer *)atimer;
- (void) loadModule: (NSString *)moduleName;
@end
