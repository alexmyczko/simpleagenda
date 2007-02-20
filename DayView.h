/* emacs buffer mode hint -*- objc -*- */

#import <AppKit/AppKit.h>

@protocol DayViewDataSource
- (int)firstHourForDayView;
- (int)lastHourForDayView;
- (NSEnumerator *)scheduledAppointmentsForDayView;
@end

@class AppointmentView;

@interface DayView : NSView
{
  id <DayViewDataSource> _dataSource;
  IBOutlet id delegate;
  int _height;
  int _width;
  int _firstH;
  int _lastH;
  NSPoint _startPt;
  NSPoint _endPt;
  NSDictionary *_textAttributes;
  AppointmentView *_selected;
}

- (id)initWithFrame:(NSRect)frameRect;
- (void)drawRect:(NSRect)rect;
- (void)reloadData;
- (Appointment *)selectedAppointment;

@end

@interface NSObject (DayViewDelegate)

- (void)doubleClickOnAppointment:(Appointment *)apt;
- (void)modifyAppointment:(Appointment *)apt;

@end
