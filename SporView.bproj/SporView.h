
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface SporView:NSView
{
	id	inspector;
	id	startPop;
	id	maxPop;
	id	startSpread;
	id	startCloud;
	id	kindRadio;
	id	eatRadio;
	id	sporWindow;

	int	kind,
			enemy,
			pop,
			sPop,
			spread,
		 	cloud;
	BOOL	initDone,
				inspectorPresent;

}

- (void) oneStep;
- (id) initWithFrame:( NSRect )frameRect;
- (void) drawRect:(NSRect)rects;
/// - sizeToFit:(NSSize)size;

- initializeSimulationForBounds:(NSRect)bounds;

- (void)inspectorInstalled;
- (void)inspectorWillBeRemoved;
- (NSView *)inspector: sender;

- toggleKind:sender;
- toggleEnemy:sender;

- getStartParameter;
- showStartParameter;
- ( int )setRangeForValue:( int )aValue Low:( int )low High:( int )high;

@end
