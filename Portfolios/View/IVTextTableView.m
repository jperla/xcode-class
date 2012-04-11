#import "IVTextTableView.h"


@implementation IVTextTableView

- (void)dealloc {
	/* Nothing to dealloc. */
	[super dealloc];
}

- (UIView*)safeHitTest:(CGPoint)point withEvent:(UIEvent*)event
{
	// reimplements hitTest:withEvent: which in the case of UITableView hides the presence of certain cells and subviews
	for (UIView* subview in self.subviews)
	{
		UIView* hitTest = [subview hitTest:[self convertPoint:point toView:subview] withEvent:event];
		if (hitTest)
			return hitTest;
	}
	return nil;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	UIView* hitView = [self safeHitTest:[touches.anyObject locationInView:self] withEvent:event];
	if ([hitView isFirstResponder])
	{
		if (!_trackedFirstResponder)
		{
			_trackedFirstResponder = [hitView retain];
			[_trackedFirstResponder touchesBegan:touches withEvent:event];
		}
	}
	else
		[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	if (_trackedFirstResponder && !_handledEvent)
	{
		_handledEvent = YES;
		[_trackedFirstResponder touchesMoved:touches withEvent:event];
		_handledEvent = NO;
	}
	else
		[super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	if (_trackedFirstResponder && !_handledEvent)
	{
		_handledEvent = YES;
		[_trackedFirstResponder touchesEnded:touches withEvent:event];
		_handledEvent = NO;
		
		[_trackedFirstResponder release];
		_trackedFirstResponder = nil;
	}
	else
		[super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	if (_trackedFirstResponder && !_handledEvent)
	{
		_handledEvent = YES;
		[_trackedFirstResponder touchesCancelled:touches withEvent:event];
		_handledEvent = NO;
		
		[_trackedFirstResponder release];
		_trackedFirstResponder = nil;
	}
	else
		[super touchesCancelled:touches withEvent:event];
}

@end

