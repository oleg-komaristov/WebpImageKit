//
//  WIKAnimationFrame.h
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-11.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIImage;

@interface WIKAnimationFrame : NSObject

@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSTimeInterval duration;

- (nullable instancetype)initWithImage:(UIImage *)image
                              duration:(const NSTimeInterval)duration NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
