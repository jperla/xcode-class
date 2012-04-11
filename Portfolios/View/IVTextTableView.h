#import <UIKit/UIKit.h>


@interface IVTextTableView : UITableView
{
	UIView* _trackedFirstResponder;
	BOOL _handledEvent;
}

@end
