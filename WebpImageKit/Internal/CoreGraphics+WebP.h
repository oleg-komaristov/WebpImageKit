//
//  CoreGraphics+WebP.h
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-11.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#ifndef CoreGraphics_WebP_h
#define CoreGraphics_WebP_h

#import <libwebp/demux.h>
#import <libwebp/decode.h>
#import <CoreGraphics/CoreGraphics.h>

@class WIKEncoderConfig;

extern CGColorSpaceRef __nonnull webpCreateColorSpace(WebPDemuxer * __nonnull demuxer) CF_RETURNS_RETAINED;
extern CGColorSpaceRef __nonnull webpCreateDeviceRgbColorSpace(void) CF_RETURNS_RETAINED;

extern CGImageRef __nullable webpCreateCGImage(WebPData webpData,
                                               CGColorSpaceRef __nonnull colorSpace,
                                               CGSize targetSize) CF_RETURNS_RETAINED;
extern CGImageRef __nullable webpCreateScaledCGImage(CGImageRef __nonnull sourceImg, CGSize size) CF_RETURNS_RETAINED;

extern BOOL webpCGImageContainsAlpha(CGImageRef __nonnull const cgImage);

extern CFDataRef __nullable webpCreateDataFromCGImage(CGImageRef __nonnull imageRef,
                                                     WIKEncoderConfig * const __nonnull config) CF_RETURNS_RETAINED;

#endif /* CoreGraphics_WebP_h */
