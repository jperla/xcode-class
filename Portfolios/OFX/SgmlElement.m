//
//  SgmlElement.m
//  Portfolio
//
//  Created by Adam Ernst on 11/24/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "SgmlElement.h"


@implementation SgmlElement

@synthesize name, parent;

- (id)initWithName:(NSString *)newName {
	if (self = [super init]) {
		name = [newName retain];
	}
	return self;
}

- (void)dealloc {
	[name release];
	[super dealloc];
}

- (NSArray *)elementsForXPathComponents:(NSArray *)xpath error:(NSError **)error {
	if ([xpath count] == 0) return [NSArray arrayWithObject:self];
	return [NSArray array];
}

- (SgmlElement *)firstSubElementWithName:(NSString *)compareName {
	return nil;
}

- (NSString *)content {
	return nil;
}

@end
