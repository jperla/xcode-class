//
//  OfxRequest.m
//  Portfolio
//
//  Created by Adam Ernst on 11/22/08.
//  Copyright 2008 cosmicsoft. All rights reserved.
//

#import "OfxRequest.h"
#import "SgmlDocument.h"
#import "SgmlAggregateElement.h"
#import "SgmlContentElement.h"
#import "SgmlElement.h"

NSString *OfxRequestErrorDomain = @"OfxRequest";

@interface OfxRequest(PrivateMethods)
- (SgmlDocument *)parseResponse:(NSData *)data error:(NSError **)error;
@end

@implementation OfxRequest

+ (NSString*)stringWithUUID {
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *newUUID = (NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	return [newUUID autorelease];
}

+ (NSString *)ofxStringFromDate:(NSDate *)date {
	NSDateFormatter *f = [[[NSDateFormatter alloc] init] autorelease];
	[f setDateFormat:@"yyyyMMddHHmmss"];
	return [f stringFromDate:[date addTimeInterval:-[[NSTimeZone defaultTimeZone] secondsFromGMT]]];
}

+ (OfxRequest *)requestForAccountsWithUrl:(NSString *)url userId:(NSString *)userId password:(NSString *)password {
	NSString *body = [[[NSString alloc] initWithData:[[NSFileHandle fileHandleForReadingAtPath:[[NSBundle mainBundle] pathForResource:@"OfxAccountRequest" ofType:@"ofx"]] availableData] encoding:NSUTF8StringEncoding] autorelease];
	
	return [[[OfxRequest alloc] initWithBody:[NSString stringWithFormat:body, [OfxRequest ofxStringFromDate:[NSDate date]], userId, [OfxRequest stringWithUUID]] url:url password:password] autorelease];
}

+ (OfxRequest *)requestForPositionsWithUrl:(NSString *)url userId:(NSString *)userId password:(NSString *)password brokerId:(NSString *)brokerId acctId:(NSString *)acctId {
	NSString *body = [[[NSString alloc] initWithData:[[NSFileHandle fileHandleForReadingAtPath:[[NSBundle mainBundle] pathForResource:@"OfxPositionsRequest" ofType:@"ofx"]] availableData] encoding:NSUTF8StringEncoding] autorelease];
	
	return [[[OfxRequest alloc] initWithBody:[NSString stringWithFormat:body, [OfxRequest ofxStringFromDate:[NSDate date]], userId, [OfxRequest stringWithUUID], brokerId, acctId] url:url password:password] autorelease];
}

+ (BOOL)ofxResponseSuccessful:(SgmlDocument *)doc statusPath:(NSString *)path error:(NSError **)error {
	NSArray *elements = [doc elementsForXPath:path error:error];
	if (!elements || [elements count] != 1 || ![[[elements objectAtIndex:0] class] isSubclassOfClass:[SgmlAggregateElement class]]) {
		if (error) {
			*error = [NSError errorWithDomain:OfxRequestErrorDomain 
										 code:kOfxRequestBadDocumentError 
									 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"An unexpected document was received", @"Something unexpected is received from the server") 
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	}
	
	SgmlAggregateElement *e = (SgmlAggregateElement *) [elements objectAtIndex:0];
	NSString *severity = [[e firstSubElementWithName:@"SEVERITY"] content];
	NSInteger code = [[[e firstSubElementWithName:@"CODE"] content] intValue];
	NSInteger errorCode = kOfxRequestServerError;
	if ([severity isEqualToString:@"ERROR"]) {
		if (error) {
			NSString *errorMessage;
			switch (code) {
				case 15500:
					errorCode = kOfxRequestBadPasswordError;
					errorMessage = NSLocalizedString(@"Incorrect username or password", @"Error if a sign-on fails");
					break;
				case 15000:
					errorMessage = NSLocalizedString(@"You must change your password before logging on", @"Instructs user to change their brokerage password");
					break;
				default:
					errorMessage = [NSString stringWithFormat:NSLocalizedString(@"Unexpected error (%@)", @"Unexpected logon error"), 
									[[e firstSubElementWithName:@"MESSAGE"] content]];
			}			
			
			*error = [NSError errorWithDomain:OfxRequestErrorDomain 
										 code:errorCode 
									 userInfo:[NSDictionary dictionaryWithObject:errorMessage
																		  forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	}
	
	return YES;
}

+ (BOOL)ofxSignOnSuccessful:(SgmlDocument *)doc error:(NSError **)error {
	return [OfxRequest ofxResponseSuccessful:doc statusPath:@"/OFX/SIGNONMSGSRSV1/SONRS/STATUS" error:error];
}

- (id)initWithBody:(NSString *)newBody url:(NSString *)newUrl password:(NSString *)newPassword {
	if (self = [super init]) {
		body = [newBody retain];
		url = [newUrl retain];
		password = [newPassword retain];
	}
	return self;
}

- (void)dealloc {
	[body release];
	[url release];
	[password release];
	[super dealloc];
}

- (SgmlDocument *)sendRequestReturningError:(NSError **)error transcript:(NSString **)transcript {
	if (transcript) {
		*transcript = [NSMutableString stringWithCapacity:1024];
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:120.0];
	[request setHTTPMethod:@"POST"];
	if (transcript) {
		[(NSMutableString *)*transcript appendString:[NSString stringWithFormat:body, @""]];
		[(NSMutableString *)*transcript appendString:@"\n\n\n"];
	}
	[request setHTTPBody:[[NSString stringWithFormat:body, password] dataUsingEncoding:NSWindowsCP1252StringEncoding]];
	[request addValue:@"application/x-ofx" forHTTPHeaderField:@"Content-Type"];
	NSURLResponse *response;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
	if (!response) return nil;
	if (transcript) {
		NSString *resp = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
		if (resp) [(NSMutableString *)*transcript appendString:resp];
		[resp release];
	}
	
	return [self parseResponse:responseData error:error];
}

#pragma mark Parsing Response

- (BOOL)confirmHeader:(NSString *)value expectedValue:(NSString *)expected headerName:(NSString *)headerName error:(NSError **)error {
	if (!value) {
		if (error) {
			*error = [NSError errorWithDomain:OfxRequestErrorDomain 
										 code:kOfxRequestMissingHeaderError 
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Missing header %@", headerName] forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	}
	
	if (![[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:expected]) {
		if (error) {
			*error = [NSError errorWithDomain:OfxRequestErrorDomain 
										 code:kOfxRequestUnexpectedHeaderValueError 
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected value for header %@, got %@ expected %@", headerName, value, expected] forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	}
	
	return YES;
}

- (SgmlDocument *)parseResponse:(NSData *)data error:(NSError **)error {
	/* Find the first CRLF/CRLF or LF/LF sequence */
	char *d = (char *) [data bytes];
	NSUInteger length = [data length];
	BOOL lastWasLF = NO;
	NSInteger docOffset = -1;
	
	for (NSUInteger i = 0; i < length; i++) {
		switch (d[i]) {
			case '\n':
				if (lastWasLF) docOffset = i + 1;
				lastWasLF = YES;
				break;
			case '\r':
				break;
			default:
				lastWasLF = NO;
				break;
		}
		if (docOffset != -1) break;
	}
	
	if (docOffset == -1) {
		if (error) {
			*error = [NSError errorWithDomain:OfxRequestErrorDomain 
										 code:kOfxRequestHeaderNotFoundError 
									 userInfo:[NSDictionary dictionaryWithObject:@"No document found; couldn't parse header" forKey:NSLocalizedDescriptionKey]];
		}
		return nil;
	}
	
	/* Parse OFX headers */
	NSString *headerText = [[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:d length:docOffset freeWhenDone:NO] encoding:NSUTF8StringEncoding] autorelease];
	NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithCapacity:8];
	for (NSString *line in [headerText componentsSeparatedByString:@"\n"]) {
		NSArray *components = [line componentsSeparatedByString:@":"];
		if ([components count] != 2) continue;
		[headers setObject:[[components objectAtIndex:1] stringByReplacingOccurrencesOfString:@"\r" withString:@""] forKey:[components objectAtIndex:0]];
	}
	
	if (![self confirmHeader:[headers objectForKey:@"OFXHEADER"] expectedValue:@"100" headerName:@"OFXHEADER" error:error]) return nil;
	if (![self confirmHeader:[headers objectForKey:@"DATA"] expectedValue:@"OFXSGML" headerName:@"DATA" error:error]) return nil;
	if (![self confirmHeader:[headers objectForKey:@"SECURITY"] expectedValue:@"NONE" headerName:@"SECURITY" error:error]) return nil;
	
	NSStringEncoding encoding = NSUTF8StringEncoding;
	if ([[headers objectForKey:@"ENCODING"] isEqualToString:@"USASCII"]) {
		if ([[headers objectForKey:@"CHARSET"] isEqualToString:@"1252"]) {
			encoding = NSWindowsCP1252StringEncoding;
		} else if ([[headers objectForKey:@"CHARSET"] isEqualToString:@"ISO-8859-1"]) {
			encoding = NSISOLatin1StringEncoding;
		}
	}
	
	return [[[SgmlDocument alloc] initWithData:[NSData dataWithBytesNoCopy:&d[docOffset] length:length - docOffset freeWhenDone:NO] encoding:encoding error:error] autorelease];
}

@end
