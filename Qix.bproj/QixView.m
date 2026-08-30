
#import	<stdlib.h>
#import	<math.h>
#import	<AppKit/NSApplication.h>
#import	<AppKit/NSSlider.h>
#import	<AppKit/NSButton.h>
#import	<AppKit/NSImage.h>
#import	<AppKit/PSOperators.h>
#import	"QixView.h"

/**********************************************************************/

#define	LEFT		( 100 )
#define	RIGHT		( 101 )
#define	UP			( 102 )
#define	DOWN		( 103 )

#define	INITLEN		( 55 )				//	Initial qix tail length.

#define	A_BASE_INC	( 5 )				//	Default distance to move the
										//	"A" point of a qix structure.
#define	B_BASE_INC	( 8 )				//	Default distance to move the
										//	"B" point of a qix structure.
#define	DRAW_WIDTH	( 0.5 )
#define	ERASE_WIDTH	( 2.0 )

static const float qixColors[][3] = {
	{ 1.0, 0.15, 0.15 },
	{ 1.0, 0.75, 0.10 },
	{ 0.10, 0.95, 0.35 },
	{ 0.10, 0.75, 1.0 },
	{ 0.65, 0.35, 1.0 },
	{ 1.0, 0.25, 0.75 }
};

#define	NUM_QIX_COLORS	( sizeof( qixColors ) / sizeof( qixColors[0] ) )

/**********************************************************************/


@implementation QixView

/**********************************************************************/

- newWindow
{
	[ self resetQix : &head : NO ];
	[ self resetQix : &tail : YES ];
	
	return self;
}
 
/**********************************************************************/

- (NSString *) windowTitle
{
	return ( NSString * ) "Qix Lines";
}

/**********************************************************************/

- initWithFrame : ( NSRect ) frameRect
{
	[ super initWithFrame : frameRect ];
	
	[ self resetQix : &head : NO ];
	[ self resetQix : &tail : YES ];
	
	return self;
}

- (BOOL) isOpaque
{
  return YES;
}

/**********************************************************************/

- (void) setFrame: (NSRect) size 
{
  [ super setFrame: size];
  
  [ self resetQix : &head : NO ];
  [ self resetQix : &tail : YES ];
}

/**********************************************************************/

- resetQix : ( QIX * ) qix : ( BOOL ) resetControls
{
  NSRect bounds = [self bounds];

  if( resetControls == YES )
  {
    tailLen = INITLEN;
    colorIndex = 0;
  }
	
	qix->pointA.x = bounds.size.width / 3.0;
	qix->pointA.y = bounds.size.height / 3.0;
	qix->pointA.x_dir = RIGHT;
	qix->pointA.y_dir = DOWN;
	qix->pointA.x_inc = A_BASE_INC;
	qix->pointA.y_inc = A_BASE_INC;
	qix->pointA.orig_inc = A_BASE_INC;
	
	qix->pointB.x = bounds.size.width / 2.0;
	qix->pointB.y = bounds.size.height / 2.0;
	qix->pointB.x_dir = LEFT;
	qix->pointB.y_dir = UP;
	qix->pointB.x_inc = B_BASE_INC;
	qix->pointB.y_inc = B_BASE_INC;
	qix->pointB.orig_inc = B_BASE_INC;
	
	return self;
}

/**********************************************************************/
	
- setQixPoint : ( MVPOINT * ) point
{
  NSRect bounds = [self bounds];
	if( point->x >= bounds.size.width )
	{
		point->x_dir = LEFT;
		point->x_inc = point->orig_inc;
	}
	else if( point->x <= 0 )
		point->x_dir = RIGHT;
	
	if( point->x_dir == RIGHT )
	{
		point->x += point->x_inc;
		point->x_inc -= .009;
	}
	else
	{
		point->x -= point->x_inc;
		point->x_inc += .03;
	}

	if( point->y >= bounds.size.height )
	{
		point->y_dir = DOWN;
		point->y_inc = point->orig_inc;
	}
	else if( point->y <= 0 )
		point->y_dir = UP;
		
	if( point->y_dir == UP )
	{
		point->y += point->y_inc;
		point->y_inc -= .009;
	}
	else
	{
		point->y -= point->y_inc;
		point->y_inc += .06;
	}
		
	return self;
}

/**********************************************************************/

- drawQix : ( QIX ) qix width : ( float ) width
{
	PSsetlinewidth( width );

	PSmoveto( qix.pointA.x, qix.pointA.y );
	PSlineto( qix.pointB.x, qix.pointB.y );
	PSstroke( );
	
	return self;
}

/**********************************************************************/

- setQixColor
{
	PSsetrgbcolor( qixColors[colorIndex][0],
				   qixColors[colorIndex][1],
				   qixColors[colorIndex][2] );
	colorIndex = ( colorIndex + 1 ) % NUM_QIX_COLORS;
	
	return self;
}

/**********************************************************************/

- oneStep
{
	if( tailLen )
		--tailLen;
	else
	{
		PSsetgray( 0.0 );
		[ self drawQix : tail width : ERASE_WIDTH ];
		[ self setQixPoint :  &tail.pointA ];
		[ self setQixPoint :  &tail.pointB ];
	}
	
	[ self setQixColor ];
	[ self drawQix : head width : DRAW_WIDTH ];
	[ self setQixPoint : &head.pointA ];
	[ self setQixPoint : &head.pointB ];
	
	return self;
}

/**********************************************************************/

- drawRect : ( NSRect ) r 
{	 
	PSsetgray( 0.0 );
	
	NSRectFill( r );
	
	return self;
	
}

/**********************************************************************/

@end
