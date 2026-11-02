#import "WeatherView.h"
#include <math.h>

/* A deliberately simplified geographic overview, in longitude/latitude. */
static const double NorthAmerica[][2] = {
  {-168,72},{-140,70},{-125,60},{-105,72},{-80,72},{-55,52},
  {-65,45},{-80,25},{-87,21},{-82,9},{-98,16},{-115,30},
  {-125,49},{-150,60},{-168,60}
};
static const double SouthAmerica[][2] = {
  {-81,12},{-65,10},{-50,0},{-35,-7},{-42,-23},{-55,-35},
  {-68,-55},{-75,-45},{-80,-10}
};
static const double Eurasia[][2] = {
  {-10,36},{-10,44},{5,48},{-5,59},{20,71},{45,68},{70,75},
  {110,73},{140,60},{178,65},{170,50},{140,45},{130,30},
  {120,20},{108,5},{100,15},{80,7},{70,25},{50,12},
  {35,30},{28,40},{15,37}
};
static const double Africa[][2] = {
  {-17,35},{10,37},{32,31},{43,12},{51,12},{40,-12},
  {30,-35},{18,-35},{10,-5},{-15,5}
};
static const double Australia[][2] = {
  {113,-22},{130,-12},{142,-11},{154,-28},{146,-39},{130,-32},{115,-35}
};
static const double Greenland[][2] = {
  {-52,60},{-42,62},{-20,80},{-45,84},{-62,76}
};

static NSPoint MapPoint(NSRect map, double lon, double lat)
{
  return NSMakePoint(map.origin.x + (lon + 180.0) * map.size.width / 360.0,
                     map.origin.y + (lat + 90.0) * map.size.height / 180.0);
}

static void DrawLand(NSRect map, const double points[][2], unsigned int count)
{
  NSBezierPath *path = [NSBezierPath bezierPath];
  unsigned int i;
  [path moveToPoint: MapPoint(map, points[0][0], points[0][1])];
  for (i = 1; i < count; i++)
    [path lineToPoint: MapPoint(map, points[i][0], points[i][1])];
  [path closePath];
  [[NSColor colorWithCalibratedRed: 0.16 green: 0.36 blue: 0.40 alpha: 1] set];
  [path fill];
  [[NSColor colorWithCalibratedRed: 0.28 green: 0.55 blue: 0.57 alpha: 1] set];
  [path stroke];
}

static NSString *WeatherDescription(int code)
{
  if (code == 0) return @"Clear sky";
  if (code == 1) return @"Mainly clear";
  if (code == 2) return @"Partly cloudy";
  if (code == 3) return @"Overcast";
  if (code == 45 || code == 48) return @"Fog";
  if (code >= 51 && code <= 57) return @"Drizzle";
  if (code >= 61 && code <= 67) return @"Rain";
  if (code >= 71 && code <= 77) return @"Snow";
  if (code >= 80 && code <= 82) return @"Rain showers";
  if (code == 85 || code == 86) return @"Snow showers";
  if (code >= 95 && code <= 99) return @"Thunderstorm";
  return @"Unknown conditions";
}

static NSString *Measurement(id value, NSString *unit)
{
  if (![value isKindOfClass: [NSNumber class]]) return @"Unavailable";
  return [NSString stringWithFormat: @"%.1f%@", [value doubleValue], unit];
}

static void DrawText(NSString *text, NSRect rect, CGFloat size, NSColor *color)
{
  NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSFont systemFontOfSize: size], NSFontAttributeName,
    color, NSForegroundColorAttributeName, nil];
  [text drawInRect: rect withAttributes: attributes];
}

@implementation WeatherView

- (id)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame: frame];
  if (self)
    {
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      weatherQueue = [[NSOperationQueue alloc] init];
      [weatherQueue setMaxConcurrentOperationCount: 1];
      useFahrenheit = [defaults boolForKey: @"WeatherUseFahrenheit"];
      latitude = 40.7128;
      longitude = -74.0060;
      if ([defaults objectForKey: @"WeatherLatitude"] != nil &&
          [defaults objectForKey: @"WeatherLongitude"] != nil)
        {
          double lat = [defaults doubleForKey: @"WeatherLatitude"];
          double lon = [defaults doubleForKey: @"WeatherLongitude"];
          if (isfinite(lat) && isfinite(lon) && fabs(lat) <= 90 && fabs(lon) <= 180)
            { latitude = lat; longitude = lon; }
        }
      ASSIGN(status, @"Waiting to retrieve weather...");
    }
  return self;
}

