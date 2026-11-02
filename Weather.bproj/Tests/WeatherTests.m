#import "../WeatherView.h"
#include <string.h>

@interface WeatherView (Testing)

- (void)weatherRequestFinished:(NSDictionary *)result;
- (NSDictionary *)fetchWeather:(NSURLRequest *)request;
- (void)refreshWeather;
- (void)startRequest:(NSString *)url;

@end

@interface TestWeatherView : WeatherView
{
  NSString *requestedURL;
  NSUInteger synchronousDisplays;
}

- (BOOL)loadJSON:(NSString *)json;
- (NSDictionary *)conditions;
- (BOOL)hasError;
- (BOOL)rejectsInvalidLocation;
- (BOOL)checkProvider;
- (BOOL)checkCoordinateReturn;

@end

@implementation TestWeatherView

- (void)dealloc
{
  RELEASE(requestedURL);
  DEALLOC;
}

- (void)display
{
  synchronousDisplays++;
  [super display];
}

- (void)startRequest:(NSString *)url
{
  ASSIGN(requestedURL, url);
}

- (BOOL)checkProvider
{
  [self refreshWeather];
  return [requestedURL hasPrefix: @"https://api.open-meteo.com/v1/forecast?"] &&
    [requestedURL rangeOfString: @"current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"].location != NSNotFound &&
    [requestedURL rangeOfString: @"temperature_unit=celsius&wind_speed_unit=kmh"].location != NSNotFound;
}

- (BOOL)loadJSON:(NSString *)json
{
  ASSIGN(responseData, [NSMutableData dataWithData: [json dataUsingEncoding: NSUTF8StringEncoding]]);
  [self weatherRequestFinished: [NSDictionary dictionaryWithObjectsAndKeys:
    responseData, @"data", [NSNumber numberWithUnsignedInteger: requestGeneration], @"generation", nil]];
  return conditions != nil;
}

- (NSDictionary *)conditions
{
  return conditions;
}

- (BOOL)hasError
{
  return status != nil;
}

- (BOOL)checkCoordinateReturn
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  id savedLat = RETAIN([defaults objectForKey: @"WeatherLatitude"]);
  id savedLon = RETAIN([defaults objectForKey: @"WeatherLongitude"]);
  NSWindow *window = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 220, 202)
    styleMask: NSTitledWindowMask backing: NSBackingStoreBuffered defer: NO];
  NSTextView *editor;
  BOOL valid = YES;
  unsigned int i;
  [window setReleasedWhenClosed: NO];
  [window setContentView: [self inspector: nil]];
  [window makeKeyAndOrderFront: nil];
  [longitudeField setStringValue: @"-74.0060"];
  for (i = 0; i < 3; i++)
    {
      NSTextField *field = i == 1 ? longitudeField : latitudeField;
      [field selectText: nil];
      editor = (NSTextView *)[field currentEditor];
      if (editor == nil) { valid = NO; break; }
      [editor setString: i == 0 ? @"39.0993" : (i == 1 ? @"-76.8483" : @"invalid")];
      {
        NSUInteger previousDisplays = synchronousDisplays;
        [self oneStep];
        if (synchronousDisplays != previousDisplays) valid = NO;
      }
      [editor doCommandBySelector: @selector(insertNewline:)];
      if (latitude != 39.0993 || (i > 0 && longitude != -76.8483)) valid = NO;
      if ([window firstResponder] != editor) valid = NO;
    }
  if (savedLat) [defaults setObject: savedLat forKey: @"WeatherLatitude"];
  else [defaults removeObjectForKey: @"WeatherLatitude"];
  if (savedLon) [defaults setObject: savedLon forKey: @"WeatherLongitude"];
  else [defaults removeObjectForKey: @"WeatherLongitude"];
  RELEASE(savedLat);
  RELEASE(savedLon);
  [window close];
  RELEASE(window);
  return valid;
}

- (BOOL)rejectsInvalidLocation
{
  double oldLatitude = latitude;
  double oldLongitude = longitude;
  [self inspector: nil];
  [latitudeField setStringValue: @"91"];
  [longitudeField setStringValue: @"0"];
  [self applyLocation: nil];
  if (latitude != oldLatitude || longitude != oldLongitude) return NO;
  [latitudeField setStringValue: @"abc"];
  [self applyLocation: nil];
  return latitude == oldLatitude && longitude == oldLongitude;
}

@end

@interface SlowWeatherView : WeatherView

- (BOOL)checkResponsiveness;

@end

@implementation SlowWeatherView

