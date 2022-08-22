//
//  WIKEncoderConfig.m
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-22.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WIKEncoderConfig.h"
#import "WIKEncoderConfig+Internal.h"

@implementation WIKEncoderConfig
@synthesize targetQuality = _quality;
@synthesize targetFileSize = _fileSize;
@synthesize maxPixelSize = _maxPixelSize;
@synthesize method = _method;
@synthesize passes = _passes;
@synthesize preprocessing = _preprocessing;
@synthesize targetPSNR = _targetPSNR;
@synthesize threadLevel = _threadLevel;
@synthesize lowMemory = _lowMemory;
@synthesize segments = _segments;
@synthesize snsStrength = _snsStrength;
@synthesize filterStrength = _filterStrength;
@synthesize filterSharpness = _filterSharpness;
@synthesize filterType = _filterType;
@synthesize alphaCompression = _alphaCompression;
@synthesize autoFilter = _autoFilter;
@synthesize alphaFiltering = _alphaFiltering;
@synthesize alphaQuality = _alphaQuality;
@synthesize showCompressed = _showCompressed;
@synthesize partitions = _partitions;
@synthesize partitionLimit = _partitionLimit;
@synthesize sharpYuv = _sharpYuv;

- (WebPPreset)webpPreset {
    WebPPreset result;
    switch (_preset) {
        case WIKPresetPicture:
            result = WEBP_PRESET_PICTURE;
            break;
        case WIKPresetPhoto:
            result = WEBP_PRESET_PHOTO;
            break;
        case WIKPresetDrawing:
            result = WEBP_PRESET_DRAWING;
            break;
        case WIKPresetIcon:
            result = WEBP_PRESET_ICON;
            break;
        case WIKPresetText:
            result = WEBP_PRESET_TEXT;
            break;
        default:
            result = WEBP_PRESET_DEFAULT;
            break;
    }
    return result;
}

- (WebPImageHint)imageHint {
    WebPImageHint result;
    switch (_contentHint) {
        case WIKContentHintPicture:
            result = WEBP_HINT_PICTURE;
            break;
        case WIKContentHintPhoto:
            result = WEBP_HINT_PHOTO;
            break;
        case WIKContentHintGraph:
            result = WEBP_HINT_GRAPH;
            break;
        default:
            result = WEBP_HINT_DEFAULT;
            break;
    }
    return result;
}

- (BOOL)setupWebpEncoderConfiguration:(WebPConfig *)config {

    if (!config || !WebPConfigPreset(config, self.webpPreset, self.targetQuality.intValue)) {
        return NO;
    }
    const __auto_type hint = self.imageHint;
    if (WEBP_HINT_DEFAULT != hint) {
        config->image_hint = hint;
    }
    if (nil != self.targetFileSize) {
        config->target_size = [self.targetFileSize intValue];
        config->pass = 6;
    }
    else {
        config->pass = 1;
    }

    if (nil != self.method) {
        config->method = self.method.intValue;
    }
    if (nil != self.passes) {
        config->pass = self.passes.intValue;
    }
    if (nil != self.preprocessing) {
        config->preprocessing = self.preprocessing.intValue;
    }
    if (nil != self.targetPSNR) {
        config->target_PSNR = self.targetPSNR.floatValue;
    }
    if (nil != self.threadLevel) {
        config->thread_level = self.threadLevel.intValue;
    }
    if (nil != self.lowMemory) {
        config->low_memory = self.lowMemory.intValue;
    }
    if (nil != self.segments) {
        config->segments = self.segments.intValue;
    }
    if (nil != self.snsStrength) {
        config->sns_strength = self.snsStrength.intValue;
    }
    if (nil != self.filterStrength) {
        config->filter_strength = self.filterStrength.intValue;
    }
    if (nil != self.filterSharpness) {
        config->filter_sharpness = self.filterSharpness.intValue;
    }
    if (nil != self.filterType) {
        config->filter_type = self.filterType.intValue;
    }
    if (nil != self.alphaCompression) {
        config->alpha_compression = self.alphaCompression.intValue;
    }
    if (nil != self.autoFilter) {
        config->autofilter = self.autoFilter.intValue;
    }
    if (nil != self.alphaFiltering) {
        config->alpha_filtering = self.alphaFiltering.intValue;
    }
    if (nil != self.alphaQuality) {
        config->alpha_quality = self.alphaQuality.intValue;
    }
    if (nil != self.showCompressed) {
        config->show_compressed = self.showCompressed.intValue;
    }
    if (nil != self.partitions) {
        config->partitions = self.partitions.intValue;
    }
    if (nil != self.partitionLimit) {
        config->partition_limit = self.partitionLimit.intValue;
    }
    if (nil != self.sharpYuv) {
        config->use_sharp_yuv = self.sharpYuv.intValue;
    }
    return 0 < WebPValidateConfig(config);
}

@end

@implementation WIKEncoderConfigBuilder {
@private
    WIKEncoderConfig *_config;
}

