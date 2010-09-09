//
//  RTSPClient.m
//  RTSPClient
//
//  Copyright 2010 Dropcam. All rights reserved.
//

#import "RTSPClientSession.h"

#include <liveMedia.hh>
#include <BasicUsageEnvironment.hh>
#include <GroupsockHelper.hh>

class RTSPSubsessionMediaSink : public MediaSink {
public:
	RTSPSubsessionMediaSink(UsageEnvironment& _env, RTSPSubsession *_subsession) 
	: MediaSink(_env) {
		
		subsession = _subsession;
		bufLen = 64000;
		buf = new uint8_t[bufLen];
	}
	
	virtual ~RTSPSubsessionMediaSink() {
		delete[] buf;
	}
	
	void afterGettingFrame(unsigned frameSize, 
						   unsigned numTruncatedBytes, 
						   struct timeval presentationTime,
						   unsigned durationInMicroseconds) {
		if (numTruncatedBytes > 0)
			NSLog(@"Frame was truncated.");
		
		[subsession.delegate didReceiveFrame:buf
							 frameDataLength:frameSize
							presentationTime:presentationTime 
					  durationInMicroseconds:durationInMicroseconds 
								  subsession:subsession];
		
		continuePlaying();		
	}
	
	static void afterGettingFrame(void* clientData, unsigned frameSize, 
								  unsigned numTruncatedBytes, 
								  struct timeval presentationTime,
								  unsigned durationInMicroseconds) {
		// Create an autorelease pool around each invocation of afterGettingFrame because we're being dispached
		// calls from the Live555 event loop, not a normal Cocoa event loop.
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		RTSPSubsessionMediaSink *sink = (RTSPSubsessionMediaSink*)clientData;
		sink->afterGettingFrame(frameSize, numTruncatedBytes, presentationTime, durationInMicroseconds);
		
		[pool release];
	}
	
	virtual Boolean continuePlaying() {
		if (fSource) {
			fSource->getNextFrame(buf, bufLen, afterGettingFrame, this, onSourceClosure, this);			
			
			return True;
		}
		
		return False;
	}

private:
	RTSPSubsession *subsession;
	uint8_t *buf;
	int bufLen;
};

static void SubsessionAfterPlaying(void* clientData) {
}

struct RTSPSubsessionContext {
	MediaSubsession *subsession;
	UsageEnvironment *env;
};

@implementation RTSPSubsession

@synthesize delegate;

- (id)initWithMediaSubsession:(MediaSubsession*)subsession environment:(UsageEnvironment*)env {
	if (self = [super init]) {
		context = new RTSPSubsessionContext;
		context->subsession = subsession;
		context->env = env;
	}
	
	return self;
}

- (void)dealloc {
	delete context;
	[super dealloc];
}

- (NSString*)getSessionId {
	return [NSString stringWithCString:context->subsession->sessionId encoding:NSUTF8StringEncoding];
}

- (NSString*)getMediumName {
	return [NSString stringWithCString:context->subsession->mediumName() encoding:NSUTF8StringEncoding];
}

- (NSString*)getProtocolName {
	return [NSString stringWithCString:context->subsession->protocolName() encoding:NSUTF8StringEncoding];
}

- (NSString*)getCodecName {
	return [NSString stringWithCString:context->subsession->codecName() encoding:NSUTF8StringEncoding];
}

- (NSUInteger)getServerPortNum {
	return context->subsession->serverPortNum;
}

- (NSUInteger)getClientPortNum {
	return context->subsession->clientPortNum();
}

- (int)getSocket {
	return context->subsession->rtpSource()->RTPgs()->socketNum();
}

- (NSString*)getSDP_spropparametersets {
	return [NSString stringWithCString:context->subsession->fmtp_spropparametersets() encoding:NSUTF8StringEncoding];
}

- (NSString*)getSDP_config {
	return [NSString stringWithCString:context->subsession->fmtp_config() encoding:NSUTF8StringEncoding];
}

- (NSString*)getSDP_mode {
	return [NSString stringWithCString:context->subsession->fmtp_mode() encoding:NSUTF8StringEncoding];
}

- (NSUInteger)getSDP_VideoWidth {
	return context->subsession->videoWidth();
}

- (NSUInteger)getSDP_VideoHeight {
	return context->subsession->videoHeight();
}

- (void)increaseReceiveBufferTo:(NSUInteger)size {
	int recvSocket = context->subsession->rtpSource()->RTPgs()->socketNum();
	increaseReceiveBufferTo(*context->env, recvSocket, size);
}