- (void)dealloc
{
  [weatherQueue cancelAllOperations];
  RELEASE(weatherQueue);
  RELEASE(responseData);
  RELEASE(conditions);
  RELEASE(status);
  RELEASE(nextRefresh);
  RELEASE(receivedAt);
  RELEASE(inspectorView);
  DEALLOC;
}

- (void)finishRequestWithError:(NSString *)message
{
  requestPending = NO;
  DESTROY(responseData);
  ASSIGN(status, message);
  ASSIGN(nextRefresh, [NSDate dateWithTimeIntervalSinceNow: message ? 300 : 900]);
  [self setNeedsDisplay: YES];
}

/* This method is called only on the worker queue. GNUstep may resolve DNS
 * synchronously while constructing even an asynchronous NSURLConnection. */
- (NSDictionary *)fetchWeather:(NSURLRequest *)request
{
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData *data = [NSURLConnection sendSynchronousRequest: request
    returningResponse: &response error: &error];
  if (error != nil)
    return [NSDictionary dictionaryWithObject: [NSString stringWithFormat:
      @"Open-Meteo: %@. Retrying in 5 minutes.", [error localizedDescription]] forKey: @"error"];
  if (![response isKindOfClass: [NSHTTPURLResponse class]] ||
      [(NSHTTPURLResponse *)response statusCode] != 200)
    return [NSDictionary dictionaryWithObject: [NSString stringWithFormat:
      @"Open-Meteo HTTP %ld. Retrying in 5 minutes.",
      (long)([response isKindOfClass: [NSHTTPURLResponse class]] ?
        [(NSHTTPURLResponse *)response statusCode] : 0)] forKey: @"error"];
  if (data == nil || [data length] > 262144)
    return [NSDictionary dictionaryWithObject:
      @"Invalid weather response. Retrying in 5 minutes." forKey: @"error"];
  return [NSDictionary dictionaryWithObject: data forKey: @"data"];
}

- (void)performWeatherRequest:(NSDictionary *)job
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSMutableDictionary *result;
  @try
    {
      result = [NSMutableDictionary dictionaryWithDictionary:
        [self fetchWeather: [job objectForKey: @"request"]]];
    }
  @catch (NSException *exception)
    {
      result = [NSMutableDictionary dictionaryWithObject:
        @"Weather request failed. Retrying in 5 minutes." forKey: @"error"];
    }
  [result setObject: [job objectForKey: @"generation"] forKey: @"generation"];
  [self performSelectorOnMainThread: @selector(weatherRequestFinished:)
    withObject: result waitUntilDone: NO];
  RELEASE(pool);
}

- (void)startRequest:(NSString *)urlString
{
  NSMutableURLRequest *request;
  NSInvocationOperation *operation;
  NSDictionary *job;
  [weatherQueue cancelAllOperations];
  requestGeneration++;
  requestPending = YES;
  request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: urlString]
    cachePolicy: NSURLRequestReloadIgnoringLocalCacheData timeoutInterval: 20];
  [request setValue: @"InnerSpace-Weather/1.0" forHTTPHeaderField: @"User-Agent"];
  [request setValue: @"application/json" forHTTPHeaderField: @"Accept"];
  ASSIGN(status, @"Updating weather...");
  job = [NSDictionary dictionaryWithObjectsAndKeys: request, @"request",
    [NSNumber numberWithUnsignedInteger: requestGeneration], @"generation", nil];
  operation = [[NSInvocationOperation alloc] initWithTarget: self
    selector: @selector(performWeatherRequest:) object: job];
  [weatherQueue addOperation: operation];
  RELEASE(operation);
}

