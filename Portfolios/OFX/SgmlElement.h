//
//  SgmlElement.h
//  Portfolio
//
//  Created by Adam Ernst on 11/24/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SgmlAggregateElement;

@interface SgmlElement : NSObject {
	NSString *name;
	SgmlAggregateElement *parent;
}

@property (nonatomic, readonly, retain) NSString *name;
@property (nonatomic, assign) SgmlAggregateElement *parent;
@property (nonatomic, readonly, retain) NSString *content;

- (id)initWithName:(NSString *)newName;
- (NSArray *)elementsForXPathComponents:(NSArray *)xpath error:(NSError **)error;
- (SgmlElement *)firstSubElementWithName:(NSString *)compareName;

@end
