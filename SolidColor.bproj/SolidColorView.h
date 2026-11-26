/*
 * SolidColorView: the desktop in one colour, a colour for each appearance.
 */

#ifndef SOLID_COLOR_VIEW_H
#define SOLID_COLOR_VIEW_H

#include <AppKit/AppKit.h>

@interface SolidColorView : NSView
{
  NSView *inspectorView;
  NSPopUpButton *darkPopUp, *lightPopUp;
}
@end

#endif
