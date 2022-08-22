//
//  WIKAnimationFrame.m
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-11.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import "WIKAnimationFrame.h"

@implementation WIKAnimationFrame {
@private
    UIImage *_image;
    NSTimeInterval _duration;
}
@synthesize image = _image;
@synthesize duration = _duration;

- (nullable instancetype)initWithImage:(UIImage *)image duration:(const NSTimeInterval)duration {
    if (!image || 0 == duration) {
        return nil;
    }
    if (self = [super init]) {
        _image = image;
        _duration = duration;
    }
    return self;
}

@end
