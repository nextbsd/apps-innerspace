/* All Rights reserved */

#import <AppKit/AppKit.h>
#import "InnerSpaceController.h"

@implementation InnerSpaceController

// interface callbacks
- (void) selectSaver: (id)sender
{
  NSLog(@"Called");
  /* insert your code here */
}


- (void) inBackground: (id)sender
{
  NSLog(@"Called");
  /* insert your code here */
}


- (void) locker: (id)sender
{
  NSLog(@"Called");
  /* insert your code here */
}


- (void) saver: (id)sender
{
  NSLog(@"Called");
  /* insert your code here */
}


- (void) doSaver: (id)sender
{
  NSLog(@"Called");
  [self createSaverWindow: YES];
  [self startTimer];
  /* insert your code here */
}

- (NSArray *) modules
{
  return [NSArray arrayWithObject: @"Test"];
}

// internal methods..
- (void)createSaverWindow: (BOOL)desktop
{
  NSRect frame = [[NSScreen mainScreen] frame];
  int store = NSBackingStoreNonretained;

  // dertermine backing type...
  NS_DURING
  if([currentModule respondsToSelector: @selector(useBufferedWindow)])
    {
      if([currentModule useBufferedWindow])
	{
	  store = NSBackingStoreBuffered;
	}
    }
  NS_HANDLER
    NSLog(@"EXCEPTION: %@",localException);
    store = NSBackingStoreBuffered;
  NS_ENDHANDLER

  // create the window...
  saverWindow = [[SaverWindow alloc] initWithContentRect: frame
				     styleMask: NSBorderlessWindowMask
				     backing: store
				     defer: NO];

  NSLog(@"In here: %@", saverWindow); 
  
  
  // set some attributes...
  [saverWindow setAction: @selector(stopSaver) forTarget: self];
  [saverWindow setAutodisplay: YES];
  [saverWindow makeFirstResponder: saverWindow];
  [saverWindow setExcludedFromWindowsMenu: YES];
  [saverWindow setBackgroundColor: [NSColor blackColor]];
  [saverWindow setOneShot:YES];

  // run the saver in on the desktop.
  if(desktop)
    {
      [saverWindow setLevel: NSDesktopWindowLevel];
    } 
  else
    {
      [saverWindow setLevel: NSScreenSaverWindowLevel];
    }

  [saverWindow makeKeyAndOrderFront: self];
}

- (void)destroySaverWindow
{
  [saverWindow close];
  saverWindow = nil;
}

- (void) stopSaver
{
  [self destroySaverWindow];
  [self stopTimer];
  NSLog(@"stopping");
}

// timer managment
- (void) startTimer
{
  NSTimeInterval time = 0.03;

  NS_DURING
    {
      if([currentModule respondsToSelector: @selector(animationDelayTime)])
	{
	  time = [currentModule animationDelayTime];
	}
    }
  NS_HANDLER
    {
      NSLog(@"EXCEPTION: %@", localException);
      time = 0.03;
    }
  NS_ENDHANDLER
    
  timer = [NSTimer scheduledTimerWithTimeInterval: time
		   target: self
		   selector: @selector(runAnimation:)
		   userInfo: nil
		   repeats: YES];
  RETAIN(timer);
}

- (void) stopTimer
{
  if(timer != nil)
    {
      [timer invalidate];
      RELEASE(timer);
      timer = nil;
    }
}

- (void) runAnimation: (NSTimer *)atimer
{
  NSLog(@"Animation");
}
@end

// delegate
@interface InnerSpaceController(BrowserDelegate)
- (BOOL) browser: (NSBrowser*)sender selectRow: (int)row inColumn: (int)column;

- (void) browser: (NSBrowser *)sender createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix;

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)column;

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column;

- (BOOL) browser: (NSBrowser *)sender isColumnValid: (int)column;
@end

@implementation InnerSpaceController(BrowserDelegate)
- (BOOL) browser: (NSBrowser*)sender selectRow: (int)row inColumn: (int)column
{
  return YES;
}

- (void) browser: (NSBrowser *)sender createRowsForColumn: (int)column
	inMatrix: (NSMatrix *)matrix
{
  NSArray    *modules = [self modules];
  NSEnumerator     *e = [modules objectEnumerator];
  NSString    *module = nil;
  NSBrowserCell *cell = nil;
  int i = 0;

  while((module = [e nextObject]) != nil)
    {
      [matrix insertRow: i withCells: nil];
      cell = [matrix cellAtRow: i column: 0];
      [cell setLeaf: YES];
      i++;
      [cell setStringValue: module];
    }
}

- (NSString*) browser: (NSBrowser*)sender titleOfColumn: (int)column
{
  return @"Modules";
}

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column
{
}

- (BOOL) browser: (NSBrowser *)sender isColumnValid: (int)column
{
  return NO;
}
@end
