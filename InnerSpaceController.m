/* All Rights reserved */

#include <AppKit/AppKit.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include "InnerSpaceController.h"

@implementation InnerSpaceController

// interface callbacks
- (void) selectSaver: (id)sender
{
  id module = nil;
  int row = [moduleList selectedRowInColumn: [moduleList selectedColumn]];

  if(row >= 0)
    {
      module = [[modules allKeys] objectAtIndex: row];
      [defaults setObject: module forKey: @"currentModule"];
      [self loadModule: module];
    }

  NSLog(@"Called");
  /* insert your code here */
}

- (void) inBackground: (id)sender
{
  isInBackground = ([inBackground state] == NSOnState);
}

- (void) locker: (id)sender
{
  isLocker = ([locker state] == NSOnState);
}

- (void) saver: (id)sender
{
  isSaver = ([saver state] == NSOnState);
}

- (void) doSaver: (id)sender
{
  NSLog(@"Called");
  [self createSaverWindow: YES];
  [self startTimer];
  /* insert your code here */
}

// internal methods..
- (void) _loadDefaults
{
  NSDictionary *appDefs = [NSDictionary dictionaryWithObjectsAndKeys:
					  @"Black",@"currentModule",nil];
  defaults = [NSUserDefaults standardUserDefaults];
  [defaults registerDefaults: appDefs];

  currentModuleName = [defaults stringForKey: @"currentModule"];
  NSLog(@"current module = %@",currentModuleName);
}

- (NSMutableDictionary *) modules
{
  return modules;
}

- (void) _findModulesInDirectory: (NSString *) directory
{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray *files = [fm directoryContentsAtPath: directory];
  NSEnumerator *en = [files objectEnumerator];
  id item = nil;

  NSLog(@"directory = %@",directory);
  while((item = [en nextObject]) != nil)
    {
      NSLog(@"file = %@",item);
      if([[item pathExtension] isEqualToString: @"InnerSpace"])
	{
	  NSString *fullPath = [directory stringByAppendingPathComponent: item];
	  NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
	  
	  [infoDict setObject: fullPath forKey: @"Path"];

	  [modules setObject: infoDict forKey: [item stringByDeletingPathExtension]];
	  NSLog(@"modules = %@",modules);
	}
    }
}

- (void) _findModules
{
  [self _findModulesInDirectory: [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: @"Resources"]];
  [self _findModulesInDirectory: [NSHomeDirectory() stringByAppendingPathComponent: @"/GNUstep/Library/InnerSpace"]];
}

