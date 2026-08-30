#include "StepManView.h"
#include <math.h>
#include <stdlib.h>
#include <time.h>

#define RAND_FLOAT ((float)rand() / (float)RAND_MAX)
#define StepManTwoPi 6.2831853

static const char *StepManMaze[StepManRows] = {
  "#####################",
  "#.........#.........#",
  "#.###.###.#.###.###.#",
  "#o#.....#...#.....#o#",
  "#.###.#.#####.#.###.#",
  "#.....#...#...#.....#",
  "#####.### # ###.#####",
  "    #.#       #.#    ",
  "#####.# ## ## #.#####",
  "#.........#.........#",
  "#.###.###.#.###.###.#",
  "#o..#..... .....#..o#",
  "###.#.#.#####.#.#.###",
  "#.....#...#...#.....#",
  "#####################"
};

enum
{
  StepManDirectionRight = 0,
  StepManDirectionUp = 1,
  StepManDirectionLeft = 2,
  StepManDirectionDown = 3
};

@implementation StepManView

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if(self)
    {
      NSString *path;

      srand((unsigned int)time(NULL));
      path = [[NSBundle bundleForClass: [self class]] pathForResource: @"GNUstep"
							  ofType: @"tiff"];
      stepManIcon = [[NSImage alloc] initWithContentsOfFile: path];
      [self resetGame];
    }
  return self;
}

- (void)dealloc
{
  RELEASE(stepManIcon);
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
  return 0.035;
}

- (NSString *)windowTitle
{
  return @"StepMan";
}

- (void)drawRect:(NSRect)rects
{
  [[NSColor blackColor] set];
  NSRectFill(rects);
  [self drawBoard];
  [self drawDots];
  [self drawStepMan];
  [self drawScore];
}

- (void)oneStep
{
  int i;
  BOOL dotsRemain = NO;

  [[NSColor blackColor] set];
  NSRectFill([self bounds]);

  animationPhase += 0.09;
  mouthPhase++;
  [self advanceActor: &stepMan speed: 0.17 chasing: NO];
  if([self hasDotAtRow: stepMan.row column: stepMan.column])
    {
      dots[stepMan.row][stepMan.column] = NO;
      score++;
    }

  for(i = 0; i < StepManMaxEnemies; i++)
    {
      [self advanceActor: &enemies[i] speed: 0.11 + (i * 0.01) chasing: YES];
      if(enemies[i].row == stepMan.row && enemies[i].column == stepMan.column)
	{
	  [self resetGame];
	  break;
	}
    }

  for(i = 0; i < StepManRows * StepManColumns; i++)
    {
      if(dots[i / StepManColumns][i % StepManColumns])
	{
	  dotsRemain = YES;
	  break;
	}
    }
  if(!dotsRemain)
    {
      [self resetDots];
    }

  [self drawBoard];
  [self drawDots];
  for(i = 0; i < StepManMaxEnemies; i++)
    {
      [self drawEnemy: &enemies[i] index: i];
    }
  [self drawStepMan];
  [self drawScore];
}

- (void)resetGame
{
  int i;
  static int enemyRows[StepManMaxEnemies] = { 7, 7, 9, 5 };
  static int enemyColumns[StepManMaxEnemies] = { 9, 11, 10, 10 };

  [self resetDots];
  score = 0;
  mouthPhase = 0;
  stepMan.row = 1;
  stepMan.column = 1;
  stepMan.nextRow = 1;
  stepMan.nextColumn = 2;
  stepMan.progress = 0.0;
  stepMan.direction = StepManDirectionRight;

  for(i = 0; i < StepManMaxEnemies; i++)
    {
      enemies[i].row = enemyRows[i];
      enemies[i].column = enemyColumns[i];
      enemies[i].nextRow = enemies[i].row;
      enemies[i].nextColumn = enemies[i].column;
      enemies[i].progress = 1.0;
      enemies[i].direction = i % 4;
      [self chooseNextMoveForActor: &enemies[i] chasing: YES];
    }
}

- (void)resetDots
{
  int row;
  int column;

  for(row = 0; row < StepManRows; row++)
    {
      for(column = 0; column < StepManColumns; column++)
	{
	  dots[row][column] = (StepManMaze[row][column] == '.' ||
			      StepManMaze[row][column] == 'o');
	}
    }
}

- (BOOL)isWallAtRow:(int)row column:(int)column
{
  if(row < 0 || row >= StepManRows)
    {
      return YES;
    }
  if(column < 0 || column >= StepManColumns)
    {
      return YES;
    }
  return StepManMaze[row][column] == '#';
}

- (BOOL)hasDotAtRow:(int)row column:(int)column
{
  if(row < 0 || row >= StepManRows || column < 0 || column >= StepManColumns)
    {
      return NO;
    }
  return dots[row][column];
}

- (float)cellSize
{
  NSRect bounds = [self bounds];
  float cellWidth = bounds.size.width / StepManColumns;
  float cellHeight = (bounds.size.height - 34.0) / StepManRows;

  if(cellHeight < 6.0)
    {
      cellHeight = bounds.size.height / StepManRows;
    }
  return cellWidth < cellHeight ? cellWidth : cellHeight;
}

