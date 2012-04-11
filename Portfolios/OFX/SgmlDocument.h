//
//  SgmlDocument.h
//  Portfolio
//
//  Created by Adam Ernst on 11/22/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	InContent,
	InTag
} ParserState;

extern NSString *SgmlDocumentErrorDomain;

@class SgmlElement;

@interface SgmlDocument : NSObject {
	/* Parsing context */
	ParserState      state;
	NSMutableArray  *openTags;    /* Of NSData */
	NSMutableData   *currentTag;
	NSMutableData   *currentContent;
	NSMutableArray  *elementsStack; /* NSMutableArray of NMutableArrays */
	
	SgmlElement     *rootElement;
}

- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (NSArray *)elementsForXPath:(NSString *)xpath error:(NSError **)error;

@property (nonatomic, readonly, retain) SgmlElement *rootElement;

@end
