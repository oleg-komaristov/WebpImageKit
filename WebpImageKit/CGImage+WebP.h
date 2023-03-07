//
//  CGImage+WebP.h
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2023-03-07.
//  Copyright © 2023 Oleg Komaristov. All rights reserved.
//

#import <Foundation/Foundation.h>

CF_EXTERN_C_BEGIN

@class WIKEncoderConfig;

/**
 * Returns a data object that contains the image in WebP format.
 *
 * @param imageRef
 *        The original image data.
 * @param config
 *        WebP encoder configuration.
 * @return
 *        An image data, or NULL if an error occurs. You are responsible for releasing this object using CFRelease.
 */
CFDataRef __nullable WebpDataCreateFromImage(CGImageRef __nonnull imageRef, WIKEncoderConfig * const __nonnull config) CF_RETURNS_RETAINED;

/**
 * Returns an image object from the binary data in WebP format.
 * @warning This method doesn't support animated images. Use UIImage's methods for animations.
 *
 * @param dataRef
 *        Image data in WebP format.
 * @return
 *        An image object, or NULL if an error occurs. You are responsible for releasing this object using CFRelease.
 */
CGImageRef __nullable WebpImageCreateFromData(CFDataRef __nonnull dataRef) CF_RETURNS_RETAINED;

/**
 * Returns an image object from the binary data in WebP format. The resulting
 * image size is limited to the `maxDimension` value.
 * @warning This method doesn't support animated images. Use UIImage's methods for animations.
 *
 * @param dataRef
 *        Image data in WebP format.
 * @param maxDisplaySize
 *        Maximum size of the image in pixels. For '0' - uses the original image size.
 * @return
 *        An image object, or NULL if an error occurs. You are responsible for releasing this object using CFRelease.
 */
CGImageRef __nullable WebpImageCreateFromDataWithSize(CFDataRef __nonnull dataRef, UInt32 maxDisplaySize) CF_RETURNS_RETAINED;

/**
 * Returns YES if given data contains image in WebP format.
 *
 * @param dataRef
 *        Image data.
 * @return
 *        YES if data contains image in WebP format.
 */
BOOL WebpIsImageData(CFDataRef __nonnull dataRef);

CF_EXTERN_C_END
