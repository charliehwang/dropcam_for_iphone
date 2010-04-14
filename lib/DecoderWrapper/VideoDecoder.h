//
//  VideoDecoder.h
//  DecoderWrapper
//
//  Copyright 2010 Dropcam. All rights reserved.
//

#import <Foundation/Foundation.h>

enum VideoCodecType {
	kVCT_H264
};

enum VideoColorSpace {
	kVCS_RGBA32
};

typedef void (*LogCallbackfn)(int level, const char *module, const char* logLine);

@interface VideoDecoder : NSObject {
	struct AVCodec *codec;
	struct AVCodecContext *codecCtx;
	struct AVFrame *srcFrame;
	struct AVFrame *dstFrame;
	struct SwsContext *convertCtx;
	uint8_t *outputBuf;
	int outputBufLen;
	
	BOOL outputInit;
	BOOL frameReady;	
}

+ (void)staticInitialize;
+ (void)registerLogCallback:(LogCallbackfn)fn;

- (id)initWithCodec:(enum VideoCodecType)codecType 
		 colorSpace:(enum VideoColorSpace)colorSpace 
			  width:(int)width 
			 height:(int)height 
		privateData:(NSData*)privateData;

- (void)decodeFrame:(NSData*)frameData;

- (BOOL)isFrameReady;
- (NSData*)getDecodedFrame;
- (NSUInteger)getDecodedFrameWidth;
- (NSUInteger)getDecodedFrameHeight;

@end
