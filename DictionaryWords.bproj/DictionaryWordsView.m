#include "DictionaryWordsView.h"
#include <stdlib.h>
#include <time.h>

#define DictionaryWordsDisplaySeconds 8.0

@implementation DictionaryWordsView

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  if(self)
    {
      entries = nil;
      wordAttributes = nil;
      definitionAttributes = nil;
      pronunciationAttributes = nil;
      labelAttributes = nil;
      currentWord = nil;
      currentPronunciation = nil;
      currentDefinition = nil;
      lastChangeDate = nil;
      displayDuration = DictionaryWordsDisplaySeconds;

      srand((unsigned int)time(NULL));
      [self buildEntries];
      [self buildTextAttributes];
      [self chooseNextEntry];
    }
  return self;
}

- (void)dealloc
{
  RELEASE(entries);
  RELEASE(wordAttributes);
  RELEASE(definitionAttributes);
  RELEASE(pronunciationAttributes);
  RELEASE(labelAttributes);
  RELEASE(currentWord);
  RELEASE(currentPronunciation);
  RELEASE(currentDefinition);
  RELEASE(lastChangeDate);
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
  return 0.08;
}

- (NSString *)windowTitle
{
  return @"Dictionary Words";
}

- (void)buildEntries
{
  NSArray *newEntries;

  newEntries = [NSArray arrayWithObjects:
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"AUREATE", @"word", @"OR-ee-it", @"pronunciation",
      @"Brilliant, golden, or richly ornamented in style.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"BRIO", @"word", @"BREE-oh", @"pronunciation",
      @"Energy, confidence, and spirited liveliness.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"CLARION", @"word", @"KLAIR-ee-un", @"pronunciation",
      @"Loud, clear, and ringing; impossible to ignore.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"DULCET", @"word", @"DUL-sit", @"pronunciation",
      @"Pleasantly soft, sweet, and soothing to hear.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"EFFERVESCENT", @"word", @"ef-er-VES-ent", @"pronunciation",
      @"Lively, sparkling, and full of cheerful energy.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"FUGACIOUS", @"word", @"fyoo-GAY-shus", @"pronunciation",
      @"Lasting only a short time; fleeting.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"HALCYON", @"word", @"HAL-see-un", @"pronunciation",
      @"Calm, peaceful, and prosperous.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"INCANDESCENT", @"word", @"in-kan-DES-ent", @"pronunciation",
      @"Glowing with heat, light, or intense emotion.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"JUBILANT", @"word", @"JOO-bi-lunt", @"pronunciation",
      @"Feeling or expressing great joy.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"LIMINAL", @"word", @"LIM-in-ul", @"pronunciation",
      @"Occupying a threshold or transitional state.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"MELLIFLUOUS", @"word", @"meh-LIF-loo-us", @"pronunciation",
      @"Smooth, flowing, and sweet-sounding.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"NOCTILUCENT", @"word", @"nok-ti-LOO-sent", @"pronunciation",
      @"Shining or visible at night.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"OPALESCENT", @"word", @"oh-puh-LES-ent", @"pronunciation",
      @"Showing shifting colors like an opal.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"PANACHE", @"word", @"puh-NASH", @"pronunciation",
      @"Flamboyant confidence and distinctive style.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"QUOTIDIAN", @"word", @"kwoh-TID-ee-un", @"pronunciation",
      @"Ordinary, everyday, or recurring daily.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"RESPLENDENT", @"word", @"ri-SPLEN-dent", @"pronunciation",
      @"Attractively bright, colorful, and impressive.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"SERENDIPITY", @"word", @"seh-ren-DIP-i-tee", @"pronunciation",
      @"The gift of finding good things by chance.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"TENACIOUS", @"word", @"teh-NAY-shus", @"pronunciation",
      @"Persistent and unwilling to give up.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"UMBRAGE", @"word", @"UM-brij", @"pronunciation",
      @"Offense, resentment, or a feeling of being slighted.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"VERDANT", @"word", @"VUR-dunt", @"pronunciation",
      @"Green with growing plants; fresh and flourishing.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"WINSOME", @"word", @"WIN-sum", @"pronunciation",
      @"Charming in a fresh, open, or innocent way.", @"definition", nil],
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"ZEPHYR", @"word", @"ZEF-er", @"pronunciation",
      @"A soft, gentle breeze.", @"definition", nil],
    nil];

  ASSIGN(entries, newEntries);
}

