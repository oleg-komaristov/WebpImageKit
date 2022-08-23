//
//  UIImage+WebP.h
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-11.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (WebpDecoder)

/**
 * Creates a new UIImage instance from the data in WebP format.
 *
 * @param data
 *        Image data in WebP format.
 * @return New image or nil if decoding failed or format version unsupported.
 */
+ (nullable instancetype)webpImageWithData:(NSData * const)data;

/**
 * Creates a new UIImage instance from the data in WebP format. Provide visible size,
 * in case it images size is much bigger than the displaying size. Usage of this option
 * can decrease the amount of used memory.
 *
 * @param data
 *        Image data in WebP format.
 * @param size
 *        Size of the result image in pixels.
 * @return New image or nil if decoding failed or format version unsupported.
 */
+ (nullable instancetype)webpImageWithData:(NSData * const)data
                               displaySize:(const CGSize)size;

/**
 * Creates a new UIImage instance from the data in WebP format. The resulting image will
 * have a given size and scale factor.
 * @warning This method expects the size of the resulting image in points not in
 *          pixels as `webpImageWithData:displaySize:` method.
 *
 * @param data
 *        Image data in WebP format.
 * @param size
 *        Size of the result image in points.
 * @param scaleFactor
 *        The scale factor of the output image.
 * @return New image or nil if decoding failed or format version unsupported.
 */
+ (nullable instancetype)webpImageWithData:(NSData * const)data
                               displaySize:(const CGSize)size
                               scaleFactor:(const CGFloat)scaleFactor;

/**
 * Creates a new UIImage instance from the data in WebP format. The resulting image will
 * have a given size and scale factor. Returns number of loops animation should be played
 * in the `loopCount` parameter.
 * @warning This method expects the size of the resulting image in points not in
 *          pixels as `webpImageWithData:displaySize:` method.
 *
 * @param data
 *        Image data in WebP format.
 * @param size
 *        Size of the result image in points.
 * @param scaleFactor
 *        The scale factor of the output image.
 * @param loopCount
 *        The number of loops to play for animated images (NSNotFound in case of normal image).
 * @return New image or nil if decoding failed or format version unsupported.
 */
+ (nullable instancetype)webpImageWithData:(NSData *const)data
                               displaySize:(const CGSize)size
                               scaleFactor:(const CGFloat)scaleFactor
                                 loopCount:(NSUInteger * __nullable)loopCount;

@end

@class WIKEncoderConfig, WIKAnimationFrame;

@interface UIImage (WebpEncoder)

/**
 * Encodes the image using the given encoder settings.
 *
 * @param config
 *        Encoder settings.
 * @return NSData object contains encoded image data or nil, if failed.
 */
- (nullable NSData *)webpDataWithConfig:(WIKEncoderConfig * const)config;

/**
 * Encodes frames as an animated Webp image using the given encoder settings.
 *
 * @param config
 *        Encoder settings.
 * @return NSData object contains encoded image data or nil, if failed.
 */
+ (nullable NSData *)webpDataWithAnimationFrames:(NSArray<WIKAnimationFrame *> * const)frames
                                       andConfig:(WIKEncoderConfig * const)config;

/**
 * Encodes frames as an animated Webp image using the given encoder settings and loop count.
 *
 * @param config
 *        Encoder settings.
 * @param loopCount
 *        The number of loops for the animation.
 * @return NSData object contains encoded image data or nil, if failed.
 */
+ (nullable NSData *)webpDataWithAnimationFrames:(NSArray<WIKAnimationFrame *> * const)frames
                                          config:(WIKEncoderConfig * const)config
                                       loopCount:(const NSUInteger)loopCount;

@end

@interface UIImage (WebPA)

/**
 * The number of animation cycles to play. For non-animated images, this value is NSNotFound.
 */
@property (nonatomic) NSUInteger webpLoopCount;

@end

@interface UIImage (WebpAnyImage)

/**
 * Creates instance of UIImage from data in WebP format or any other format supported by the UIKit.
 *
 * @param data
 *        Image data in WebP or any UIKit-supported format.
 * @return New image or nil if decoding failed.
 */
+ (nullable instancetype)webpAnyImageWithData:(NSData * const)data;

@end

NS_ASSUME_NONNULL_END
