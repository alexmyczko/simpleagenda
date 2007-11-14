#import <AppKit/AppKit.h>
#import "MemoryStore.h"
#import "Event.h"
#import "Task.h"
#import "defines.h"

@implementation MemoryStore

- (NSDictionary *)defaults
{
  return nil;
}

- (id)initWithName:(NSString *)name
{
  NSString *filename;

  self = [super init];
  if (self) {
    _name = [name copy];
    _config = [[ConfigManager alloc] initForKey:name withParent:nil];
    [_config registerDefaults:[self defaults]];
    filename = [_config objectForKey:ST_FILE];
    _modified = NO;
    _data = [[NSMutableDictionary alloc] initWithCapacity:128];
    _tasks = [[NSMutableDictionary alloc] initWithCapacity:16];
    _writable = [[_config objectForKey:ST_RW] boolValue];
    _displayed = [[_config objectForKey:ST_DISPLAY] boolValue];
  }
  return self;
}

+ (id)storeNamed:(NSString *)name
{
  return AUTORELEASE([[self allocWithZone: NSDefaultMallocZone()] initWithName:name]);
}

+ (BOOL)registerWithName:(NSString *)name
{
  return NO;
}
+ (NSString *)storeTypeName
{
  return nil;
}

- (void)dealloc
{
  [_data release];
  [_tasks release];
  [_name release];
  [_config release];
  [super dealloc];
}

- (NSEnumerator *)enumerator
{
  return [_data objectEnumerator];
}

- (NSArray *)events
{
  return [_data allValues];
}
- (NSArray *)tasks
{
  return [_tasks allValues];
}

-(void)addEvent:(Event *)evt
{
  [evt setStore:self];
  [_data setValue:evt forKey:[evt UID]];
  _modified = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:SADataChangedInStore object:self];
}
-(void)addTask:(Task *)task
{
  [task setStore:self];
  [_tasks setValue:task forKey:[task UID]];
  _modified = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:SADataChangedInStore object:self];
}

-(void)remove:(Element *)elt
{
  if ([elt isKindOfClass:[Event class]])
    [_data removeObjectForKey:[elt UID]];
  else
    [_tasks removeObjectForKey:[elt UID]];
  _modified = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:SADataChangedInStore object:self];
}

- (void)update:(Element *)elt;
{
  [elt setStore:self];
  if ([elt isKindOfClass:[Event class]]) {
    [_data removeObjectForKey:[elt UID]];
    [_data setValue:elt forKey:[elt UID]];
  } else {
    [_tasks removeObjectForKey:[elt UID]];
    [_tasks setValue:elt forKey:[elt UID]];
  }  
  _modified = YES;
  [[NSNotificationCenter defaultCenter] postNotificationName:SADataChangedInStore object:self];
}

- (BOOL)contains:(Element *)elt
{
  if ([elt isKindOfClass:[Event class]])
    return [_data objectForKey:[elt UID]] != nil;
  return [_tasks objectForKey:[elt UID]] != nil;
}

-(BOOL)isWritable
{
  return _writable;
}

- (void)setIsWritable:(BOOL)writable
{
  _writable = writable;
  [_config setObject:[NSNumber numberWithBool:_writable] forKey:ST_RW];
}

- (BOOL)modified
{
  return _modified;
}

- (NSString *)description
{
  return _name;
}

- (NSColor *)eventColor
{
  NSData *theData =[_config objectForKey:ST_COLOR];
  return [NSUnarchiver unarchiveObjectWithData:theData];
}

- (void)setEventColor:(NSColor *)color
{
  NSData *data = [NSArchiver archivedDataWithRootObject:color];
  [_config setObject:data forKey:ST_COLOR];
}

- (NSColor *)textColor
{
  NSData *theData =[_config objectForKey:ST_TEXT_COLOR];
  return [NSUnarchiver unarchiveObjectWithData:theData];
}

- (void)setTextColor:(NSColor *)color
{
  NSData *data = [NSArchiver archivedDataWithRootObject:color];
  [_config setObject:data forKey:ST_TEXT_COLOR];
}

- (BOOL)displayed
{
  return _displayed;
}

- (void)setDisplayed:(BOOL)state
{
  _displayed = state;
  [_config setObject:[NSNumber numberWithBool:_displayed] forKey:ST_DISPLAY];
}

@end