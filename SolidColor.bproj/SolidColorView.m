/*
 * SolidColorView: the desktop in one colour (nextbsd/nextbsd#708).
 *
 * One colour for each appearance (NBAppearance, Dark or Light, from
 * Workspace Preferences): NeXT slate in Dark and Gershwin's grey in Light
 * unless chosen otherwise in Options, where every colour is offered for
 * both. The appearance changes at once: Workspace's change notice redraws
 * it. Nothing animates, so it costs nothing while it shows.
 */

#include "SolidColorView.h"

static NSString *const SCDarkKey = @"SolidColorDark";
static NSString *const SCLightKey = @"SolidColorLight";

/* The colours, by name, as the design proposed them (any in either
   appearance). */
static const struct { const char *name; unsigned rgb; } SCColors[] = {
  { "NeXT slate", 0x2b3440 },
  { "Midnight blue", 0x14233a },
  { "Deep teal", 0x0c2f38 },
  { "Plum", 0x2a1734 },
  { "Forest", 0x13291f },
  { "Black", 0x000000 },
  { "Gershwin grey", 0x5f6770 },
  { "Steel", 0x7a8591 },
  { "Soft blue", 0x6f8aa6 },
  { "Sand", 0xa59c8c },
};
#define SC_COUNT (sizeof(SCColors) / sizeof(SCColors[0]))

static NSUInteger
SCIndex(NSString *name, NSUInteger fallback)
{
  NSUInteger i;

  for (i = 0; i < SC_COUNT; i++)
    if ([name isEqual: [NSString stringWithUTF8String: SCColors[i].name]])
      return i;
  return fallback;
}

/* Dark unless the appearance in effect is Light: the person's choice,
   else the theme's default. */
static BOOL
SCIsLight(void)
{
  id value = [[NSUserDefaults standardUserDefaults] objectForKey: @"NBAppearance"];

  if (![value isKindOfClass: [NSString class]])
    value = [[[NSClassFromString(@"GSTheme") performSelector: @selector(theme)]
               infoDictionary] objectForKey: @"NBAppearance"];
  return [value isEqual: @"light"];
}

@implementation SolidColorView

- (id)initWithFrame:(NSRect)frame
{
  if ((self = [super initWithFrame: frame]) != nil)
    [[NSDistributedNotificationCenter defaultCenter]
      addObserver: self
         selector: @selector(desktopSettingsChanged:)
             name: @"org.nextbsd.DesktopSettingsChanged"
           object: nil];
  return self;
}

- (void)dealloc
{
  [[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
  RELEASE(inspectorView);
  RELEASE(darkPopUp);
  RELEASE(lightPopUp);
  [super dealloc];
}

- (BOOL)useBufferedWindow
{
  return NO;
}

- (BOOL)isBoringScreenSaver
{
  return NO;
}

- (BOOL)isOpaque
{
  return YES;
}

/* Nothing moves: a long delay keeps the host's timer quiet. */
- (NSTimeInterval)animationDelayTime
{
  return 5.0;
}

- (NSString *)windowTitle
{
  return @"Solid Color";
}

- (NSColor *)currentColor
{
  BOOL light = SCIsLight();
  NSUInteger i = SCIndex([[NSUserDefaults standardUserDefaults]
                           stringForKey: light ? SCLightKey : SCDarkKey],
                         light ? 6 : 0);
  unsigned rgb = SCColors[i].rgb;

  return [NSColor colorWithCalibratedRed: ((rgb >> 16) & 255) / 255.0
                                   green: ((rgb >> 8) & 255) / 255.0
                                    blue: (rgb & 255) / 255.0
                                   alpha: 1.0];
}

- (void)drawRect:(NSRect)rect
{
  [[self currentColor] set];
  NSRectFill(rect);
}

- (void)oneStep
{
}

/* Dark or Light changed in Workspace Preferences. */
- (void)desktopSettingsChanged:(NSNotification *)note
{
  if (![[[note userInfo] objectForKey: @"key"] isEqual: @"NBAppearance"])
    return;
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self setNeedsDisplay: YES];
}

/* Options: a colour for each appearance, every colour offered for both. */
- (NSPopUpButton *)popUpAt:(CGFloat)y label:(NSString *)label key:(NSString *)key
                  fallback:(NSUInteger)fallback
{
  NSTextField *text = AUTORELEASE([[NSTextField alloc]
                        initWithFrame: NSMakeRect(20, y + 3, 70, 20)]);
  NSPopUpButton *popUp = [[NSPopUpButton alloc]
                           initWithFrame: NSMakeRect(96, y, 200, 26) pullsDown: NO];
  NSUInteger i;

  [text setStringValue: label];
  [text setEditable: NO];
  [text setSelectable: NO];
  [text setBordered: NO];
  [text setBezeled: NO];
  [text setDrawsBackground: NO];
  [text setAlignment: NSRightTextAlignment];
  [inspectorView addSubview: text];
  for (i = 0; i < SC_COUNT; i++)
    [popUp addItemWithTitle: [NSString stringWithUTF8String: SCColors[i].name]];
  [popUp selectItemAtIndex: SCIndex([[NSUserDefaults standardUserDefaults]
                                      stringForKey: key], fallback)];
  [popUp setTarget: self];
  [popUp setAction: @selector(chooseColor:)];
  [inspectorView addSubview: popUp];
  return popUp;
}

- (NSView *)inspector:(id)sender
{
  if (inspectorView == nil)
    {
      /* As tall as the Options panel's box, the controls at its top:
         a shorter view sits at the bottom of the box. */
      inspectorView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 380, 250)];
      darkPopUp = [self popUpAt: 214 label: @"In Dark:" key: SCDarkKey fallback: 0];
      lightPopUp = [self popUpAt: 180 label: @"In Light:" key: SCLightKey fallback: 6];
    }
  return inspectorView;
}

- (void)chooseColor:(id)sender
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  [defaults setObject: [sender titleOfSelectedItem]
               forKey: sender == lightPopUp ? SCLightKey : SCDarkKey];
  [defaults synchronize];
  [self setNeedsDisplay: YES];
}

@end
