#import <Foundation/Foundation.h>
#import "Task.h"

@implementation Task(NSCoding)
- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeInt:_state forKey:@"state"];
  if (_completionDate != nil)
    [coder encodeObject:_completionDate forKey:@"completion"];
}
- (id)initWithCoder:(NSCoder *)coder
{
  [super initWithCoder:coder];
  _state = [coder decodeIntForKey:@"state"];
  if ([coder containsValueForKey:@"completion"])
    _completionDate = [[coder decodeObjectForKey:@"completion"] retain];
  else
    _completionDate = nil;
  return self;
}
@end

static NSArray *stateName;

@implementation Task
+ (void)initialize
{
  if (stateName == nil)
    stateName = [[NSArray alloc] initWithObjects:_(@"None"), _(@"Started"), _(@"Completed"), _(@"Canceled"), _(@"Needs action"), nil];
}

+ (NSArray *)stateNamesArray
{
  return stateName;
}

- (id)init
{
  self = [super init];
  if (self) {
    _state = TK_NONE;
    _completionDate = nil;
  }
  return self;
}
- (void)dealloc
{
  RELEASE(_completionDate);
  [super dealloc];
}
- (enum taskState)state
{
  return _state;
}
- (NSString *)stateAsString
{
  return [stateName objectAtIndex:_state];
}
- (void)setState:(enum taskState)state
{
  _state = state;
  if (state == TK_COMPLETED)
    [self setCompletionDate:[Date today]];
  else
    [self setCompletionDate:nil];
}
- (Date *)completionDate
{
  return _completionDate;
}
- (void)setCompletionDate:(Date *)cd
{
  if (_completionDate != nil)
    RELEASE(_completionDate);
  if (cd != nil)
    ASSIGNCOPY(_completionDate, cd);
  else
    _completionDate = nil;
}
- (Date *)nextActivationDate
{
  return _completionDate;
}
- (NSString *)description
{
  return [self summary];
}
@end

@implementation Task(iCalendar)
- (id)initWithICalComponent:(icalcomponent *)ic
{
  icalproperty *prop;

  self = [super initWithICalComponent:ic];
  if (self == nil)
    return nil;
  prop = icalcomponent_get_first_property(ic, ICAL_STATUS_PROPERTY);
  if (prop) {
    switch (icalproperty_get_status(prop))
      {
      case ICAL_STATUS_COMPLETED:
	[self setState:TK_COMPLETED];
	break;
      case ICAL_STATUS_CANCELLED:
	[self setState:TK_CANCELED];
	break;
      case ICAL_STATUS_INPROCESS:
	[self setState:TK_INPROCESS];
	break;
      case ICAL_STATUS_NEEDSACTION:
	[self setState:TK_NEEDSACTION];
	break;
      default:
	[self setState:TK_NONE];
      }
  }
  else
    [self setState:TK_NONE];
  return self;
}

static int statusCorr[] = {ICAL_STATUS_NONE, ICAL_STATUS_INPROCESS, ICAL_STATUS_COMPLETED, ICAL_STATUS_CANCELLED, ICAL_STATUS_NEEDSACTION};

- (BOOL)updateICalComponent:(icalcomponent *)ic
{
  if (![super updateICalComponent:ic])
    return NO;
  [self deleteProperty:ICAL_STATUS_PROPERTY fromComponent:ic];
  icalcomponent_add_property(ic, icalproperty_new_status(statusCorr[[self state]]));
  return YES;
}

- (int)iCalComponentType
{
  return ICAL_VTODO_COMPONENT;
}
@end