- (void)startGlobalWeather
{
  [self startRequest: [NSString stringWithFormat:
    @"https://api.open-meteo.com/v1/forecast?latitude=%.6f&longitude=%.6f&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&timezone=GMT&temperature_unit=celsius&wind_speed_unit=kmh",
    latitude, longitude]];
}

- (void)refreshWeather
{
  if (requestPending) return;
  [self startGlobalWeather];
}

- (void)weatherRequestFinished:(NSDictionary *)result
{
  id json;
  id current;
  NSArray *keys;
  unsigned int i;
  BOOL valid;
  /* A request for a previous location can finish after Apply and Refresh. */
  if ([[result objectForKey: @"generation"] unsignedIntegerValue] != requestGeneration) return;
  if ([result objectForKey: @"error"] != nil)
    {
      [self finishRequestWithError: [result objectForKey: @"error"]];
      return;
    }
  ASSIGN(responseData, [result objectForKey: @"data"]);
  json = [NSJSONSerialization JSONObjectWithData: responseData options: 0 error: NULL];
  current = [json isKindOfClass: [NSDictionary class]] ? [json objectForKey: @"current"] : nil;
  valid = [current isKindOfClass: [NSDictionary class]];
  keys = [NSArray arrayWithObjects: @"temperature_2m", @"relative_humidity_2m",
                  @"weather_code", @"wind_speed_10m", nil];
  for (i = 0; valid && i < [keys count]; i++)
    {
      id value = [current objectForKey: [keys objectAtIndex: i]];
      valid = [value isKindOfClass: [NSNumber class]] && isfinite([value doubleValue]);
    }
  if (valid)
    valid = [[current objectForKey: @"time"] isKindOfClass: [NSString class]];
  if (!valid)
    {
      [self finishRequestWithError: @"Invalid weather response. Retrying in 5 minutes."];
      return;
    }
  current = AUTORELEASE([current mutableCopy]);
  [current setObject: WeatherDescription([[current objectForKey: @"weather_code"] intValue]) forKey: @"description"];
  [current setObject: @"Open-Meteo (CC BY 4.0)" forKey: @"source"];
  [current setObject: [[current objectForKey: @"time"] stringByAppendingString: @"Z"] forKey: @"time"];
  ASSIGN(conditions, current);
  ASSIGN(receivedAt, [NSDate date]);
  [self finishRequestWithError: nil];
}

- (void)oneStep
{
  if (nextRefresh == nil || [nextRefresh timeIntervalSinceNow] <= 0)
    [self refreshWeather];
#if defined(__APPLE__) && !defined(GNUSTEP)
  [self drawRect: [self bounds]];
#else
  /* The host already holds focus during oneStep. Let AppKit redraw after
   * that focus is released, rather than nesting display/text layout inside
   * the animation callback while an inspector field editor is active. */
  [self setNeedsDisplay: YES];
#endif
}

- (NSTimeInterval)animationDelayTime
{
  return 1.0;
}

