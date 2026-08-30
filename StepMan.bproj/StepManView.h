#include <AppKit/AppKit.h>

#define StepManRows 15
#define StepManColumns 21
#define StepManMaxEnemies 4

typedef struct stepman_actor
{
  int row;
  int column;
  int nextRow;
  int nextColumn;
  float progress;
  int direction;
} StepManActor;

@interface StepManView : NSView
{
  BOOL dots[StepManRows][StepManColumns];
  StepManActor stepMan;
  StepManActor enemies[StepManMaxEnemies];
  NSImage *stepManIcon;
  int score;
  int mouthPhase;
  float animationPhase;
}
- (void)oneStep;
- (void)resetGame;
- (void)resetDots;
- (BOOL)isWallAtRow:(int)row column:(int)column;
- (BOOL)hasDotAtRow:(int)row column:(int)column;
- (NSRect)boardRect;
- (float)cellSize;
- (NSPoint)pointForActor:(StepManActor *)actor;
- (void)chooseNextMoveForActor:(StepManActor *)actor chasing:(BOOL)chasing;
- (void)advanceActor:(StepManActor *)actor speed:(float)speed chasing:(BOOL)chasing;
- (void)drawBoard;
- (void)drawDots;
- (void)drawStepMan;
- (void)drawEnemy:(StepManActor *)actor index:(int)index;
- (void)drawScore;
@end

@interface StaticStepManView : StepManView
{
}
@end
