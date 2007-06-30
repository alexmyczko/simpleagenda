/* emacs objective-c mode -*- objc -*- */

#import <AppKit/AppKit.h>

@interface CalendarView : NSBox
{
	Date *date;
	NSPopUpButton *button;
	NSStepper *stepper;
	NSTextField *text;
	NSMatrix *matrix;
	NSFont *normalFont;
	NSFont *boldFont;
	IBOutlet id delegate;
        NSTimer *_dayTimer;
}

- (id)initWithFrame:(NSRect)frame;
- (void)setDate:(Date *)date;
- (Date *)date;
- (void)setDelegate:(id)aDelegate;
- (id)delegate;

@end

@interface NSObject(CalendarViewDelegate)

- (void)calendarView:(CalendarView *)cs selectedDateChanged:(Date *)date;
- (void)calendarView:(CalendarView *)cs currentDateChanged:(Date *)date;

@end