- (void) awakeFromNib
{
  modules = RETAIN([NSMutableDictionary dictionary]);
  [self _findModules];
  [self _loadDefaults];
  [self loadModule: currentModuleName];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notification
{
  // The saver is *always running...
  NSLog(@"Notified");
  [self doSaver: self];
}

- (void) createSaverWindow: (BOOL)desktop
{
  NSRect frame = [[NSScreen mainScreen] frame];
  int store = NSBackingStoreRetained;

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

  // set up the backing store...
  if(store == NSBackingStoreBuffered)
    {
      [saverWindow useOptimizedDrawing: YES];
      [saverWindow setDynamicDepthLimit: YES];
    }

  // run the saver in on the desktop...
  if(desktop)
    {
      [saverWindow setLevel: NSDesktopWindowLevel];
    } 
  else
    {
      [saverWindow setLevel: NSScreenSaverWindowLevel];
    }

  // load the view from the currently active module, if
  // there is one...
  if(currentModule)
    {
      [saverWindow setContentView: currentModule];
      NS_DURING
	if([currentModule respondsToSelector: @selector(willEnterScreenSaverMode)])
	  {
	    [currentModule willEnterScreenSaverMode];
	  }
      NS_HANDLER
	NSLog(@"EXCEPTION while creating saver window %@",localException);
      NS_ENDHANDLER
    }
  
  [saverWindow makeKeyAndOrderFront: self];
}

- (void) destroySaverWindow
{
  [saverWindow close];
  saverWindow = nil;
}

- (void) stopSaver
{
  NSLog(@"%@",[inBackground stringValue]);
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
    
  if(![currentModule respondsToSelector: @selector(isBoringScreenSaver)])
    {
      timer = [NSTimer scheduledTimerWithTimeInterval: time
		       target: self
		       selector: @selector(runAnimation:)
		       userInfo: nil
		       repeats: YES];
    }
  else
    {
      // if the screen saver is "boring" it should only run oneStep
      // once.   This means that it will not waste CPU cycles spinning and
      // doing nothing...
      NS_DURING
	// do one frame..
	[currentModule lockFocus];
        if([currentModule respondsToSelector: @selector(didLockFocus)])
	  {
	    [currentModule didLockFocus];
	  }
	[currentModule oneStep];
	[saverWindow flushWindow];
	[currentModule unlockFocus];
      NS_HANDLER
	NSLog(@"EXCEPTION: %@",localException);
      NS_ENDHANDLER      
    }
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
  if(!saverWindow)
    {
      return;
    }
  else
    {
      NS_DURING
	// do one frame..
	[currentModule lockFocus];
        if([currentModule respondsToSelector: @selector(didLockFocus)])
	  {
	    [currentModule didLockFocus];
	  }
	[currentModule oneStep];
	[saverWindow flushWindow];
	[currentModule unlockFocus];
      NS_HANDLER
	NSLog(@"EXCEPTION while in running animation: %@",localException);
      NS_ENDHANDLER
    }
}

- (void) _startModule: (ModuleView *)moduleView
{
  NSView *inspectorView = nil;
  NS_DURING
    if([moduleView respondsToSelector: @selector(inspector:)])
      {
	inspectorView = [moduleView inspector: self];
	[(NSBox *)controlsView setBorderType: NSNoBorder];
	[(NSBox *)controlsView setContentView: inspectorView];
	if([moduleView respondsToSelector: @selector(inspectorInstalled)])
	  {
	    [moduleView inspectorInstalled];
	  }
      }
    [self createSaverWindow: YES];
    [self startTimer];
  NS_HANDLER

  NS_ENDHANDLER
}

- (void) _stopModule: (ModuleView *)moduleView
{
  NS_DURING
    if([moduleView respondsToSelector: @selector(inspectorWillBeRemoved)])
      {
	[moduleView inspectorWillBeRemoved];
      }
    [self stopSaver];
  NS_HANDLER
    NSLog(@"EXCEPTION while in _stopModule: %@",localException);
  NS_ENDHANDLER

  [(NSBox *)controlsView setContentView: nil];
  [(NSBox *)controlsView setBorderType: NSGrooveBorder];
}

- (NSString *) _pathForModule: (NSString *) moduleName
{
  NSString *result = nil;
  NSMutableDictionary *dict;

  if(dict = [modules objectForKey: moduleName])
    {
      result = [dict objectForKey: @"Path"];
    }
  return result;
}

- (void) loadModule: (NSString *)moduleName
{
  id newModule = nil;

  if(moduleName)
    {
      NSBundle *bundle = nil;
      Class    theViewClass;
      id       module = nil;
      NSString *bundlePath = [self _pathForModule: moduleName];
      
      NSDebugLog(@"Bundle path = %@",bundlePath);
      bundle = [NSBundle bundleWithPath: bundlePath];
      if(bundle != nil)
	{
	  NSLog(@"Bundle loaded");
	  theViewClass = [bundle principalClass];
	  if(theViewClass != nil)
	    {
	      newModule = [[theViewClass alloc] initWithFrame: [[NSScreen mainScreen] frame]];
	    }
	}
    }
  
  if(newModule != currentModule)
    {
      if(currentModule)
	{
	  [self _stopModule: currentModule];
	}
      
      currentModule = (ModuleView *)newModule;
      [self _startModule: currentModule];
      [controlsView display];
    }
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
  NSEnumerator     *e = [[[self modules] allKeys] objectEnumerator];
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