- (NSRect)boardRect
{
  NSRect bounds = [self bounds];
  float cell = [self cellSize];
  float width = cell * StepManColumns;
  float height = cell * StepManRows;

  return NSMakeRect(NSMidX(bounds) - (width * 0.5),
		    NSMidY(bounds) - (height * 0.5) - 8.0,
		    width,
		    height);
}

- (NSPoint)pointForActor:(StepManActor *)actor
{
  NSRect board = [self boardRect];
  float cell = [self cellSize];
  float row = actor->row + ((actor->nextRow - actor->row) * actor->progress);
  float column = actor->column + ((actor->nextColumn - actor->column) * actor->progress);

  return NSMakePoint(board.origin.x + (column + 0.5) * cell,
		     board.origin.y + ((StepManRows - 1 - row) + 0.5) * cell);
}

- (void)chooseNextMoveForActor:(StepManActor *)actor chasing:(BOOL)chasing
{
  static int rowDelta[4] = { 0, -1, 0, 1 };
  static int columnDelta[4] = { 1, 0, -1, 0 };
  int possible[4];
  int possibleCount = 0;
  int bestDirection = actor->direction;
  int direction;
  float bestScore = chasing ? 1000000.0 : -1.0;

  for(direction = 0; direction < 4; direction++)
    {
      int row = actor->row + rowDelta[direction];
      int column = actor->column + columnDelta[direction];

      if(![self isWallAtRow: row column: column] &&
	 direction != ((actor->direction + 2) % 4))
	{
	  possible[possibleCount++] = direction;
	}
    }
  if(possibleCount == 0)
    {
      possible[possibleCount++] = (actor->direction + 2) % 4;
    }

  for(direction = 0; direction < possibleCount; direction++)
    {
      int candidate = possible[direction];
      int row = actor->row + rowDelta[candidate];
      int column = actor->column + columnDelta[candidate];
      float candidateScore;

      if(chasing)
	{
	  float dr = (float)(row - stepMan.row);
	  float dc = (float)(column - stepMan.column);

	  candidateScore = (dr * dr) + (dc * dc) + (RAND_FLOAT * 2.0);
	  if(candidateScore < bestScore)
	    {
	      bestScore = candidateScore;
	      bestDirection = candidate;
	    }
	}
      else
	{
	  candidateScore = [self hasDotAtRow: row column: column] ? 4.0 : RAND_FLOAT;
	  if(candidate == actor->direction)
	    {
	      candidateScore += 1.1;
	    }
	  if(candidateScore > bestScore)
	    {
	      bestScore = candidateScore;
	      bestDirection = candidate;
	    }
	}
    }

  actor->direction = bestDirection;
  actor->nextRow = actor->row + rowDelta[bestDirection];
  actor->nextColumn = actor->column + columnDelta[bestDirection];
}

- (void)advanceActor:(StepManActor *)actor speed:(float)speed chasing:(BOOL)chasing
{
  actor->progress += speed;
  while(actor->progress >= 1.0)
    {
      actor->row = actor->nextRow;
      actor->column = actor->nextColumn;
      actor->progress -= 1.0;
      [self chooseNextMoveForActor: actor chasing: chasing];
    }
}

- (void)drawBoard
{
  NSRect board = [self boardRect];
  float cell = [self cellSize];
  int row;
  int column;

  [[NSColor colorWithCalibratedWhite: 0.02 alpha: 1.0] set];
  NSRectFill(board);

  [[NSColor colorWithCalibratedRed: 0.10 green: 0.27 blue: 0.72 alpha: 1.0] set];
  for(row = 0; row < StepManRows; row++)
    {
      for(column = 0; column < StepManColumns; column++)
	{
	  if([self isWallAtRow: row column: column])
	    {
	      NSRect wallRect = NSMakeRect(board.origin.x + column * cell,
					   board.origin.y + (StepManRows - 1 - row) * cell,
					   cell,
					   cell);
	      NSBezierPath *wall = [NSBezierPath bezierPathWithRoundedRect:
				    NSInsetRect(wallRect, cell * 0.08, cell * 0.08)
							       xRadius: cell * 0.20
							       yRadius: cell * 0.20];
	      [wall fill];
	    }
	}
    }
}

- (void)drawDots
{
  NSRect board = [self boardRect];
  float cell = [self cellSize];
  int row;
  int column;

  [[NSColor colorWithCalibratedRed: 1.0 green: 0.86 blue: 0.58 alpha: 1.0] set];
  for(row = 0; row < StepManRows; row++)
    {
      for(column = 0; column < StepManColumns; column++)
	{
	  if(dots[row][column])
	    {
	      float diameter = StepManMaze[row][column] == 'o' ? cell * 0.26 : cell * 0.12;
	      NSPoint center = NSMakePoint(board.origin.x + (column + 0.5) * cell,
					   board.origin.y + ((StepManRows - 1 - row) + 0.5) * cell);
	      NSRect dotRect = NSMakeRect(center.x - diameter * 0.5,
					  center.y - diameter * 0.5,
					  diameter,
					  diameter);

	      [[NSBezierPath bezierPathWithOvalInRect: dotRect] fill];
	    }
	}
    }
}

