//
//  WIKEncoderConfig.h
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-22.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Encoder configuration. By default, all values are nil, and only non-nil
 * values are applied to the encoder configuration.
 */
@interface WIKEncoderConfig: NSObject

@property (nonatomic, readonly, nullable) NSNumber *method;             // 0 (fast) - 6 (slower/better)
@property (nonatomic, readonly, nullable) NSNumber *passes;             // number of entropy-analysis passes (in [1..10])
@property (nonatomic, readonly, nullable) NSNumber *preprocessing;      // 0 - none, 1 - segment-smooth
@property (nonatomic, readonly, nullable) NSNumber *targetPSNR;         // float, if non-zero, specifies the minimal distortion to try to achieve. Takes precedence over target_size.
@property (nonatomic, readonly, nullable) NSNumber *threadLevel;        // if non-zero, try and use multithreaded encoding.
@property (nonatomic, readonly, nullable) NSNumber *lowMemory;          // if set, reduce memory usage (but increase CPU use).
@property (nonatomic, readonly, nullable) NSNumber *segments;           // maximum number of segments to use, in [1..4]
@property (nonatomic, readonly, nullable) NSNumber *snsStrength;        // Spatial Noise Shaping. 0=off, 100=maximum.
@property (nonatomic, readonly, nullable) NSNumber *filterStrength;     // range: [0 = off .. 100 = strongest]
@property (nonatomic, readonly, nullable) NSNumber *filterSharpness;    // range: [0 = off .. 7 = least sharp]
@property (nonatomic, readonly, nullable) NSNumber *filterType;         // 0 - simple, 1 - strong (only if 0 < filterStrength or 0 < autoFilter)
@property (nonatomic, readonly, nullable) NSNumber *alphaCompression;   // algorithm for encoding the alpha plane (0 = none, 1 = WebP lossless)
@property (nonatomic, readonly, nullable) NSNumber *autoFilter;         // auto adjust filter's strength [0 = off, 1 = on]
@property (nonatomic, readonly, nullable) NSNumber *alphaFiltering;     // predictive filtering method for alpha plane (0 - none, 1 - fast, 2 - best)
@property (nonatomic, readonly, nullable) NSNumber *alphaQuality;       // 0 (smallest) - 100 (lossless)
@property (nonatomic, readonly, nullable) NSNumber *showCompressed;     // if true, export the compressed picture back; in-loop filtering is not applied
@property (nonatomic, readonly, nullable) NSNumber *partitions;         // log2(number of token partitions) in [0..3]
@property (nonatomic, readonly, nullable) NSNumber *partitionLimit;     // 0 (no degradation) - 100 (max degradation)
@property (nonatomic, readonly, nullable) NSNumber *sharpYuv;           // if needed, use sharp (and slow) RGB->YUV conversion

@end

typedef NS_ENUM(NSInteger, WIKContentHint) {
    WIKContentHintDefault = 0,  // default preset.
    WIKContentHintPicture,      // digital picture, like portrait, inner shot
    WIKContentHintPhoto,        // outdoor photograph, with natural lighting
    WIKContentHintGraph,        // Discrete tone image (graph, map-tile etc).
};

typedef NS_ENUM(NSInteger, WIKPreset) {
    WIKPresetDefault = 0,  // default preset.
    WIKPresetPicture,      // digital picture, like portrait, inner shot
    WIKPresetPhoto,        // outdoor photograph, with natural lighting
    WIKPresetDrawing,      // hand or line drawing, with high-contrast details
    WIKPresetIcon,         // small-sized colorful images
    WIKPresetText          // text-like
};

typedef NS_ENUM(NSInteger, WIKFilterType) {
    WIKFilterTypeSimple,
    WIKFilterTypeStrong
};

typedef NS_ENUM(NSInteger, WIKAlphaFilterType) {
    WIKAlphaFilterTypeNone,
    WIKAlphaFilterTypeFast,
    WIKAlphaFilterTypeBest
};

@interface WIKEncoderConfigBuilder: NSObject

+ (instancetype)builderWithImageQuality:(const float)quality;
+ (instancetype)builderWithFileSize:(const NSUInteger)bytesSize;

/**
 * Creates encoder configuration builder with limited image quality.
 *
 * @param quality
 *        Target image quality should be between 0.0 and 1.0.
 * @param contentHint
 *        Hint about image content for WebP encoder.
 * @return New builder instance.
 */
- (instancetype)initWithTargetImageQuality:(const float)quality
                                    preset:(const WIKPreset)preset
                               contentHint:(const WIKContentHint)contentHint;

/**
 * Creates encoder configuration builder with limited image size.
 *
 * @param bytesSize
 *        Maximum size of the encoded image in bytes.
 * @param contentHint
 *        Hint about image content for WebP encoder.
 * @return New builder instance.
 */
- (instancetype)initWithTargetFileSize:(const NSUInteger)bytesSize
                                preset:(const WIKPreset)preset
                           contentHint:(const WIKContentHint)contentHint;

/**
 * Sets the maximum size of the image in pixels to pre-scale bigger images
 * before encoding. Preserve ratio while scaling.
 *
 * @param size
 *        Maximum size to encode.
 * @return New builder instance.
 */
- (WIKEncoderConfigBuilder *)setMaxPixelSize:(const CGSize)size;

- (WIKEncoderConfigBuilder *)setMethod:(const int)value;
- (WIKEncoderConfigBuilder *)setPasses:(const int)value;
- (WIKEncoderConfigBuilder *)setPreprocessing:(const BOOL)value;
- (WIKEncoderConfigBuilder *)setTargetPSNR:(const float)value;
- (WIKEncoderConfigBuilder *)setThreadLevel:(const int)value;
- (WIKEncoderConfigBuilder *)setLowMemory:(const BOOL)value;
- (WIKEncoderConfigBuilder *)setSegments:(const int)value;
- (WIKEncoderConfigBuilder *)setSnsStrength:(const int)value;
- (WIKEncoderConfigBuilder *)setFilterStrength:(const int)value;
- (WIKEncoderConfigBuilder *)setFilterSharpness:(const int)value;
- (WIKEncoderConfigBuilder *)setFilterType:(const WIKFilterType)value;
- (WIKEncoderConfigBuilder *)setAlphaCompression:(const BOOL)value;
- (WIKEncoderConfigBuilder *)setAutoFilter:(const BOOL)value;
- (WIKEncoderConfigBuilder *)setAlphaFiltering:(const WIKAlphaFilterType)value;
- (WIKEncoderConfigBuilder *)setAlphaQuality:(const int)value;
- (WIKEncoderConfigBuilder *)setShowCompressed:(const BOOL)value;
- (WIKEncoderConfigBuilder *)setPartitions:(const int)value;
- (WIKEncoderConfigBuilder *)setPartitionLimit:(const int)value;
- (WIKEncoderConfigBuilder *)setSharpYuv:(const BOOL)value;

- (WIKEncoderConfig *)construct;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