- (void)drawRect:(NSRect)dirty
{
  NSRect bounds = [self bounds];
  CGFloat scale = MIN(bounds.size.width / 800.0, bounds.size.height / 520.0);
  NSAffineTransform *transform = [NSAffineTransform transform];
  NSRect map = NSMakeRect(30, 66, 740, 300);
  NSColor *white = [NSColor whiteColor];
  NSColor *muted = [NSColor colorWithCalibratedWhite: 0.72 alpha: 1];
  NSPoint marker;
  NSBezierPath *grid = [NSBezierPath bezierPath];
  int degrees;
  [[NSColor colorWithCalibratedRed: 0.035 green: 0.07 blue: 0.12 alpha: 1] set];
  NSRectFill(bounds);
  if (scale <= 0) return;
  [NSGraphicsContext saveGraphicsState];
  [transform translateXBy: NSMidX(bounds) - 400 * scale yBy: NSMidY(bounds) - 260 * scale];
  [transform scaleBy: scale];
  [transform concat];
  DrawText(@"WEATHER", NSMakeRect(30, 477, 740, 28), 20, muted);
  DrawText([NSString stringWithFormat: @"Location  %.4f, %.4f", latitude, longitude],
           NSMakeRect(30, 445, 740, 28), 20, white);
  if (conditions != nil)
    {
      DrawText([NSString stringWithFormat: @"%@  ·  %@",
        [self temperatureString],
        [conditions objectForKey: @"description"]],
        NSMakeRect(30, 403, 740, 40), 30, white);
      DrawText([NSString stringWithFormat: @"Humidity %@    Wind %@    %@%@",
        Measurement([conditions objectForKey: @"relative_humidity_2m"], @"%"),
        Measurement([conditions objectForKey: @"wind_speed_10m"], @" km/h"),
        [conditions objectForKey: @"time"],
        (status != nil || -[receivedAt timeIntervalSinceNow] > 1800) ? @"  (last received)" : @""],
        NSMakeRect(30, 375, 740, 25), 15, muted);
    }
  else
    DrawText(@"Current conditions unavailable", NSMakeRect(30, 403, 740, 40), 28, white);
  [[NSColor colorWithCalibratedRed: 0.06 green: 0.15 blue: 0.23 alpha: 1] set];
  NSRectFill(map);
  for (degrees = -180; degrees <= 180; degrees += 30)
    {
      [grid moveToPoint: MapPoint(map, degrees, -90)];
      [grid lineToPoint: MapPoint(map, degrees, 90)];
    }
  for (degrees = -90; degrees <= 90; degrees += 30)
    {
      [grid moveToPoint: MapPoint(map, -180, degrees)];
      [grid lineToPoint: MapPoint(map, 180, degrees)];
    }
  [[NSColor colorWithCalibratedWhite: 0.3 alpha: 0.5] set];
  [grid setLineWidth: 0.5];
  [grid stroke];
#define LAND(name) DrawLand(map, name, sizeof(name) / sizeof(name[0]))
  LAND(NorthAmerica); LAND(SouthAmerica); LAND(Eurasia);
  LAND(Africa); LAND(Australia); LAND(Greenland);
#undef LAND
  marker = MapPoint(map, longitude, latitude);
  [[NSColor colorWithCalibratedRed: 1 green: 0.77 blue: 0.25 alpha: 1] set];
  [[NSBezierPath bezierPathWithOvalInRect: NSMakeRect(marker.x - 5, marker.y - 5, 10, 10)] fill];
  [[NSBezierPath bezierPathWithOvalInRect: NSMakeRect(marker.x - 10, marker.y - 10, 20, 20)] stroke];
  DrawText(status != nil ? status : @"Weather received successfully · Updates every 15 minutes",
           NSMakeRect(30, 36, 740, 23), 15, white);
  DrawText([NSString stringWithFormat: @"Weather: %@ · Simplified world map · Coordinates in Settings",
           conditions ? [conditions objectForKey: @"source"] : @"Open-Meteo (CC BY 4.0)"],
           NSMakeRect(30, 10, 740, 22), 13, muted);
  [NSGraphicsContext restoreGraphicsState];
}

- (NSString *)temperatureString
{
  id value = [conditions objectForKey: @"temperature_2m"];
  if (![value isKindOfClass: [NSNumber class]]) return @"Unavailable";
  /* Keep downloaded values in Celsius so changing units needs no request. */
  return Measurement([NSNumber numberWithDouble: useFahrenheit ?
    [value doubleValue] * 9.0 / 5.0 + 32.0 : [value doubleValue]],
    useFahrenheit ? @" °F" : @" °C");
}

- (void)setTemperatureUnit:(id)sender
{
  useFahrenheit = [sender state] == NSOnState;
  [[NSUserDefaults standardUserDefaults] setBool: useFahrenheit forKey: @"WeatherUseFahrenheit"];
  [self setNeedsDisplay: YES];
}

