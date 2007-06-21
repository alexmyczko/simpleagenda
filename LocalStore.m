#import <AppKit/AppKit.h>
#import "LocalStore.h"
#import "Event.h"
#import "UserDefaults.h"
#import "defines.h"

#define LocalAgendaPath @"~/GNUstep/Library/SimpleAgenda"

@implementation LocalStore

- (id)initWithName:(NSString *)name forManager:(id)manager
{
  NSString *filename;
  BOOL isDir;

  self = [super init];
  if (self) {
    _name = [name copy];
    _params = [NSMutableDictionary new];
    [_params addEntriesFromDictionary:[[UserDefaults sharedInstance] objectForKey:name]];

    if (![self eventColor])
      [self setEventColor:[NSColor yellowColor]];

    filename = [_params objectForKey:ST_FILE];
    _globalPath = [LocalAgendaPath stringByExpandingTildeInPath];
    _globalFile = [[NSString pathWithComponents:[NSArray arrayWithObjects:_globalPath, filename, nil]] retain];
    _modified = NO;
    _manager = manager;
    _set = [[NSMutableSet alloc] initWithCapacity:128];
    if ([_params objectForKey:ST_DISPLAY])
      _displayed = [[_params objectForKey:ST_DISPLAY] boolValue];
    else
      _displayed = YES;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:_globalPath]) {
      if (![fm createDirectoryAtPath:_globalPath attributes:nil])
	NSLog(@"Error creating dir %@", _globalPath);
      else
	NSLog(@"Created directory %@", _globalPath);
    }
    if ([fm fileExistsAtPath:_globalFile isDirectory:&isDir] && !isDir) {
      NSSet *savedData =  [NSKeyedUnarchiver unarchiveObjectWithFile:_globalFile];       
      if (savedData) {
	[savedData makeObjectsPerform:@selector(setStore:) withObject:self];
	[_set unionSet: savedData];
	NSLog(@"LocalStore from %@ : loaded %d appointment(s)", _globalFile, [_set count]);
      }
    }
  }
  return self;
}

+ (id)storeNamed:(NSString *)name forManager:(id)manager
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()] initWithName:name 
								  forManager:manager]);
}

- (void)dealloc
{
  [self write];
  [_set release];
  [_globalFile release];
  [_name release];
  [_params release];
  [super dealloc];
}

- (NSArray *)scheduledAppointmentsFor:(Date *)day
{
  NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:1];
  NSEnumerator *enumerator = [_set objectEnumerator];
  Event *apt;

  while ((apt = [enumerator nextObject])) {
    if ([apt isScheduledForDay:day])
      [array addObject:apt];
  }
  return array;
}

-(void)addAppointment:(Event *)app
{
  [_set addObject:app];
  [app setStore:self];
  _modified = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:SADataChangedInStore object:self];
}

-(void)delAppointment:(Event *)app
{
  [_set removeObject:app];
  _modified = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:SADataChangedInStore object:self];
}

-(void)updateAppointment:(Event *)app
{
  _modified = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:SADataChangedInStore object:self];
}

- (BOOL)contains:(Event *)evt
{
  if ([_set member:evt])
    return YES;
  return NO;
}

-(BOOL)isWritable
{
  return YES;
}

- (BOOL)modified
{
  return _modified;
}

- (void)write
{
  if (_modified) {
    [NSKeyedArchiver archiveRootObject:_set toFile:_globalFile];
    NSLog(@"LocalStore written to %@", _globalFile);
    _modified = NO;
  }
}

- (NSString *)description
{
  return _name;
}

- (NSColor *)eventColor
{
  NSColor *aColor = nil;
  NSData *theData =[_params objectForKey:ST_COLOR];

  if (theData)
    aColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
  return aColor;
}

- (void)setEventColor:(NSColor *)color
{
  NSData *data = [NSArchiver archivedDataWithRootObject:color];
  [_params setObject:data forKey:ST_COLOR];
  [[UserDefaults sharedInstance] setObject:_params forKey:_name];
}

- (BOOL)displayed
{
  return _displayed;
}

- (void)setDisplayed:(BOOL)state
{
  _displayed = state;
  [_params setValue:[NSNumber numberWithBool:_displayed] forKey:ST_DISPLAY];
  [[UserDefaults sharedInstance] setObject:_params forKey:_name];
}

- (void)defaultDidChanged:(NSString *)name
{
  [[NSNotificationCenter defaultCenter] postNotificationName:SADefaultsChangedforStore object:self];
}

@end
