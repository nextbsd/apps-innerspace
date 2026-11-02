#import <AppKit/AppKit.h>

@interface WeatherView : NSView <NSTextFieldDelegate>
{
  BOOL useFahrenheit;
  double latitude;
  double longitude;
  NSDictionary *conditions;
  NSString *status;
  NSDate *nextRefresh;
  NSDate *receivedAt;
  NSOperationQueue *weatherQueue;
  NSUInteger requestGeneration;
  BOOL requestPending;
  NSMutableData *responseData;
  NSView *inspectorView;
  NSTextField *latitudeField;
  NSTextField *longitudeField;
  NSTextField *settingsStatus;
}

- (void)oneStep;
- (NSView *)inspector:(id)sender;
- (void)applyLocation:(id)sender;
- (void)setTemperatureUnit:(id)sender;

@end
