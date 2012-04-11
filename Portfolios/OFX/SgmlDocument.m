//
//  SgmlDocument.m
//  Portfolio
//
//  Created by Adam Ernst on 11/22/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "SgmlDocument.h"
#import "SgmlElement.h"
#import "SgmlAggregateElement.h"
#import "SgmlContentElement.h"
#import <mach/mach_time.h>

#define STRING_FROM_DATA(x, enc) ([[(NSString *)CFStringCreateWithBytes(NULL, CFDataGetBytePtr((CFDataRef) x), CFDataGetLength((CFDataRef) x), enc, false) autorelease] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]])

NSString *SgmlDocumentErrorDomain = @"SgmlDocument";

@interface SgmlDocument(PrivateMethods)
- (BOOL)parse:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)error;
@end

@implementation SgmlDocument

@synthesize rootElement;

- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)error {
	if (self = [super init]) {
		if (![self parse:data encoding:(NSStringEncoding)encoding error:error]) return nil;
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

- (BOOL)handleInContent:(char)c encoding:(NSStringEncoding)encoding error:(NSError **)error {
	switch (c) {
		case '<':
			state = InTag;
			NSAssert([currentTag length] == 0, @"Starting tag but currentTag is non-empty");
			break;
		default:
			if ([openTags count] == 0) {
				/* Data before an open tag. Ignore if it's whitespace */
				if (isspace(c)) return YES;
				/* Otherwise it's an error */
				if (error) {
					*error = [NSError errorWithDomain:SgmlDocumentErrorDomain 
												 code:101 
											 userInfo:[NSDictionary dictionaryWithObject:@"Non-whitespace data outside of root element" forKey:NSLocalizedDescriptionKey]];
				}
				return NO;
			}
			if ([currentContent length] > 0 || !isspace(c)) {
				CFDataAppendBytes((CFMutableDataRef) currentContent, (const UInt8 *) &c, 1);
			}
			break;
	}
	return YES;
}

- (BOOL)handleInTag:(char)c encoding:(NSStringEncoding)encoding error:(NSError **)error {
	switch (c) {
		case '>':
			if (((char *)[currentTag bytes])[0] == '/') {
				/* Close tag. */
				NSData *closesTag = [currentTag subdataWithRange:NSMakeRange(1, [currentTag length] - 1)];
				
				if ([currentContent length]) {
					if (![[openTags lastObject] isEqualToData:closesTag]) {
						/* Close tag doesn't match the last open tag-- */
						/* Implicitly close the last tag and assume the one previous to that is the one we're closing */
						NSAssert([(NSMutableArray *)[elementsStack lastObject] count] == 0, @"elementsStack non-empty when closing a content element");
						
						SgmlContentElement *e = [SgmlContentElement contentElementWithName:STRING_FROM_DATA([openTags lastObject], encoding) 
																				   content:STRING_FROM_DATA(currentContent, encoding)];
						[elementsStack removeLastObject];
						[(NSMutableArray *)[elementsStack lastObject] addObject:e];
						
						[currentContent setLength:0];
						[openTags removeLastObject];
					}
					/* Else, this must be an explicit close of a content element--handled next */
				}
				if (![[openTags lastObject] isEqualToData:closesTag]) {
					if (error) {
						*error = [NSError errorWithDomain:SgmlDocumentErrorDomain 
													 code:102 
												 userInfo:[NSDictionary dictionaryWithObject:@"Unmatched tag" forKey:NSLocalizedDescriptionKey]];
					}
					return NO;
				}
				
				/* Explicit close tag */
				SgmlElement *e;
				if ([currentContent length]) {
					NSAssert([(NSMutableArray *)[elementsStack lastObject] count] == 0, @"elementsStack non-empty when closing a content element");
					
					e = [SgmlContentElement contentElementWithName:STRING_FROM_DATA([openTags lastObject], encoding) 
														   content:STRING_FROM_DATA(currentContent, encoding)];
				} else {
					e = [SgmlAggregateElement aggregateElementWithName:STRING_FROM_DATA([openTags lastObject], encoding) 
															  elements:(NSArray *)[elementsStack lastObject]];
				}
				[elementsStack removeLastObject];
				NSAssert([elementsStack lastObject], @"Inserting aggregate element but elementsStack is empty");
				[(NSMutableArray *)[elementsStack lastObject] addObject:e];
				
				[openTags removeLastObject];
			} else {
				if ([currentContent length]) {
					/* Implicitly close the tag. */
					NSAssert([(NSMutableArray *)[elementsStack lastObject] count] == 0, @"elementsStack non-empty when closing a content element");
					
					SgmlContentElement *e = [SgmlContentElement contentElementWithName:STRING_FROM_DATA([openTags lastObject], encoding) 
																			   content:STRING_FROM_DATA(currentContent, encoding)];
					[elementsStack removeLastObject];
					[(NSMutableArray *)[elementsStack lastObject] addObject:e];
					
					[openTags removeLastObject];
				}
				[openTags addObject:[[currentTag copy] autorelease]];
				[elementsStack addObject:[NSMutableArray arrayWithCapacity:16]];
			}
			state = InContent;
			[currentContent setLength:0];
			[currentTag setLength:0];
			break;
		case '<':
			if (error) {
				*error = [NSError errorWithDomain:SgmlDocumentErrorDomain 
											 code:103 
										 userInfo:[NSDictionary dictionaryWithObject:@"< inside tag" forKey:NSLocalizedDescriptionKey]];					
			}
			return NO;
		default:
			CFDataAppendBytes((CFMutableDataRef) currentTag, (const UInt8 *) &c, 1);
			break;
	}
	return YES;
}

- (BOOL)parse:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)error {
	char *d = (char *) [data bytes];
	NSUInteger length = [data length];
		
	/* These are all auto-released since they aren't used after parse:,
	   but they're also ivars to cut down on param passing */
	openTags = [NSMutableArray arrayWithCapacity:16];
	currentTag = [NSMutableData dataWithCapacity:16];
	currentContent = [NSMutableData dataWithCapacity:256];
	elementsStack = [NSMutableArray arrayWithCapacity:16];
	[elementsStack addObject:[NSMutableArray arrayWithCapacity:16]];
	state = InContent;
	
	for (NSUInteger i = 0; i < length; i++) {
		switch (state) {
			case InContent:
				if (![self handleInContent:d[i] encoding:encoding error:error]) return NO;
				break;
			case InTag:
				if (![self handleInTag:d[i] encoding:encoding error:error]) return NO;
				break;
		}
	}
	
	if ([openTags count]) {
		if (error) {
			*error = [NSError errorWithDomain:SgmlDocumentErrorDomain 
										 code:104 
									 userInfo:[NSDictionary dictionaryWithObject:@"Unbalanced open tag at end of parse" forKey:NSLocalizedDescriptionKey]];		
		}
		return NO;
	}
	
	rootElement = [(SgmlElement *)[(NSMutableArray *)[elementsStack objectAtIndex:0] objectAtIndex:0] retain];
	
	return YES;
}

- (NSArray *)elementsForXPath:(NSString *)xpath error:(NSError **)error {
	NSArray *components = [xpath componentsSeparatedByString:@"/"];
	if ([(NSString *)[components objectAtIndex:0] length]) {
		if (error) {
			*error = [NSError errorWithDomain:SgmlDocumentErrorDomain 
										 code:105 
									 userInfo:[NSDictionary dictionaryWithObject:@"Invalid Xpath syntax" forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	
	if ([[components objectAtIndex:0] isEqualToString:@"*"] || ![[rootElement name] isEqualToString:[components objectAtIndex:1]]) {
		return [NSArray array];
	}
	return [rootElement elementsForXPathComponents:[components subarrayWithRange:NSMakeRange(2, [components count] - 2)] error:error];
}

@end
