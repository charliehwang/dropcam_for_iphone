//
//  RTSPClient.h
//  RTSPClient
//
//  Copyright 2010 Dropcam. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RTSPSubsessionDelegate
- (void)didReceiveFrame:(NSData*)frameData presentationTime:(NSDate*)presentationTime;
@end

@interface RTSPSubsession : NSObject {
	struct RTSPSubsessionContext *context;
	id <RTSPSubsessionDelegate> delegate;
}

- (NSString*)getMediumName;
- (NSString*)getProtocolName;
- (NSString*)getCodecName;
- (NSUInteger)getServerPortNum;
- (NSString*)getSDP_spropparametersets;
- (NSUInteger)getSDP_VideoWidth;
- (NSUInteger)getSDP_VideoHeight;
- (void)increaseReceiveBufferTo:(NSUInteger)size;
- (void)setPacketReorderingThresholdTime:(NSUInteger)uSeconds;

@property (assign) id <RTSPSubsessionDelegate> delegate;

@end

@interface RTSPClientSession : NSObject {
	struct RTSPClientSessionContext *context;
	NSURL *url;
	NSString *username;
	NSString *password;
	
	NSString *sdp;
}

- (id)initWithURL:(NSURL*)url;
- (id)initWithURL:(NSURL*)url username:(NSString*)username password:(NSString*)password;
- (BOOL)setup;
- (NSArray*)getSubsessions;
- (BOOL)setupSubsession:(RTSPSubsession*)subsession clientPortNum:(NSUInteger)portNum;
- (BOOL)play;
- (BOOL)teardown;
- (BOOL)runEventLoop:(char*)cancelSession;
- (NSString*)getLastErrorString;
- (NSString*)getSDP;

@end

