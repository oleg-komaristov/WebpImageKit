//
//  CoreGraphics+WebP.m
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-11.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <UIKit/UIKit.h>

#import "CoreGraphics+WebP.h"
#import "WebpImageKitMacro.h"
#import "WIKEncoderConfig+Internal.h"

CGColorSpaceRef __nonnull webpSharedDeviceColorSpace(void) {
    static dispatch_once_t onceToken;
    static CGColorSpaceRef colorSpace = NULL;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    });
    return colorSpace;
}

NS_INLINE size_t webpByteAlign(size_t size, size_t alignment) {
    return ((size + (alignment - 1)) / alignment) * alignment;
}

static void FreeWebpOutputBuffer(__unused void *info, const void *data, __unused size_t size) {
    if (!data) { return; }
    free((void *) data);
}

CGColorSpaceRef __nonnull webpCreateColorSpace(WebPDemuxer * __nonnull demuxer) CF_RETURNS_RETAINED {
    CGColorSpaceRef colorSpace = NULL;
    uint32_t flags = WebPDemuxGetI(demuxer, WEBP_FF_FORMAT_FLAGS);
    if (flags & ICCP_FLAG) {
        WebPChunkIterator chunkIterator;
        if (WebPDemuxGetChunk(demuxer, "ICCP", 1, &chunkIterator)) {
            __auto_type profileDataRef = CFDataCreate(NULL, chunkIterator.chunk.bytes, chunkIterator.chunk.size);
            colorSpace = CGColorSpaceCreateWithICCData(profileDataRef);
            CFRelease(profileDataRef);
            WebPDemuxReleaseChunkIterator(&chunkIterator);
            if (colorSpace && kCGColorSpaceModelRGB != CGColorSpaceGetModel(colorSpace)) {
                CFRelease(colorSpace);
                colorSpace = NULL;
            }
        }
    }
    if (!colorSpace) {
        colorSpace = webpCreateDeviceRgbColorSpace();
    }
    return colorSpace;
}

CGColorSpaceRef __nonnull webpCreateDeviceRgbColorSpace(void) CF_RETURNS_RETAINED {
    CFRetain(webpSharedDeviceColorSpace());
    return webpSharedDeviceColorSpace();
}

CGImageRef __nullable webpCreateCGImage(WebPData webpData,
                                        CGColorSpaceRef __nonnull colorSpace,
                                        CGSize targetSize) CF_RETURNS_RETAINED {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return NULL;
    }
    if (VP8_STATUS_OK != WebPGetFeatures(webpData.bytes, webpData.size, &config.input)) {
        return NULL;
    }
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= config.input.has_alpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    config.options.use_threads = 1;
    config.output.colorspace = MODE_bgrA;
    if (0 < targetSize.width && 0 < targetSize.height) {
        config.options.use_scaling = 1;
        config.options.scaled_width = (int)trunc(targetSize.width);
        config.options.scaled_height = (int)trunc(targetSize.height);
    }

    if (VP8_STATUS_OK != WebPDecode(webpData.bytes, webpData.size, &config)) {
        return NULL;
    }

    __auto_type dataProvider = CGDataProviderCreateWithData(&config.output,
                                                            config.output.u.RGBA.rgba,
                                                            config.output.u.RGBA.size,
                                                            FreeWebpOutputBuffer);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = (size_t) config.output.u.RGBA.stride;
    size_t width = (size_t) config.output.width;
    size_t height = (size_t) config.output.height;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef image = CGImageCreate(width, height,
                                     bitsPerComponent,
                                     bitsPerPixel,
                                     bytesPerRow,
                                     colorSpace,
                                     bitmapInfo,
                                     dataProvider,
                                     NULL,
                                     NO,
                                     renderingIntent);
    CGDataProviderRelease(dataProvider);
    return image;
}