- (NSFont *)fontNamed:(NSString *)name size:(float)size fallback:(NSFont *)fallback
{
  NSFont *font = [NSFont fontWithName: name size: size];
  return font ? font : fallback;
}

- (void)buildTextAttributes
{
  NSMutableParagraphStyle *centerStyle = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);
  NSMutableParagraphStyle *definitionStyle = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);
  NSFont *wordFont;
  NSFont *definitionFont;
  NSFont *pronunciationFont;
  NSDictionary *newWordAttributes;
  NSDictionary *newDefinitionAttributes;
  NSDictionary *newPronunciationAttributes;
  NSDictionary *newLabelAttributes;

  [centerStyle setAlignment: NSCenterTextAlignment];
  [definitionStyle setAlignment: NSCenterTextAlignment];
  [definitionStyle setLineSpacing: 4.0];

  wordFont = [self fontNamed: @"Palatino-Bold" size: 76.0
		    fallback: [NSFont boldSystemFontOfSize: 76.0]];
  definitionFont = [self fontNamed: @"Palatino-Roman" size: 30.0
			  fallback: [NSFont systemFontOfSize: 30.0]];
  pronunciationFont = [self fontNamed: @"Helvetica-Oblique" size: 21.0
			     fallback: [NSFont systemFontOfSize: 21.0]];

  newWordAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
    wordFont, NSFontAttributeName,
    [NSColor colorWithCalibratedRed: 0.98 green: 0.93 blue: 0.76 alpha: 1.0], NSForegroundColorAttributeName,
    centerStyle, NSParagraphStyleAttributeName,
    nil];
  newDefinitionAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
    definitionFont, NSFontAttributeName,
    [NSColor colorWithCalibratedRed: 0.92 green: 0.96 blue: 0.98 alpha: 1.0], NSForegroundColorAttributeName,
    definitionStyle, NSParagraphStyleAttributeName,
    nil];
  newPronunciationAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
    pronunciationFont, NSFontAttributeName,
    [NSColor colorWithCalibratedRed: 0.67 green: 0.84 blue: 0.92 alpha: 1.0], NSForegroundColorAttributeName,
    centerStyle, NSParagraphStyleAttributeName,
    nil];
  newLabelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont boldSystemFontOfSize: 13.0], NSFontAttributeName,
    [NSColor colorWithCalibratedRed: 0.50 green: 0.67 blue: 0.72 alpha: 1.0], NSForegroundColorAttributeName,
    centerStyle, NSParagraphStyleAttributeName,
    nil];

  ASSIGN(wordAttributes, newWordAttributes);
  ASSIGN(definitionAttributes, newDefinitionAttributes);
  ASSIGN(pronunciationAttributes, newPronunciationAttributes);
  ASSIGN(labelAttributes, newLabelAttributes);
}

- (void)chooseNextEntry
{
  NSDictionary *entry;
  unsigned int count = [entries count];
  unsigned int index;

  if(count == 0)
    {
      return;
    }

  index = (unsigned int)(rand() % count);
  entry = [entries objectAtIndex: index];

  ASSIGN(currentWord, [entry objectForKey: @"word"]);
  ASSIGN(currentPronunciation, [entry objectForKey: @"pronunciation"]);
  ASSIGN(currentDefinition, [entry objectForKey: @"definition"]);
  ASSIGN(lastChangeDate, [NSDate date]);
}

- (float)fadeAmount
{
  NSTimeInterval age;
  float fade;

  if(lastChangeDate == nil)
    {
      return 1.0;
    }

  age = [[NSDate date] timeIntervalSinceDate: lastChangeDate];
  if(age < 1.0)
    {
      fade = age;
    }
  else if(age > displayDuration - 1.0)
    {
      fade = displayDuration - age;
    }
  else
    {
      fade = 1.0;
    }

  if(fade < 0.0)
    {
      fade = 0.0;
    }
  if(fade > 1.0)
    {
      fade = 1.0;
    }
  return fade;
}

