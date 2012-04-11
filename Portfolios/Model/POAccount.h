//
//  POAccount.h
//  Portfolio
//
//  Created by Adam Ernst on 11/18/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@class POPosition;

@interface POAccount : NSObject <NSCoding> {
	NSString *name;	
	
	NSMutableArray  *positions;
	NSRecursiveLock *positionsLock;
}

@property (nonatomic, copy) NSString *name;

- (id)initWithName:(NSString *)newName;

- (NSDecimalNumber *)value;
- (NSDecimalNumber *)change;

- (POPosition *)objectInPositionsAtIndex:(NSUInteger)idx;
- (NSUInteger)countOfPositions;
- (void)insertObject:(POPosition *)obj inPositionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPositionsAtIndex:(NSUInteger)idx;
- (void)replaceObjectInPositionsAtIndex:(NSUInteger)idx withObject:(POPosition *)obj;

/* Protected (for POAutomaticAccount use): */
- (NSDecimalNumber *)positionsTotalForKey:(NSString *)key;

@end