CGImageRef __nullable webpCreateScaledCGImage(CGImageRef __nonnull sourceImg, CGSize size) CF_RETURNS_RETAINED {
    NSCParameterAssert(sourceImg);
    __auto_type width = CGImageGetWidth(sourceImg);
    __auto_type height = CGImageGetHeight(sourceImg);
    if (width == size.width && height == size.height) {
        CGImageRetain(sourceImg);
        return sourceImg;
    }
    __block vImage_Buffer input_buffer = {}, output_buffer = {};
    @webp_defer {
        if (input_buffer.data) free(input_buffer.data);
        if (output_buffer.data) free(output_buffer.data);
    };
    CGBitmapInfo bitmapInfo;
    if (webpCGImageContainsAlpha(sourceImg)) {
        bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
    }
    else {
        bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
    }
    vImage_CGImageFormat format = (vImage_CGImageFormat) {
            .bitsPerComponent = 8,
            .bitsPerPixel = 32,
            .colorSpace = NULL,
            .bitmapInfo = bitmapInfo,
            .version = 0,
            .decode = NULL,
            .renderingIntent = CGImageGetRenderingIntent(sourceImg)
    };

    vImage_Error a_ret = vImageBuffer_InitWithCGImage(&input_buffer, &format, NULL, sourceImg, kvImageNoFlags);
    if (a_ret != kvImageNoError) return NULL;
    output_buffer.width = MAX((vImagePixelCount) trunc(size.width), 0);
    output_buffer.height = MAX((vImagePixelCount) trunc(size.height), 0);
    output_buffer.rowBytes = webpByteAlign(output_buffer.width * 4, 64);
    output_buffer.data = malloc(output_buffer.rowBytes * output_buffer.height);
    if (!output_buffer.data) {
        return NULL;
    }

    vImage_Error ret = vImageScale_ARGB8888(&input_buffer, &output_buffer, NULL, kvImageHighQualityResampling);
    if (kvImageNoError != ret) {
        return NULL;
    }
    CGImageRef outputImg = vImageCreateCGImageFromBuffer(&output_buffer, &format, NULL, NULL, kvImageNoFlags, &ret);
    if (kvImageNoError != ret) {
        CGImageRelease(outputImg);
        return NULL;
    }
    return outputImg;
}

NS_INLINE BOOL webpHasAlpha(CGImageAlphaInfo alphaInfo) {
    return alphaInfo != kCGImageAlphaNone
            && alphaInfo != kCGImageAlphaNoneSkipFirst
            && alphaInfo != kCGImageAlphaNoneSkipLast;
}

BOOL webpCGImageContainsAlpha(CGImageRef __nonnull const cgImage) {
    NSCParameterAssert(cgImage);
    if (!cgImage) { return NO; }
    return webpHasAlpha(CGImageGetAlphaInfo(cgImage));
}

