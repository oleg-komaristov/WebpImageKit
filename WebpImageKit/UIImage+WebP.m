//
//  UIImage+WebP.m
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-11.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import <objc/runtime.h>
#import <libwebp/mux.h>

#import "UIImage+WebP.h"
#import "NSData+WebP.h"
#import "CoreGraphics+WebP.h"
#import "WIKAnimationFrame.h"

extern CGSize scaledImageSize(const CGSize imgSize, const CGSize targetSize, const CGFloat scaleFactor);
static NSUInteger gcdOf(size_t const count, NSUInteger const * const values);

static void *kLoopCountKey = &kLoopCountKey;

@implementation UIImage (WebpDecoder)

+ (nullable instancetype)webpImageWithData:(NSData * const)data {
    return [self webpImageWithData:data displaySize:CGSizeZero];
}

+ (nullable instancetype)webpImageWithData:(NSData * const)data
                               displaySize:(const CGSize)size {
    return [self webpImageWithData:data displaySize:size scaleFactor:1.0];
}

+ (nullable instancetype)webpImageWithData:(NSData * const)data
                               displaySize:(const CGSize)size
                               scaleFactor:(const CGFloat)scaleFactor {
    return [self webpImageWithData:data displaySize:size scaleFactor:scaleFactor loopCount:nil];
}

+ (nullable instancetype)webpImageWithData:(NSData *const)data
                               displaySize:(const CGSize)size
                               scaleFactor:(const CGFloat)scaleFactor
                                 loopCount:(NSUInteger * __nullable)loopCount {
    if (!data.webpIsImage) {
        return nil;
    }
    WebPData webpData;
    WebPDataInit(&webpData);
    webpData.bytes = data.bytes;
    webpData.size = data.length;
    WebPDemuxer *demuxer;
    if (!(demuxer = WebPDemux(&webpData))) {
        return nil;
    }
    const uint32_t flags = WebPDemuxGetI(demuxer, WEBP_FF_FORMAT_FLAGS);
    const __auto_type scale = MAX(scaleFactor, 1.0);

    WebPIterator iterator;
    if (!WebPDemuxGetFrame(demuxer, 1, &iterator)) {
        WebPDemuxReleaseIterator(&iterator);
        WebPDemuxDelete(demuxer);
        return nil;
    }
    __auto_type colorSpace = webpCreateColorSpace(demuxer);
    __auto_type canvasWidth = (size_t) WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
    __auto_type canvasHeight = (size_t) WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    const __auto_type originalSize = CGSizeMake(canvasWidth, canvasHeight);
    const __auto_type scaledSize = scaledImageSize(originalSize, size, scaleFactor);
    const __auto_type isScaledOutput = CGSizeEqualToSize(originalSize, scaledSize);
    if (!(flags & ANIMATION_FLAG)) {
        __auto_type cgImage = webpCreateCGImage(iterator.fragment,
                                                colorSpace,
                                                isScaledOutput ? CGSizeZero : scaledSize);
        __auto_type resultImg = [[UIImage alloc] initWithCGImage:cgImage scale:scale orientation:UIImageOrientationUp];
        CGImageRelease(cgImage);
        CFRelease(colorSpace);
        WebPDemuxReleaseIterator(&iterator);
        WebPDemuxDelete(demuxer);
        if (loopCount) { *loopCount = NSNotFound; }
        return resultImg;
    }
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= (flags & ALPHA_FLAG) ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    __auto_type deviceColorSpace = webpCreateDeviceRgbColorSpace();
    CGContextRef canvas = CGBitmapContextCreate(NULL, canvasWidth, canvasHeight, 8, 0, deviceColorSpace, bitmapInfo);
    CFRelease(deviceColorSpace);
    if (!canvas) {
        WebPDemuxDelete(demuxer);
        CGColorSpaceRelease(colorSpace);
        return nil;
    }

    const __auto_type loopCountValue = WebPDemuxGetI(demuxer, WEBP_FF_LOOP_COUNT);
    if (loopCount) {
        *loopCount = MAX(loopCountValue, 0);
    }
    NSMutableArray<WIKAnimationFrame *> *frames = [NSMutableArray new];
    do {
        @autoreleasepool {
            __auto_type cgOriginal = webpCreateCGImage(iterator.fragment, colorSpace, CGSizeZero);
            if (!cgOriginal) {
                continue;
            }
            __auto_type imgRect = (CGRect){CGPointZero, CGSizeMake(iterator.width, iterator.height)};
            imgRect.origin.x = iterator.x_offset;
            imgRect.origin.y = canvasHeight - CGRectGetHeight(imgRect) - iterator.y_offset;
            if (WEBP_MUX_BLEND != iterator.blend_method) {
                CGContextClearRect(canvas, imgRect);
            }
            CGContextDrawImage(canvas, imgRect, cgOriginal);
            CGImageRef cgImg = CGBitmapContextCreateImage(canvas);
            CGImageRelease(cgOriginal);

            if (isScaledOutput) {
                __auto_type scaledImg = webpCreateScaledCGImage(cgImg, scaledSize);
                CGImageRelease(cgImg);
                cgImg = scaledImg;
            }
            __auto_type frameImg = [[UIImage alloc] initWithCGImage:cgImg scale:scale orientation:UIImageOrientationUp];
            CGImageRelease(cgImg);
            WIKAnimationFrame *frame;
            if ((frame = [[WIKAnimationFrame alloc] initWithImage:frameImg duration:iterator.duration / 1000.0])) {
                [frames addObject:frame];
            }
        }
    } while(WebPDemuxNextFrame(&iterator));

    WebPDemuxReleaseIterator(&iterator);
    WebPDemuxDelete(demuxer);
    CGContextRelease(canvas);
    CGColorSpaceRelease(colorSpace);

    NSTimeInterval fullDuration = 0.0;
    NSUInteger *durations = calloc(frames.count, sizeof(NSUInteger));
    NSAssert(durations, @"Can't allocate memory for durations array");
    if (!durations) {
        return nil;
    }
    for (size_t frameIdx = 0; frameIdx < frames.count; ++frameIdx) {
        const __auto_type value = frames[frameIdx].duration;
        fullDuration += value;
        durations[frameIdx] = (NSUInteger) trunc(value * 1000);
    }
    const __auto_type gcd = gcdOf(frames.count, durations);
    free(durations);

    __auto_type expectedImgNumber = frames.count * (0 < gcd ? (NSUInteger)(fullDuration / gcd) : 1);
    NSMutableArray<UIImage *> *images = [NSMutableArray arrayWithCapacity:expectedImgNumber];
    for (WIKAnimationFrame *frame in frames) {
        const __auto_type duration = (NSUInteger) trunc(frame.duration * 1000.0);
        NSInteger repeatCount = 0 < gcd ? duration / gcd : 1;
        do {
            [images addObject:frame.image];
        } while (--repeatCount > 0);
    }
    __auto_type animatedImage = [UIImage animatedImageWithImages:images duration:fullDuration];
    animatedImage.webpLoopCount = MAX(loopCountValue, 0);
    return animatedImage;
}

