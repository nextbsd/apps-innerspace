#include "HAL9000View.h"
#include <math.h>

#define HALRows 3
#define HALColumns 4
#define HALPanelGap 14.0

static NSColor *
HALColor(float red, float green, float blue, float alpha)
{
  return [NSColor colorWithCalibratedRed: red
				   green: green
				    blue: blue
				   alpha: alpha];
}

static void
HALFillRect(NSRect rect, NSColor *color)
{
  [color set];
  NSRectFill(rect);
}

@implementation HAL9000View

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if(self)
    {
      NSFont *titleFont = [NSFont boldSystemFontOfSize: 24.0];
      NSFont *labelFont = [NSFont userFixedPitchFontOfSize: 13.0];
      NSFont *smallFont = [NSFont userFixedPitchFontOfSize: 10.0];

      if(labelFont == nil)
	{
	  labelFont = [NSFont systemFontOfSize: 13.0];
	}
      if(smallFont == nil)
	{
	  smallFont = [NSFont systemFontOfSize: 10.0];
	}

      titleAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
					   titleFont, NSFontAttributeName,
					   HALColor(0.95, 0.95, 0.88, 1.0), NSForegroundColorAttributeName,
					   nil] retain];
      labelAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
					   labelFont, NSFontAttributeName,
					   HALColor(0.78, 0.91, 1.0, 1.0), NSForegroundColorAttributeName,
					   nil] retain];
      smallAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
					   smallFont, NSFontAttributeName,
					   HALColor(0.48, 0.65, 0.72, 1.0), NSForegroundColorAttributeName,
					   nil] retain];
      greenAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
					   labelFont, NSFontAttributeName,
					   HALColor(0.32, 1.0, 0.56, 1.0), NSForegroundColorAttributeName,
					   nil] retain];
      amberAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
					   labelFont, NSFontAttributeName,
					   HALColor(1.0, 0.72, 0.24, 1.0), NSForegroundColorAttributeName,
					   nil] retain];
      phase = 0.0;
      frameCount = 0;
      screenMode = 0;
    }
  return self;
}

- (void)dealloc
{
  [titleAttributes release];
  [labelAttributes release];
  [smallAttributes release];
  [greenAttributes release];
  [amberAttributes release];
  [super dealloc];
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
  return 0.05;
}

- (NSString *)windowTitle
{
  return @"HAL 9000";
}

- (void)drawRect:(NSRect)rect
{
  NSRect bounds = [self bounds];

  HALFillRect(rect, [NSColor blackColor]);
  [self drawDisplayInRect: bounds];
  [self drawScanLinesInRect: bounds];
}

- (void)oneStep
{
  phase += 0.06;
  frameCount++;
  if(frameCount % 160 == 0)
    {
      screenMode = (screenMode + 1) % 4;
    }
  [self setNeedsDisplay: YES];
}

- (void)drawDisplayInRect:(NSRect)rect
{
  NSRect content = NSInsetRect(rect, 22.0, 22.0);
  NSRect header = NSMakeRect(content.origin.x, NSMaxY(content) - 48.0,
			     content.size.width, 42.0);
  int row, column;
  NSString *title = @"HAL 9000";
  NSString *subtitle = @"DISCOVERY MISSION OPERATIONS";
  NSSize titleSize = [title sizeWithAttributes: titleAttributes];

  HALFillRect(content, HALColor(0.015, 0.018, 0.022, 1.0));
  [[HALColor(0.10, 0.18, 0.22, 1.0) colorWithAlphaComponent: 1.0] set];
  NSFrameRect(content);

  [title drawAtPoint: NSMakePoint(NSMidX(header) - titleSize.width / 2.0,
				  header.origin.y + 13.0)
      withAttributes: titleAttributes];
  [subtitle drawAtPoint: NSMakePoint(header.origin.x + 8.0, header.origin.y + 5.0)
	 withAttributes: smallAttributes];

  content.size.height -= 58.0;

  for(row = 0; row < HALRows; row++)
    {
      for(column = 0; column < HALColumns; column++)
	{
	  [self drawPanelAtRow: row column: column inRect: content];
	}
    }
}

- (void)drawPanelAtRow:(int)row column:(int)column inRect:(NSRect)rect
{
  float panelWidth = (rect.size.width - (HALPanelGap * (HALColumns - 1))) / HALColumns;
  float panelHeight = (rect.size.height - (HALPanelGap * (HALRows - 1))) / HALRows;
  float x = rect.origin.x + column * (panelWidth + HALPanelGap);
  float y = rect.origin.y + (HALRows - row - 1) * (panelHeight + HALPanelGap);
  NSRect panel = NSMakeRect(x, y, panelWidth, panelHeight);
  int selector = (row * HALColumns + column + screenMode) % 6;
  NSString *labels[] = {
    @"LOGIC MEMORY", @"AE-35 SIGNAL", @"CREW STATUS",
    @"POD BAY", @"JUPITER LINK", @"SYSTEM READOUT"
  };

  HALFillRect(panel, HALColor(0.025, 0.038, 0.046, 1.0));
  [[HALColor(0.10, 0.34, 0.42, 1.0) colorWithAlphaComponent: 1.0] set];
  NSFrameRect(panel);

  [labels[(row * HALColumns + column) % 6]
    drawAtPoint: NSMakePoint(panel.origin.x + 8.0, NSMaxY(panel) - 22.0)
    withAttributes: smallAttributes];

  panel = NSInsetRect(panel, 10.0, 28.0);

  if(row == 1 && column == 1)
    {
      [self drawHalEyeInRect: panel];
    }
  else if(selector == 0 || selector == 3)
    {
      [self drawStatusMatrixInRect: panel];
    }
  else
    {
      [self drawSignalTraceInRect: panel];
    }
}