- (void)setPacketReorderingThresholdTime:(NSUInteger)uSeconds {
	context->subsession->rtpSource()->setPacketReorderingThresholdTime(uSeconds);	
}

- (BOOL)timeIsSynchronized {
	return context->subsession->rtpSource()->hasBeenSynchronizedUsingRTCP();
}

- (void)setDelegate:(id <RTSPSubsessionDelegate>)_delegate {
	delegate = _delegate;
}

- (MediaSubsession*)getMediaSubsession {
	return context->subsession;
}

@end

struct RTSPClientSessionContext {
	TaskScheduler *scheduler;
	UsageEnvironment *env;
	RTSPClient *client;
	MediaSession *session;
};

@implementation RTSPClientSession

- (id)initWithURL:(NSURL*)_url {
	return [self initWithURL:_url username:nil password:nil];
}

- (id)initWithURL:(NSURL*)_url username:(NSString*)_username password:(NSString*)_password {
	if ([super init]) {
		url = [_url retain];
		username = [_username retain];
		password = [_password retain];
		
		context = new RTSPClientSessionContext;
		memset(context, 0, sizeof(*context));

		context->scheduler = BasicTaskScheduler::createNew();
		context->env = BasicUsageEnvironment::createNew(*context->scheduler);
		context->client = RTSPClient::createNew(*context->env);
	}
	
	return self;
}

- (void)dealloc {
	Medium::close(context->client);
	context->env->reclaim();
	delete context->scheduler;
	delete context;
	
	[url release];
	[username release];
	[password release];
	[sdp release];
	[super dealloc];
}

- (BOOL)setup {
	char* rawsdp = NULL;
	if (username && password) {
		rawsdp = context->client->describeWithPassword([[url absoluteString] UTF8String], 
													   [username UTF8String], 
													   [password UTF8String]);
	}
	else {
		rawsdp = context->client->describeURL([[url absoluteString] UTF8String]);
	}
	
	if (rawsdp) {
		sdp = [[NSString alloc] initWithCString:rawsdp encoding:NSUTF8StringEncoding];
		delete[] rawsdp;
	}
	
	if (sdp == nil)
		return NO;

	MediaSession *session = MediaSession::createNew(*context->env, [sdp UTF8String]);
	if (!session) {
		return NO;
	}
	
	context->session = session;
	return YES;
}

- (NSArray*)getSubsessions {
	NSMutableArray *subsessions = [[[NSMutableArray alloc] init] autorelease];
	
	MediaSubsessionIterator iter(*context->session);
	while (MediaSubsession *subsession = iter.next()) {
		RTSPSubsession *newObj = [[[RTSPSubsession alloc] initWithMediaSubsession:subsession environment:context->env] autorelease];
		[subsessions addObject:newObj];
	}
	
	return subsessions;
}

- (BOOL)setupSubsession:(RTSPSubsession*)subsession useTCP:(BOOL)useTCP {
	MediaSubsession* cppSubsession = [subsession getMediaSubsession];
	
	if (!cppSubsession->initiate())	{
		return NO;
	}
	
	if (!context->client->setupMediaSubsession(*cppSubsession, False, useTCP)) {
		return NO;
	}
	
	RTSPSubsessionMediaSink *sink = new RTSPSubsessionMediaSink(*context->env, subsession);
	cppSubsession->sink = sink;
	cppSubsession->sink->startPlaying(*(cppSubsession->readSource()), SubsessionAfterPlaying, self);
	
	return YES;
}

- (BOOL)play {
	double startTime = context->session->playStartTime();
	context->client->playMediaSession(*context->session, startTime, -1.0f, 1.0f);
	
	return YES;
}

- (BOOL)teardown {
	context->client->teardownMediaSession(*context->session);
	
	MediaSubsessionIterator iter(*context->session);
	while (MediaSubsession *subsession = iter.next()) {
		if (subsession->sink) {
			Medium::close(subsession->sink);
		}
	}
	
	Medium::close(context->session);
	
	return YES;
}

- (BOOL)runEventLoop:(char*)cancelSession {
	// Main event loop - will block until cancelSession becomes true
	context->scheduler->doEventLoop(cancelSession);

	return YES;
}

- (NSString*)getLastErrorString {
	return [NSString stringWithCString:context->env->getResultMsg() encoding:NSUTF8StringEncoding];
}

- (NSString*)getSDP {
	return sdp;
}

- (int)getSocket {
	return context->client->socketNum();
}


@end