+ (instancetype)builderWithImageQuality:(const float)quality {
    return [[self alloc] initWithTargetImageQuality:quality preset:WIKPresetDefault contentHint:WIKContentHintDefault];
}

+ (instancetype)builderWithFileSize:(const NSUInteger)bytesSize {
    return [[self alloc] initWithTargetFileSize:bytesSize preset:WIKPresetDefault contentHint:WIKContentHintDefault];
}

- (instancetype)initWithTargetImageQuality:(const float)quality
                                    preset:(const WIKPreset)preset
                               contentHint:(const WIKContentHint)contentHint {
    if (self = [super init]) {
        _config = [WIKEncoderConfig new];
        _config->_preset = preset;
        _config->_contentHint = contentHint;
        _config->_quality = @((int)trunc(MAX(MIN(quality, 1.0), 0.0) * 100));
    }
    return self;
}

- (instancetype)initWithTargetFileSize:(const NSUInteger)bytesSize
                                preset:(const WIKPreset)preset
                           contentHint:(const WIKContentHint)contentHint {
    if (self = [super init]) {
        _config = [WIKEncoderConfig new];
        _config->_preset = preset;
        _config->_contentHint = contentHint;
        _config->_fileSize = @(bytesSize);
    }
    return self;
}

- (WIKEncoderConfigBuilder *)setMaxPixelSize:(const CGSize)size {
    _config->_maxPixelSize = [NSValue valueWithCGSize:size];
    return self;
}

- (WIKEncoderConfigBuilder *)setMethod:(const int)value {
    _config->_method = @(MAX(MIN(value, 6), 0));
    return self;
}

- (WIKEncoderConfigBuilder *)setPasses:(const int)value {
    _config->_passes = @(MAX(MIN(value, 10), 0));
    return self;
}

- (WIKEncoderConfigBuilder *)setPreprocessing:(const BOOL)value {
    _config->_preprocessing = value ? @1 : @0;
    return self;
}

- (WIKEncoderConfigBuilder *)setTargetPSNR:(const float)value {
    _config->_targetPSNR = @(value);
    return self;
}

- (WIKEncoderConfigBuilder *)setThreadLevel:(const int)value {
    _config->_threadLevel = @(MAX(value, 0));
    return self;
}

- (WIKEncoderConfigBuilder *)setLowMemory:(const BOOL)value {
    _config->_lowMemory = value ? @1 : @0;
    return self;
}

- (WIKEncoderConfigBuilder *)setSegments:(const int)value {
    _config->_segments = @(MAX(MIN(value, 4), 1));
    return self;
}

- (WIKEncoderConfigBuilder *)setSnsStrength:(const int)value {
    _config->_snsStrength = @(MAX(MIN(value, 100), 0));
    return self;
}

- (WIKEncoderConfigBuilder *)setFilterStrength:(const int)value {
    _config->_filterStrength = @(MAX(MIN(value, 100), 0));
    return self;
}

- (WIKEncoderConfigBuilder *)setFilterSharpness:(const int)value {
    _config->_filterSharpness = @(MAX(MIN(value, 7), 0));
    return self;
}

- (WIKEncoderConfigBuilder *)setFilterType:(const WIKFilterType)value {
    switch (value) {
        case WIKFilterTypeSimple:
            _config->_filterType = @0;
            break;
        case WIKFilterTypeStrong:
            _config->_filterType = @1;
            break;
    }
    return self;
}

- (WIKEncoderConfigBuilder *)setAlphaCompression:(const BOOL)value {
    _config->_alphaCompression = value ? @1 : @0;
    return self;
}

- (WIKEncoderConfigBuilder *)setAutoFilter:(const BOOL)value {
    _config->_autoFilter = value ? @1 : @0;
    return self;
}

- (WIKEncoderConfigBuilder *)setAlphaFiltering:(const WIKAlphaFilterType)value {
    switch (value) {
        case WIKAlphaFilterTypeNone:
            _config->_alphaFiltering = @0;
            break;
        case WIKAlphaFilterTypeFast:
            _config->_alphaFiltering = @1;
            break;
        case WIKAlphaFilterTypeBest:
            _config->_alphaFiltering = @2;
            break;
    }
    return self;
}

- (WIKEncoderConfigBuilder *)setAlphaQuality:(const int)value {
    _config->_alphaQuality = @(MAX(MIN(value, 100), 0));
    return self;
}

- (WIKEncoderConfigBuilder *)setShowCompressed:(const BOOL)value {
    _config->_showCompressed = value ? @1 : @0;
    return self;
}

- (WIKEncoderConfigBuilder *)setPartitions:(const int)value {
    _config->_partitions = @(MAX(MIN(value, 3), 0));
    return self;
}

- (WIKEncoderConfigBuilder *)setPartitionLimit:(const int)value {
    _config->_partitionLimit = @(MAX(MIN(value, 100), 0));
    return self;
}

- (WIKEncoderConfigBuilder *)setSharpYuv:(const BOOL)value {
    _config->_method = value ? @1 : @0;
    return self;
}

- (WIKEncoderConfig *)construct {
    return _config;
}

@end