- (NSView *)inspector:(id)sender
{
  if (inspectorView == nil)
    {
      unsigned int i;
      NSButton *button;
      NSButton *unitButton;
      inspectorView = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 220, 202)];
      for (i = 0; i < 2; i++)
        {
          NSTextField *label = AUTORELEASE([[NSTextField alloc]
            initWithFrame: NSMakeRect(10, 174 - i * 53, 200, 20)]);
          NSTextField *field = AUTORELEASE([[NSTextField alloc]
            initWithFrame: NSMakeRect(10, 149 - i * 53, 200, 24)]);
          [label setStringValue: i == 0 ? @"Latitude (-90 to 90)" : @"Longitude (-180 to 180)"];
          [label setEditable: NO];
          [label setSelectable: NO];
          [label setBordered: NO];
          [label setDrawsBackground: NO];
          [field setDelegate: self];
          [field setTarget: self];
          [field setAction: @selector(applyLocation:)];
          [[field cell] setSendsActionOnEndEditing: NO];
          [field setStringValue: [NSString stringWithFormat: @"%.4f", i == 0 ? latitude : longitude]];
          [inspectorView addSubview: label];
          [inspectorView addSubview: field];
          if (i == 0) latitudeField = field; else longitudeField = field;
        }
      unitButton = AUTORELEASE([[NSButton alloc] initWithFrame: NSMakeRect(10, 69, 200, 22)]);
      [unitButton setButtonType: NSSwitchButton];
      [unitButton setTitle: @"Use Fahrenheit (°F)"];
      [unitButton setState: useFahrenheit ? NSOnState : NSOffState];
      [unitButton setTarget: self];
      [unitButton setAction: @selector(setTemperatureUnit:)];
      [inspectorView addSubview: unitButton];
      button = AUTORELEASE([[NSButton alloc] initWithFrame: NSMakeRect(10, 36, 200, 28)]);
      [button setTitle: @"Apply and Refresh"];
      [button setTarget: self];
      [button setAction: @selector(applyLocation:)];
      [inspectorView addSubview: button];
      settingsStatus = AUTORELEASE([[NSTextField alloc] initWithFrame: NSMakeRect(10, 0, 200, 34)]);
      [settingsStatus setFont: [NSFont systemFontOfSize: 11]];
      [settingsStatus setEditable: NO];
      [settingsStatus setSelectable: NO];
      [settingsStatus setBordered: NO];
      [settingsStatus setDrawsBackground: NO];
      [settingsStatus setStringValue: @"Default: New York. Enter coordinates for your location."];
      [inspectorView addSubview: settingsStatus];
    }
  return inspectorView;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView
  doCommandBySelector:(SEL)command
{
  if ((control == latitudeField || control == longitudeField) &&
      ([NSStringFromSelector(command) isEqualToString: @"insertNewline:"] ||
       [NSStringFromSelector(command) isEqualToString: @"insertNewlineIgnoringFieldEditor:"]))
    {
      /* Consume Return in the field editor, before AppKit tears down and
       * reselects the field or forwards it to a window default action. */
      [control validateEditing];
      [self applyLocation: control];
      return YES;
    }
  return NO;
}

- (void)applyLocation:(id)sender
{
  NSScanner *latScanner = [NSScanner scannerWithString: [latitudeField stringValue]];
  NSScanner *lonScanner = [NSScanner scannerWithString: [longitudeField stringValue]];
  double lat, lon;
  [latScanner setLocale: [NSDictionary dictionaryWithObject: @"." forKey: NSDecimalSeparator]];
  [lonScanner setLocale: [NSDictionary dictionaryWithObject: @"." forKey: NSDecimalSeparator]];
  if (![latScanner scanDouble: &lat] || ![latScanner isAtEnd] ||
      ![lonScanner scanDouble: &lon] || ![lonScanner isAtEnd] ||
      !isfinite(lat) || !isfinite(lon) || fabs(lat) > 90 || fabs(lon) > 180)
    {
      [settingsStatus setStringValue: @"Enter valid coordinates using a decimal point."];
      return;
    }
  [weatherQueue cancelAllOperations];
  requestGeneration++;
  requestPending = NO;
  DESTROY(responseData);
  DESTROY(conditions);
  DESTROY(receivedAt);
  latitude = lat;
  longitude = lon;
  [[NSUserDefaults standardUserDefaults] setDouble: lat forKey: @"WeatherLatitude"];
  [[NSUserDefaults standardUserDefaults] setDouble: lon forKey: @"WeatherLongitude"];
  [settingsStatus setStringValue: @"Location saved."];
  [self refreshWeather];
  [self setNeedsDisplay: YES];
}

@end
