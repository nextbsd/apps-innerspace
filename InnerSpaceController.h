/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "SaverWindow.h"

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
}
// methods called from interface
- (void) selectSaver: (id)sender;
- (void) inBackground: (id)sender;
- (void) locker: (id)sender;
- (void) saver: (id)sender;
- (void) doSaver: (id)sender;

// internal methods
- (NSArray *)modules;
- (void)createSaverWindow;
@end
