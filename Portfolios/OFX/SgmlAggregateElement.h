//
//  SgmlAggregateElement.h
//  Portfolio
//
//  Created by Adam Ernst on 11/24/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SgmlElement.h"


@interface SgmlAggregateElement : SgmlElement {
	NSArray *elements;
}

+ (SgmlAggregateElement *)aggregateElementWithName:(NSString *)newName elements:(NSArray *)newElements;

@property (nonatomic, readonly, retain) NSArray *elements;

- (id)initWithName:(NSString *)newName elements:(NSArray *)newElements;

@end
