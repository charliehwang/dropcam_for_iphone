#!/bin/bash

ROOT_PATH=`pwd`/`dirname "$0"`
LIB_PATH=$ROOT_PATH/ffmpeg_build

if [ ! -s $ROOT_PATH/ffmpeg/libswscale ] ; then
	ln -sf ../libswscale/ $ROOT_PATH/ffmpeg/libswscale
fi

mkdir -p $LIB_PATH/{i386,iphone3g,iphone3gs}

cd $LIB_PATH/iphone3gs

COMMON_PARAMS="--disable-doc --disable-ffplay --disable-ffserver \
--disable-ipv6 --disable-encoders --disable-decoders --disable-hwaccels \
--disable-muxers --disable-demuxers --disable-parsers --disable-bsfs \
--disable-protocols --disable-indevs --disable-outdevs --disable-devices \
--disable-filters \
--enable-encoder=rawvideo \
--enable-decoder=h264 \
--enable-muxer=rawvideo \
--enable-demuxer=h264 \
--enable-parser=h264 \
--disable-zlib --disable-bzlib"

../../ffmpeg/configure --enable-cross-compile --arch=arm --target-os=darwin \
--cc=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc \
--as='gas-preprocessor.pl /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc' \
--sysroot=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk \
--cpu=cortex-a8 --extra-cflags='-arch armv7' --extra-ldflags='-arch armv7' --enable-pic \
$COMMON_PARAMS

make

cd $LIB_PATH/iphone3g

../../ffmpeg/configure --enable-cross-compile --arch=arm --target-os=darwin \
--cc=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc \
--as='gas-preprocessor.pl /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc' \
--sysroot=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk \
--cpu=arm1176jzf-s --extra-cflags='-arch armv6' --extra-ldflags='-arch armv6' --enable-pic \
$COMMON_PARAMS

make

cd $LIB_PATH/i386

../../ffmpeg/configure \
--arch=i386 --extra-cflags='-arch i386' --extra-ldflags='-arch i386' \
--enable-cross-compile \
--sysroot=/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator3.0.sdk \
--disable-mmx --disable-mmx2 \
$COMMON_PARAMS

make

cd $LIB_PATH

for l in `echo -ne "libavcodec\nlibavdevice\nlibavformat\nlibavutil\nlibswscale"`; do
	lipo -create "i386/$l/$l.a" "iphone3gs/$l/$l.a" "iphone3g/$l/$l.a" -output "$l.a";
done

