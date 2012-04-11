//
//  OfxRequest.h
//  Portfolio
//
//  Created by Adam Ernst on 11/22/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SgmlDocument;

extern NSString *OfxRequestErrorDomain;

enum {
	kOfxRequestBadDocumentError,
	kOfxRequestMissingHeaderError,
	kOfxRequestUnexpectedHeaderValueError,
	kOfxRequestHeaderNotFoundError,
	kOfxRequestServerError,
	kOfxRequestBadPasswordError
};

@interface OfxRequest : NSObject {
	NSString *url;
	NSString *body;
	NSString *password;
}

+ (OfxRequest *)requestForAccountsWithUrl:(NSString *)url userId:(NSString *)userId password:(NSString *)password;
+ (OfxRequest *)requestForPositionsWithUrl:(NSString *)url userId:(NSString *)userId password:(NSString *)password brokerId:(NSString *)brokerId acctId:(NSString *)acctId;

/* Check a STATUS tag at the given path for an error. */
+ (BOOL)ofxResponseSuccessful:(SgmlDocument *)doc statusPath:(NSString *)path error:(NSError **)error;

/* Check the global SONRS's STATUS tag for an error. */
+ (BOOL)ofxSignOnSuccessful:(SgmlDocument *)doc error:(NSError **)error;

/* Body should be a fully formed OFX request including OFX headers, except that in place of the password the 
   Objective-C format string "@%" should be used.
   Url should be the OFX url for the server.
   Password should be the user's password in plain text. */
- (id)initWithBody:(NSString *)newBody url:(NSString *)newUrl password:(NSString *)newPassword;
- (SgmlDocument *)sendRequestReturningError:(NSError **)error transcript:(NSString **)transcript;

@end