- (void)drawBackgroundInRect:(NSRect)bounds
{
  int band;
  int bandCount = 48;

  for(band = 0; band < bandCount; band++)
    {
      float t = (float)band / (float)(bandCount - 1);
      float r = 0.02 + (0.06 * t);
      float g = 0.04 + (0.11 * t);
      float b = 0.08 + (0.16 * t);
      NSRect bandRect = NSMakeRect(bounds.origin.x,
				   bounds.origin.y + (bounds.size.height * t),
				   bounds.size.width,
				   (bounds.size.height / (float)bandCount) + 1.0);

      [[NSColor colorWithCalibratedRed: r green: g blue: b alpha: 1.0] set];
      NSRectFill(bandRect);
    }

  [[NSColor colorWithCalibratedRed: 0.90 green: 0.72 blue: 0.28 alpha: 0.10] set];
  NSFrameRectWithWidth(NSInsetRect(bounds, 26.0, 26.0), 1.0);
  [[NSColor colorWithCalibratedRed: 0.44 green: 0.78 blue: 0.86 alpha: 0.10] set];
  NSFrameRectWithWidth(NSInsetRect(bounds, 34.0, 34.0), 1.0);
}

- (NSDictionary *)attributes:(NSDictionary *)attributes withAlpha:(float)alpha
{
  NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary: attributes];
  NSColor *color = [attributes objectForKey: NSForegroundColorAttributeName];

  if(color != nil)
    {
      NSColor *rgbColor = [color colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
      [newAttributes setObject:
	[NSColor colorWithCalibratedRed: [rgbColor redComponent]
				  green: [rgbColor greenComponent]
				   blue: [rgbColor blueComponent]
				  alpha: alpha]
		       forKey: NSForegroundColorAttributeName];
    }

  return newAttributes;
}

- (void)drawString:(NSString *)string
	    inRect:(NSRect)rect
    withAttributes:(NSDictionary *)attributes
	     alpha:(float)alpha
{
  NSDictionary *fadeAttributes = [self attributes: attributes withAlpha: alpha];
  NSMutableDictionary *shadowAttributes = [NSMutableDictionary dictionaryWithDictionary: fadeAttributes];
  NSRect shadowRect = NSOffsetRect(rect, 2.0, -2.0);

  [shadowAttributes setObject:
    [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.42 * alpha]
			forKey: NSForegroundColorAttributeName];
  [string drawInRect: shadowRect withAttributes: shadowAttributes];
  [string drawInRect: rect withAttributes: fadeAttributes];
}

- (void)drawCurrentEntryInRect:(NSRect)bounds
{
  float alpha = [self fadeAmount];
  float width = bounds.size.width * 0.72;
  float left;
  float centerY = NSMidY(bounds);
  NSRect labelRect;
  NSRect wordRect;
  NSRect pronunciationRect;
  NSRect definitionRect;

  if(width < 420.0)
    {
      width = bounds.size.width - 52.0;
    }
  if(width > 920.0)
    {
      width = 920.0;
    }
  left = NSMidX(bounds) - (width / 2.0);

  labelRect = NSMakeRect(left, centerY + 116.0, width, 24.0);
  wordRect = NSMakeRect(left, centerY + 34.0, width, 92.0);
  pronunciationRect = NSMakeRect(left, centerY + 4.0, width, 30.0);
  definitionRect = NSMakeRect(left, centerY - 94.0, width, 78.0);

  [self drawString: @"DICTIONARY WORD"
	    inRect: labelRect
    withAttributes: labelAttributes
	     alpha: alpha * 0.80];
  [self drawString: currentWord
	    inRect: wordRect
    withAttributes: wordAttributes
	     alpha: alpha];
  [self drawString: currentPronunciation
	    inRect: pronunciationRect
    withAttributes: pronunciationAttributes
	     alpha: alpha * 0.92];
  [self drawString: currentDefinition
	    inRect: definitionRect
    withAttributes: definitionAttributes
	     alpha: alpha];
}

- (void)drawRect:(NSRect)rects
{
  NSRect bounds = [self bounds];

  [self drawBackgroundInRect: bounds];
  [self drawCurrentEntryInRect: bounds];
}

- (void)oneStep
{
  if(lastChangeDate == nil ||
     [[NSDate date] timeIntervalSinceDate: lastChangeDate] >= displayDuration)
    {
      [self chooseNextEntry];
    }

  [self drawRect: [self bounds]];
}

@end

@implementation StaticDictionaryWordsView
- (void)drawRect:(NSRect)rects
{
  NSRectClip(rects);
  [super drawRect: rects];
}
@end