- (void)drawHalEyeInRect:(NSRect)rect
{
  float diameter = MIN(rect.size.width, rect.size.height) * 0.86;
  NSRect eyeRect = NSMakeRect(NSMidX(rect) - diameter / 2.0,
			      NSMidY(rect) - diameter / 2.0,
			      diameter, diameter);
  NSBezierPath *outer = [NSBezierPath bezierPathWithOvalInRect: eyeRect];
  NSBezierPath *inner;
  NSBezierPath *pupil;
  float pulse = (sin(phase * 2.0) + 1.0) / 2.0;

  [HALColor(0.09, 0.00, 0.00, 1.0) set];
  [outer fill];
  [[NSColor darkGrayColor] set];
  [outer setLineWidth: 4.0];
  [outer stroke];

  inner = [NSBezierPath bezierPathWithOvalInRect: NSInsetRect(eyeRect, diameter * 0.18, diameter * 0.18)];
  [HALColor(0.88 + 0.12 * pulse, 0.03, 0.01, 1.0) set];
  [inner fill];

  pupil = [NSBezierPath bezierPathWithOvalInRect: NSInsetRect(eyeRect, diameter * 0.36, diameter * 0.36)];
  [HALColor(0.10, 0.0, 0.0, 1.0) set];
  [pupil fill];

  [HALColor(1.0, 0.76, 0.56, 0.75) set];
  NSRectFill(NSMakeRect(NSMidX(eyeRect) - 2.0, NSMidY(eyeRect), 4.0, diameter * 0.28));
  NSRectFill(NSMakeRect(NSMidX(eyeRect) - diameter * 0.14, NSMidY(eyeRect) - 2.0,
			diameter * 0.28, 4.0));
}

- (void)drawStatusMatrixInRect:(NSRect)rect
{
  int rows = 6;
  int columns = 7;
  int row, column;
  float cellWidth = rect.size.width / columns;
  float cellHeight = rect.size.height / rows;

  for(row = 0; row < rows; row++)
    {
      for(column = 0; column < columns; column++)
	{
	  float value = sin(phase + row * 0.71 + column * 0.43);
	  NSRect cell = NSInsetRect(NSMakeRect(rect.origin.x + column * cellWidth,
					       rect.origin.y + row * cellHeight,
					       cellWidth, cellHeight), 2.0, 2.0);
	  if(value > 0.58)
	    {
	      HALFillRect(cell, HALColor(0.95, 0.42, 0.10, 1.0));
	    }
	  else if(value > -0.20)
	    {
	      HALFillRect(cell, HALColor(0.06, 0.70, 0.26, 1.0));
	    }
	  else
	    {
	      HALFillRect(cell, HALColor(0.03, 0.13, 0.16, 1.0));
	    }
	}
    }

  [@"NOMINAL" drawAtPoint: NSMakePoint(rect.origin.x + 4.0, rect.origin.y + 4.0)
	   withAttributes: greenAttributes];
}

- (void)drawSignalTraceInRect:(NSRect)rect
{
  NSBezierPath *trace = [NSBezierPath bezierPath];
  int samples = 48;
  int index;
  float baseline = NSMidY(rect);
  NSString *readout;

  HALFillRect(rect, HALColor(0.01, 0.02, 0.025, 1.0));
  [[HALColor(0.05, 0.20, 0.25, 1.0) colorWithAlphaComponent: 1.0] set];
  NSFrameRect(rect);

  for(index = 0; index < samples; index++)
    {
      float t = (float)index / (float)(samples - 1);
      float x = rect.origin.x + t * rect.size.width;
      float y = baseline + sin(phase * 1.5 + t * 18.0) * rect.size.height * 0.25
		      + sin(phase * 3.0 + t * 7.0) * rect.size.height * 0.08;
      if(index == 0)
	{
	  [trace moveToPoint: NSMakePoint(x, y)];
	}
      else
	{
	  [trace lineToPoint: NSMakePoint(x, y)];
	}
    }

  [HALColor(0.33, 0.92, 1.0, 1.0) set];
  [trace setLineWidth: 2.0];
  [trace stroke];

  readout = (screenMode % 2 == 0) ? @"COMPUTER ACTIVE" : @"LIFE FUNCTIONS";
  [readout drawAtPoint: NSMakePoint(rect.origin.x + 5.0, NSMaxY(rect) - 18.0)
	withAttributes: amberAttributes];
}

- (void)drawScanLinesInRect:(NSRect)rect
{
  float y;
  float shimmer = (sin(phase * 4.0) + 1.0) * 0.015;
  NSColor *lineColor = HALColor(0.0, 0.0, 0.0, 0.16 + shimmer);

  [lineColor set];
  for(y = rect.origin.y; y < NSMaxY(rect); y += 4.0)
    {
      NSRectFill(NSMakeRect(rect.origin.x, y, rect.size.width, 1.0));
    }
}

@end

@implementation StaticHAL9000View
- (void)drawRect:(NSRect)rect
{
  NSRectClip(rect);
  [super drawRect: rect];
}
@end
