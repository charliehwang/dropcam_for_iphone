//
//  RTSPClient.h
//  RTSPClient
//
//  Copyright 2010 Dropcam. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RTSPSubsessionDelegate;

@interface RTSPSubsession : NSObject {
	struct RTSPSubsessionContext *context;
	id <RTSPSubsessionDelegate> delegate;
}

- (NSString*)getSessionId;
- (NSString*)getMediumName;
- (NSString*)getProtocolName;
- (NSString*)getCodecName;
- (NSUInteger)getServerPortNum;
- (NSString*)getSDP_spropparametersets;
- (NSString*)getSDP_config;
- (NSString*)getSDP_mode;
- (NSUInteger)getSDP_VideoWidth;
- (NSUInteger)getSDP_VideoHeight;
- (NSUInteger)getClientPortNum;
- (int)getSocket;
- (void)increaseReceiveBufferTo:(NSUInteger)size;
- (void)setPacketReorderingThresholdTime:(NSUInteger)uSeconds;
- (BOOL)timeIsSynchronized;

@property (assign) id <RTSPSubsessionDelegate> delegate;

@end

@protocol RTSPSubsessionDelegate
- (void)didReceiveFrame:(const uint8_t*)frameData
		frameDataLength:(int)frameDataLength
	   presentationTime:(struct timeval)presentationTime
 durationInMicroseconds:(unsigned)duration
			 subsession:(RTSPSubsession*)subsession;
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
- (BOOL)setupSubsession:(RTSPSubsession*)subsession useTCP:(BOOL)useTCP;
- (BOOL)play;
- (BOOL)teardown;
- (BOOL)runEventLoop:(char*)cancelSession;
- (NSString*)getLastErrorString;
- (NSString*)getSDP;
- (int)getSocket;

@end

