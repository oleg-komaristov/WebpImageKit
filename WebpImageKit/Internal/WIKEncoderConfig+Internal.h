//
//  WIKEncoderConfig+Internal.h
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-22.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libwebp/encode.h>
#import "WIKEncoderConfig.h"

@interface WIKEncoderConfig () {
@public
    WIKEncoderMode _mode;
    WIKPreset _preset;
    WIKContentHint _contentHint;
    NSNumber *_quality;
    NSNumber *_fileSize;
    NSValue *_maxPixelSize;
    NSNumber *_qmin;
    NSNumber *_qmax;

    NSNumber *_method;
    NSNumber *_passes;
    NSNumber *_preprocessing;
    NSNumber *_targetPSNR;
    NSNumber *_threadLevel;
    NSNumber *_lowMemory;
    NSNumber *_segments;
    NSNumber *_snsStrength;
    NSNumber *_filterStrength;
    NSNumber *_filterSharpness;
    NSNumber *_filterType;
    NSNumber *_alphaCompression;
    NSNumber *_autoFilter;
    NSNumber *_alphaFiltering;
    NSNumber *_alphaQuality;
    NSNumber *_showCompressed;
    NSNumber *_partitions;
    NSNumber *_partitionLimit;
    NSNumber *_sharpYuv;
}

@property (nonatomic, readonly, nullable) NSNumber *targetQuality;
@property (nonatomic, readonly, nullable) NSNumber *targetFileSize;

@property (nonatomic, readonly, nullable) NSValue *maxPixelSize;

- (BOOL)setupWebpEncoderConfiguration:(nonnull WebPConfig *)config;

- (nullable WIKEncoderConfig *)initWithQuality:(int)quality andPreset:(WIKPreset)preset;

@end
