//
//  VideoDecoder.m
//  DecoderWrapper
//
//  Copyright 2010 Dropcam. All rights reserved.
//

#import "VideoDecoder.h"

#include <avformat.h>
#include <avcodec.h>
#include <swscale.h>

//#define SHOW_DEBUG_MV

LogCallbackfn g_logCallbackFn = NULL;

static void av_log_callback(void *ptr, 
                            int level, 
                            const char *fmt, 
                            va_list vl)
{
    static char line[1024] = {0};
    const char *module = "unknown";
	
    if (ptr)
    {
        AVClass *avc = *(AVClass**) ptr;
        module = avc->item_name(ptr);
    }
	
    vsnprintf(line, sizeof(line), fmt, vl);

	if (g_logCallbackFn) {
		g_logCallbackFn(level, module, line);
	}
}

@implementation VideoDecoder

+ (void)staticInitialize {
	av_register_all();	
	avcodec_init();
}

+ (void)registerLogCallback:(LogCallbackfn)fn {
	g_logCallbackFn = fn;
	av_log_set_callback(av_log_callback);
}

- (id)initWithCodec:(enum VideoCodecType)codecType 
		 colorSpace:(enum VideoColorSpace)colorSpace 
			  width:(int)width 
			 height:(int)height 
		privateData:(NSData*)privateData {
	if(self = [super init]) {
		
		codec = avcodec_find_decoder(CODEC_ID_H264);
		codecCtx = avcodec_alloc_context();
		
		// Note: for H.264 RTSP streams, the width and height are usually not specified (width and height are 0).  
		// These fields will become filled in once the first frame is decoded and the SPS is processed.
		codecCtx->width = width;
		codecCtx->height = height;
		
		codecCtx->extradata = av_malloc([privateData length]);
		codecCtx->extradata_size = [privateData length];
		[privateData getBytes:codecCtx->extradata length:codecCtx->extradata_size];
		codecCtx->pix_fmt = PIX_FMT_YUV420P;
#ifdef SHOW_DEBUG_MV
		codecCtx->debug_mv = 0xFF;
#endif
		
		srcFrame = avcodec_alloc_frame();
		dstFrame = avcodec_alloc_frame();
		
		int res = avcodec_open(codecCtx, codec);
		if (res < 0)
		{
			NSLog(@"Failed to initialize decoder");
		}
	}
	
	return self;	
}

- (void)decodeFrame:(NSData*)frameData {
	AVPacket packet = {0};
	packet.data = (uint8_t*)[frameData bytes];
	packet.size = [frameData length];
	
	int frameFinished = 0;
	int res = avcodec_decode_video2(codecCtx, srcFrame, &frameFinished, &packet);
	if (res < 0)
	{
		NSLog(@"Failed to decode frame");
	}
	
	// Need to delay initializing the output buffers because we don't know the dimensions until we decode the first frame.
	if (!outputInit) {
		if (codecCtx->width > 0 && codecCtx->height > 0) {
#ifdef _DEBUG
			NSLog(@"Initializing decoder with frame size of: %dx%d", codecCtx->width, codecCtx->height);
#endif
			
			outputBufLen = avpicture_get_size(PIX_FMT_RGBA, codecCtx->width, codecCtx->height);
			outputBuf = av_malloc(outputBufLen);
			
			avpicture_fill((AVPicture*)dstFrame, outputBuf, PIX_FMT_RGBA, codecCtx->width, codecCtx->height);
			
			convertCtx = sws_getContext(codecCtx->width, codecCtx->height, codecCtx->pix_fmt,  codecCtx->width, 
										codecCtx->height, PIX_FMT_RGBA, SWS_FAST_BILINEAR, NULL, NULL, NULL); 
			
			outputInit = YES;
		}
		else {
			NSLog(@"Could not get video output dimensions");
		}
	}
	
	if (frameFinished)
		frameReady = YES;
}

- (BOOL)isFrameReady {
	return frameReady;
}

- (NSData*)getDecodedFrame {
	if (!frameReady)
		return nil;
	
	sws_scale(convertCtx, (const uint8_t**)srcFrame->data, srcFrame->linesize, 0, codecCtx->height, dstFrame->data, dstFrame->linesize);
	
	return [NSData dataWithBytesNoCopy:outputBuf length:outputBufLen freeWhenDone:NO];
}

- (NSUInteger)getDecodedFrameWidth {
	return codecCtx->width;
}

- (NSUInteger)getDecodedFrameHeight {
	return codecCtx->height;
}


- (void)dealloc {
	av_free(codecCtx->extradata);
	avcodec_close(codecCtx);
	av_free(codecCtx);
	av_free(srcFrame);
	av_free(dstFrame);
	av_free(outputBuf);
	
	[super dealloc];
}

@end