@end

@implementation UIImage (WebpEncoder)

- (NSArray<WIKAnimationFrame *> *)getFrames {
    if (0 == self.images.count) {
        return @[];
    }
    WIKAnimationFrame *frame;
    const NSTimeInterval imageDuration = self.duration / self.images.count;
    NSMutableArray<WIKAnimationFrame *> *result = [NSMutableArray arrayWithCapacity:self.images.count];
    UIImage *currentImg = self.images.firstObject;
    NSTimeInterval currentDuration = imageDuration;
    for (NSUInteger imgIdx = 1; imgIdx < self.images.count; ++imgIdx) {
        UIImage *image = self.images[imgIdx];
        if (image == currentImg) {
            currentDuration+= imageDuration;
            continue;
        }
        if ((frame = [[WIKAnimationFrame alloc] initWithImage:currentImg duration:currentDuration])) {
            [result addObject:frame];
        }
        currentImg = image;
        currentDuration = imageDuration;
    }
    if ((frame = [[WIKAnimationFrame alloc] initWithImage:currentImg duration:currentDuration])) {
        [result addObject:frame];
    }
    return result;
}

- (nullable NSData *)webpDataWithConfig:(WIKEncoderConfig * const)config {
    if (!config) {
        return nil;
    }
    __auto_type frames = [self getFrames];
    if (0 == frames.count) {
        return (__bridge_transfer NSData *)webpCreateDataFromCGImage(self.CGImage, config);
    }
    return [UIImage webpDataWithAnimationFrames:frames config:config loopCount:self.webpLoopCount];
}

