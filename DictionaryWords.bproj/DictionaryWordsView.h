#include <AppKit/AppKit.h>

@interface DictionaryWordsView : NSView
{
  NSArray *entries;
  NSDictionary *wordAttributes;
  NSDictionary *definitionAttributes;
  NSDictionary *pronunciationAttributes;
  NSDictionary *labelAttributes;
  NSString *currentWord;
  NSString *currentPronunciation;
  NSString *currentDefinition;
  NSDate *lastChangeDate;
  NSTimeInterval displayDuration;
}
- (void)oneStep;
- (void)buildEntries;
- (void)buildTextAttributes;
- (void)chooseNextEntry;
- (float)fadeAmount;
- (void)drawBackgroundInRect:(NSRect)bounds;
- (void)drawCurrentEntryInRect:(NSRect)bounds;
@end

@interface StaticDictionaryWordsView : DictionaryWordsView
{
}
@end