CFDataRef __nullable webpCreateDataFromCGImage(CGImageRef __nonnull imageRef,
                                              WIKEncoderConfig * const __nonnull config) CF_RETURNS_RETAINED {
    const size_t width = CGImageGetWidth(imageRef);
    const size_t height = CGImageGetHeight(imageRef);
    if (0 >= width || 0 >= height || !config) {
        return NULL;
    }
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    const size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    const size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    const size_t components = bitsPerPixel / bitsPerComponent;
    __auto_type bitmapInfo = CGImageGetBitmapInfo(imageRef);
    const CGImageAlphaInfo alphaInfo = (CGImageAlphaInfo) (bitmapInfo & kCGBitmapAlphaInfoMask);
    const CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    const BOOL hasAlpha = webpHasAlpha(alphaInfo);
    BOOL byteOrderNormal;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault:
            byteOrderNormal = YES;
            break;
        case kCGBitmapByteOrder32Big:
            byteOrderNormal = YES;
            break;
        case kCGBitmapByteOrder32Little:
        default:
            byteOrderNormal = NO;
            break;
    }
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    if (!dataProvider) {
        return NULL;
    }
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    BOOL isRGB = CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelRGB;
    CFDataRef dataRef;
    uint8_t *rgba = NULL;
    BOOL isRGB888 = isRGB && byteOrderNormal && alphaInfo == kCGImageAlphaNone && components == 3;
    BOOL isRGBA8888 = isRGB && byteOrderNormal && alphaInfo == kCGImageAlphaLast && components == 4;
    if (isRGB888 || isRGBA8888) {
        if (!(dataRef = CGDataProviderCopyData(dataProvider))) {
            return NULL;
        }
        rgba = (uint8_t *)CFDataGetBytePtr(dataRef);
    }
    else {
        vImageConverterRef convertor = NULL;
        vImage_Error error = kvImageNoError;

        vImage_CGImageFormat srcFormat = {
                .bitsPerComponent = (uint32_t)bitsPerComponent,
                .bitsPerPixel = (uint32_t)bitsPerPixel,
                .colorSpace = colorSpace,
                .bitmapInfo = bitmapInfo,
                .renderingIntent = CGImageGetRenderingIntent(imageRef)
        };
        vImage_CGImageFormat destFormat = {
                .bitsPerComponent = 8,
                .bitsPerPixel = hasAlpha ? 32 : 24,
                .colorSpace = webpSharedDeviceColorSpace(),
                .bitmapInfo = (CGBitmapInfo) ((hasAlpha ? kCGImageAlphaLast : kCGImageAlphaNone) | kCGBitmapByteOrderDefault)
        };
        convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, &destFormat, NULL, kvImageNoFlags, &error);
        if (!convertor || kvImageNoError != error) {
            return NULL;
        }
        @webp_defer {
            vImageConverter_Release(convertor);
        };
        vImage_Buffer src;
        if (kvImageNoError != vImageBuffer_InitWithCGImage(&src, &srcFormat, nil, imageRef, kvImageNoFlags)) {
            return NULL;
        }
        vImage_Buffer dest;
        @webp_defer {
            free(src.data);
        };
        if (kvImageNoError != vImageBuffer_Init(&dest, height, width, destFormat.bitsPerPixel, kvImageNoFlags)) {
            return NULL;
        }
        if (kvImageNoError != vImageConvert_AnyToAny(convertor, &src, &dest, NULL, kvImageNoFlags)) {
            return NULL;
        }
        rgba = dest.data;
        bytesPerRow = dest.rowBytes;
        dataRef = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, rgba, bytesPerRow * height, kCFAllocatorDefault);
    }
    @webp_defer {
        CFRelease(dataRef);
    };
    WebPConfig webpConfig;
    if (![config setupWebpEncoderConfiguration:&webpConfig]) {
        return NULL;
    }

    WebPPicture *picture = calloc(1, sizeof(WebPPicture));
    if (!picture || !WebPPictureInit(picture)) {
        if (picture) free(picture);
        return NULL;
    }
    @webp_defer {
        WebPPictureFree(picture);
        free(picture);
    };
    WebPMemoryWriter *writer = calloc(1, sizeof(WebPMemoryWriter));
    if (!writer) {
        return NULL;
    }
    WebPMemoryWriterInit(writer);
    @webp_defer {
        WebPMemoryWriterClear(writer);
        free(writer);
    };
    picture->use_argb = 0;
    picture->width = (int)width;
    picture->height = (int)height;
    picture->writer = WebPMemoryWrite;
    picture->custom_ptr = writer;
    if ((hasAlpha && !WebPPictureImportRGBA(picture, rgba, (int)bytesPerRow))
        || (!hasAlpha && !WebPPictureImportRGB(picture, rgba, (int)bytesPerRow))) {
        return NULL;
    }

    if (config.maxPixelSize) {
        __auto_type maxSize = [config.maxPixelSize CGSizeValue];
        __auto_type currentRatio = width / height;
        __auto_type maxRatio = maxSize.width / maxSize.height;
        CGFloat targetWidth, targetHeight;
        if (currentRatio > maxRatio) {
            targetWidth = MIN(width, maxSize.width);
            targetHeight = ceil(targetWidth / currentRatio);
        }
        else {
            targetHeight = MIN(height, maxSize.height);
            targetWidth = ceil(targetHeight * currentRatio);
        }
        __auto_type currentSize = CGSizeMake(width, height);
        __auto_type targetSize = CGSizeMake(targetWidth, targetHeight);
        if (!CGSizeEqualToSize(currentSize, targetSize)
                && !WebPPictureRescale(picture, (int) targetSize.width, (int) targetSize.height)) {
            return NULL;
        }
    }

    if (!WebPEncode(&webpConfig, picture)) {
        return NULL;
    }
    return CFDataCreate(CFAllocatorGetDefault(), writer->mem, writer->size);
}