- (NSDictionary *)fetchWeather:(NSURLRequest *)request
{
  /* Simulate slow DNS/network work without relying on the public service. */
  if ([NSThread isMainThread])
    return [NSDictionary dictionaryWithObject: @"Network ran on UI thread" forKey: @"error"];
  [NSThread sleepForTimeInterval: 0.2];
  return [NSDictionary dictionaryWithObject: @"Simulated offline response" forKey: @"error"];
}

- (BOOL)checkResponsiveness
{
  NSDate *start = [NSDate date];
  NSDate *deadline;
  [self startRequest: @"https://example.invalid/first"];
  [self startRequest: @"https://example.invalid/second"];
  if (-[start timeIntervalSinceNow] > 0.15) return NO;
  /* Old completions must not clear the new request's pending flag/status. */
  [self weatherRequestFinished: [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithUnsignedInteger: requestGeneration - 1], @"generation",
    @"Old location error", @"error", nil]];
  if (!requestPending || ![status isEqual: @"Updating weather..."]) return NO;
  deadline = [NSDate dateWithTimeIntervalSinceNow: 3];
  while (requestPending && [deadline timeIntervalSinceNow] > 0)
    [[NSRunLoop currentRunLoop] runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
  return !requestPending && [status isEqual: @"Simulated offline response"];
}

@end

static void Check(BOOL condition, NSString *message)
{
  if (!condition)
    {
      NSLog(@"FAIL: %@", message);
      exit(1);
    }
}

int main(int argc, const char **argv)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  TestWeatherView *view;
  SlowWeatherView *slowView;
  NSBitmapImageRep *bitmap;
  NSWindow *window;
  BOOL headless = argc > 1 && strcmp(argv[1], "--headless") == 0;
  if (!headless) [NSApplication sharedApplication];
  view = [[TestWeatherView alloc] initWithFrame: NSMakeRect(0, 0, 800, 520)];
  Check(![view loadJSON: @"{}"] && [view hasError], @"Missing data must not become current weather");
  Check(![view loadJSON: @"{\"current\":{\"temperature_2m\":null}}"], @"Null values must be rejected");
  Check([view loadJSON: @"{\"current\":{\"temperature_2m\":12.5,\"relative_humidity_2m\":70,\"weather_code\":3,\"wind_speed_10m\":8.2,\"time\":\"2026-11-01T12:00\"}}"], @"Valid response accepted");
  Check(![view hasError], @"Successful refresh clears errors");
  Check([[ [view conditions] objectForKey: @"temperature_2m"] doubleValue] == 12.5, @"Temperature preserved");
  Check([view loadJSON: @"not JSON"] && [view hasError], @"Failed update keeps previous conditions and reports error");
  if (!headless) Check([view rejectsInvalidLocation], @"Invalid settings preserve the current location");
  if (!headless) Check([view checkCoordinateReturn], @"Return commits either coordinate without leaving the field editor; invalid input preserves location");
  Check([view checkProvider], @"Refresh requests all current measurements directly from Open-Meteo with explicit units");
  Check([view loadJSON: @"{\"current\":{\"temperature_2m\":12.5,\"relative_humidity_2m\":70,\"weather_code\":3,\"wind_speed_10m\":8.2,\"time\":\"2026-11-01T12:00\"}}"], @"Recovery from failed update");
  Check(![view hasError] && [[[view conditions] objectForKey: @"source"] hasPrefix: @"Open-Meteo"], @"Recovery clears error and identifies provider");
  slowView = [[SlowWeatherView alloc] initWithFrame: NSMakeRect(0, 0, 800, 520)];
  Check([slowView checkResponsiveness], @"Slow network stays off UI thread and old location responses are ignored");
  RELEASE(slowView);
  if (headless)
    {
      RELEASE(view);
      NSLog(@"Weather data tests passed (GUI checks not run)");
      RELEASE(pool);
      return 0;
    }
  window = [[NSWindow alloc] initWithContentRect: [view bounds]
    styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO];
  [window setReleasedWhenClosed: NO];
  [window setContentView: view];
  [window orderFront: nil];
  [view display];
  bitmap = [view bitmapImageRepForCachingDisplayInRect: [view bounds]];
  [view cacheDisplayInRect: [view bounds] toBitmapImageRep: bitmap];
  Check(bitmap != nil, @"Map and conditions render");
  Check([[bitmap representationUsingType: NSPNGFileType properties: [NSDictionary dictionary]]
    writeToFile: @"/tmp/innerspace-weather-test.png" atomically: YES], @"Render sample written");
  [window close];
  RELEASE(window);
  RELEASE(view);
  NSLog(@"Weather tests passed");
  RELEASE(pool);
  return 0;
}
