//
//  SgmlAggregateElement.m
//  Portfolio
//
//  Created by Adam Ernst on 11/24/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "SgmlAggregateElement.h"


@implementation SgmlAggregateElement

@synthesize elements;

+ (SgmlAggregateElement *)aggregateElementWithName:(NSString *)newName elements:(NSArray *)newElements {
	return [[[SgmlAggregateElement alloc] initWithName:newName elements:newElements] autorelease];
}

- (id)initWithName:(NSString *)newName elements:(NSArray *)newElements {
	if (self = [super initWithName:newName]) {
		elements = [newElements retain];
		for (SgmlElement *e in elements) {
			[e setParent:self];
		}
	}
	return self;
}

- (void)dealloc {
	[elements release];
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@>%@</%@>", name, [elements componentsJoinedByString:@""], name];
}

- (NSArray *)elementsForXPathComponents:(NSArray *)xpath error:(NSError **)error {
	if ([xpath count] == 0) return [NSArray arrayWithObject:self];
	
	NSString *tagName = [xpath objectAtIndex:0];
	NSArray *subXPath = [xpath subarrayWithRange:NSMakeRange(1, [xpath count] - 1)];
	NSMutableArray *returnElements = [NSMutableArray arrayWithCapacity:8];
	
	for (SgmlElement *e in elements) {
		if ([tagName isEqualToString:@"*"] || [[e name] isEqualToString:tagName]) {
			[returnElements addObjectsFromArray:[e elementsForXPathComponents:subXPath error:error]];
		}
	}
	return returnElements;
}

- (SgmlElement *)firstSubElementWithName:(NSString *)compareName {
	for (SgmlElement *e in elements) {
		if ([[e name] isEqualToString:compareName]) return e;
	}
	return nil;
}

@end
