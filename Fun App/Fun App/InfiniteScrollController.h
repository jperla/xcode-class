//
//  InfiniteScrollController.h
//  Fun App
//
//  Created by Joseph Perla on 4/3/12.
//  Copyright (c) 2012 Ivy Call, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfiniteScrollController : UITableViewController

@property (strong) UINavigationController *parentNavigationController;
@property () NSInteger numRowsToReturn;
@property () NSInteger infiniteScrollLock;

@end