+ (nullable NSData *)webpDataWithAnimationFrames:(NSArray<WIKAnimationFrame *> * const)frames
                                       andConfig:(WIKEncoderConfig * const)config {
    return [self webpDataWithAnimationFrames:frames config:config loopCount:1];
}

+ (nullable NSData *)webpDataWithAnimationFrames:(NSArray<WIKAnimationFrame *> * const)frames
                                          config:(WIKEncoderConfig * const)config
                                       loopCount:(const NSUInteger)loopCount {
    WebPMux *mux;
    if (!(mux = WebPMuxNew())) {
        return nil;
    }
    for (WIKAnimationFrame *frame in frames) {
        NSData *webpData;
        if (!(webpData = (__bridge_transfer NSData *) webpCreateDataFromCGImage(frame.image.CGImage, config))) {
            return nil;
        }
        int duration = (int)trunc(frame.duration * 1000);
        WebPMuxFrameInfo frameInfo = {
                .bitstream.bytes = webpData.bytes,
                .bitstream.size = webpData.length,
                .duration = duration,
                .id = WEBP_CHUNK_ANMF,
                .dispose_method = WEBP_MUX_DISPOSE_BACKGROUND, // each frame will clear canvas
                .blend_method = WEBP_MUX_NO_BLEND
        };
        if (WEBP_MUX_OK != WebPMuxPushFrame(mux, &frameInfo, 0)) {
            WebPMuxDelete(mux);
            return nil;
        }
    }
    WebPMuxAnimParams params = {
            .bgcolor = 0,
            .loop_count = (int)loopCount
    };
    if (WEBP_MUX_OK != WebPMuxSetAnimationParams(mux, &params)) {
        WebPMuxDelete(mux);
        return nil;
    }

    WebPData outputData;
    WebPMuxError error = WebPMuxAssemble(mux, &outputData);
    WebPMuxDelete(mux);
    if (error != WEBP_MUX_OK) {
        return nil;
    }
    NSData *imageData = [NSData dataWithBytes:outputData.bytes length:outputData.size];
    WebPDataClear(&outputData);
    return imageData;
}

@end

@implementation UIImage (WebpAnyImage)

+ (nullable instancetype)webpAnyImageWithData:(NSData *const)data {
    if (data.webpIsImage) {
        return [UIImage webpImageWithData:data];
    }
    return [UIImage imageWithData:data];
}

@end

CGSize scaledImageSize(const CGSize imgSize, const CGSize targetSize, const CGFloat scaleFactor) {
    __auto_type rWidth = imgSize.width;
    __auto_type rHeight = imgSize.height;
    if (targetSize.width > 0.0 && targetSize.height > 0.0) {
        const __auto_type tWidth = targetSize.width * MAX(1.0, scaleFactor);
        const __auto_type tHeight = targetSize.height * MAX(1.0, scaleFactor);
        const __auto_type sRatio = imgSize.width / imgSize.height;
        const __auto_type tRatio = tWidth / tHeight;
        if (sRatio > tRatio) {
            rWidth = tWidth;
            rHeight = ceil(tWidth / sRatio);
        }
        else {
            rHeight = tHeight;
            rWidth = ceil(tHeight * sRatio);
        }
        rWidth = MIN(imgSize.width, rWidth);
        rHeight = MIN(imgSize.height, rHeight);
    }
    return CGSizeMake(rWidth, rHeight);
}

@implementation UIImage (WebPA)

- (NSUInteger)webpLoopCount {
    NSNumber *value = objc_getAssociatedObject(self, kLoopCountKey);
	if (nil == value) {
        return (0 < self.images.count ? 1 : NSNotFound);
	}
    return [value unsignedIntegerValue];
}

- (void)setWebpLoopCount:(NSUInteger)count {
    objc_setAssociatedObject(self, kLoopCountKey, @(count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

static NSUInteger gcdIn(NSUInteger a, NSUInteger b) {
    NSUInteger c;
    while (a != 0) {
        c = a;
        a = b % a;
        b = c;
    }
    return b;
}

static NSUInteger gcdOf(size_t const count, NSUInteger const * const values) {
    if (count == 0 || !values) {
        return 0;
    }
    NSUInteger result = values[0];
    for (size_t i = 1; i < count; ++i) {
        result = gcdIn(values[i], result);
    }
    return result;
}