- (void)drawStepMan
{
  NSPoint center = [self pointForActor: &stepMan];
  float cell = [self cellSize];
  float diameter = cell * 0.86;
  float angle = stepMan.direction * 90.0;
  float bite = 18.0 + (fabs(sinf(mouthPhase * 0.28)) * 30.0);
  NSRect imageRect = NSMakeRect(center.x - diameter * 0.5,
				center.y - diameter * 0.5,
				diameter,
				diameter);
  NSBezierPath *clip = [NSBezierPath bezierPathWithOvalInRect: imageRect];
  NSBezierPath *mouth = [NSBezierPath bezierPath];

  [NSGraphicsContext saveGraphicsState];
  [clip addClip];
  if(stepManIcon != nil)
    {
      [stepManIcon drawInRect: imageRect
		     fromRect: NSZeroRect
		    operation: NSCompositeSourceOver
		     fraction: 1.0];
    }
  else
    {
      [[NSColor colorWithCalibratedRed: 0.94 green: 0.79 blue: 0.16 alpha: 1.0] set];
      [clip fill];
    }

  [mouth moveToPoint: center];
  [mouth appendBezierPathWithArcWithCenter: center
				    radius: diameter
				startAngle: angle - bite
				  endAngle: angle + bite];
  [mouth closePath];
  [[NSColor blackColor] set];
  [mouth fill];
  [NSGraphicsContext restoreGraphicsState];

  [[NSColor colorWithCalibratedWhite: 1.0 alpha: 0.40] set];
  [clip setLineWidth: 1.5];
  [clip stroke];
}

- (void)drawEnemy:(StepManActor *)actor index:(int)index
{
  NSPoint center = [self pointForActor: actor];
  float cell = [self cellSize];
  float radius = cell * 0.36;
  float wave = sinf(animationPhase * 6.0 + index);
  NSBezierPath *body = [NSBezierPath bezierPath];
  NSColor *colors[StepManMaxEnemies];

  colors[0] = [NSColor colorWithCalibratedRed: 0.96 green: 0.22 blue: 0.18 alpha: 1.0];
  colors[1] = [NSColor colorWithCalibratedRed: 0.21 green: 0.82 blue: 0.95 alpha: 1.0];
  colors[2] = [NSColor colorWithCalibratedRed: 0.98 green: 0.52 blue: 0.78 alpha: 1.0];
  colors[3] = [NSColor colorWithCalibratedRed: 0.98 green: 0.61 blue: 0.20 alpha: 1.0];

  [body appendBezierPathWithArcWithCenter: NSMakePoint(center.x, center.y)
				   radius: radius
			       startAngle: 0.0
				 endAngle: 180.0];
  [body lineToPoint: NSMakePoint(center.x - radius, center.y - radius)];
  [body lineToPoint: NSMakePoint(center.x - radius * 0.45,
				 center.y - radius * (0.72 + wave * 0.10))];
  [body lineToPoint: NSMakePoint(center.x,
				 center.y - radius)];
  [body lineToPoint: NSMakePoint(center.x + radius * 0.45,
				 center.y - radius * (0.72 - wave * 0.10))];
  [body lineToPoint: NSMakePoint(center.x + radius, center.y - radius)];
  [body closePath];

  [colors[index] set];
  [body fill];

  [[NSColor whiteColor] set];
  [[NSBezierPath bezierPathWithOvalInRect:
    NSMakeRect(center.x - radius * 0.58, center.y + radius * 0.05,
	       radius * 0.36, radius * 0.42)] fill];
  [[NSBezierPath bezierPathWithOvalInRect:
    NSMakeRect(center.x + radius * 0.22, center.y + radius * 0.05,
	       radius * 0.36, radius * 0.42)] fill];

  [[NSColor blackColor] set];
  [[NSBezierPath bezierPathWithOvalInRect:
    NSMakeRect(center.x - radius * 0.45, center.y + radius * 0.16,
	       radius * 0.13, radius * 0.16)] fill];
  [[NSBezierPath bezierPathWithOvalInRect:
    NSMakeRect(center.x + radius * 0.35, center.y + radius * 0.16,
	       radius * 0.13, radius * 0.16)] fill];
}

- (void)drawScore
{
  NSDictionary *attributes;
  NSString *text;
  NSFont *font = [NSFont boldSystemFontOfSize: 18.0];

  attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			       font, NSFontAttributeName,
			       [NSColor colorWithCalibratedWhite: 0.86 alpha: 1.0],
			       NSForegroundColorAttributeName,
			       nil];
  text = [NSString stringWithFormat: @"StepMan  %d", score];
  [text drawAtPoint: NSMakePoint(NSMinX([self boardRect]), NSMaxY([self boardRect]) + 7.0)
     withAttributes: attributes];
}

@end

@implementation StaticStepManView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect: rects];
}
@end
