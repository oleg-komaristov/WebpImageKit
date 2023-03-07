//
//  CGImageWebP.m
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2023-03-07.
//  Copyright © 2023 Oleg Komaristov. All rights reserved.
//

#import "CGImage+WebP.h"
#import "CoreGraphics+WebP.h"
#import "WebpImageKitMacro.h"

CFDataRef __nullable WebpDataCreateFromImage(CGImageRef __nonnull imageRef, WIKEncoderConfig * const __nonnull config) CF_RETURNS_RETAINED {
    if (!imageRef || !config) {
        return NULL;
    }
    return webpCreateDataFromCGImage(imageRef, config);
}

CGImageRef __nullable WebpImageCreateFromData(CFDataRef __nonnull dataRef) CF_RETURNS_RETAINED {
    return WebpImageCreateFromDataWithSize(dataRef, 0);
}

CGImageRef __nullable WebpImageCreateFromDataWithSize(CFDataRef __nonnull dataRef, UInt32 maxDisplaySize) CF_RETURNS_RETAINED {
    if (!WebpIsImageData(dataRef)) {
        return NULL;
    }
    WebPData webpData;
    WebPDataInit(&webpData);
    webpData.bytes = CFDataGetBytePtr(dataRef);
    webpData.size = (size_t) CFDataGetLength(dataRef);
    WebPDemuxer *demuxer;
    if (!(demuxer = WebPDemux(&webpData))) {
        return nil;
    }
    WebPIterator iterator;
    if (!WebPDemuxGetFrame(demuxer, 1, &iterator)) {
        WebPDemuxReleaseIterator(&iterator);
        WebPDemuxDelete(demuxer);
        return NULL;
    }
    __auto_type colorSpace = webpCreateColorSpace(demuxer);
    __auto_type canvasWidth = (size_t) WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
    __auto_type canvasHeight = (size_t) WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    CGSize scaledSize = CGSizeZero;
    if (0 < maxDisplaySize && maxDisplaySize < MAX(canvasWidth, canvasHeight)) {
        const __auto_type originalSize = CGSizeMake(canvasWidth, canvasHeight);
        __auto_type limitedSize = scaledImageSize(originalSize, CGSizeMake(maxDisplaySize, maxDisplaySize), 1.0);
        if (!CGSizeEqualToSize(originalSize, scaledSize)) {
            scaledSize = limitedSize;
        }
    }
    __auto_type image = webpCreateCGImage(iterator.fragment, colorSpace, scaledSize);
    CFRelease(colorSpace);
    WebPDemuxReleaseIterator(&iterator);
    WebPDemuxDelete(demuxer);
    return image;
}

BOOL WebpIsImageData(CFDataRef __nonnull dataRef) {
    UInt8 magicString[12];
    if (!dataRef || CFDataGetLength(dataRef) < sizeof(magicString)) {
        return NO;
    }
    CFDataGetBytes(dataRef, CFRangeMake(0, sizeof(magicString)), magicString);
    const UInt8 prefix[4] = "RIFF";
    const UInt8 suffix[4] = "WEBP";
    return 0 == memcmp(magicString, prefix, sizeof(prefix))
            && 0 == memcmp(magicString + (sizeof(magicString) - sizeof(suffix)), suffix, sizeof(suffix));
}
