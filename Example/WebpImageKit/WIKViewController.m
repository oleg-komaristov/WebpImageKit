//
//  WIKViewController.m
//  WebpImageKit
//
//  Created by Oleg Komaristov on 08/23/2022.
//  Copyright (c) 2022 Oleg Komaristov. All rights reserved.
//

#import <WebpImageKit/WebpImageKit.h>

#import "WIKViewController.h"

@interface WIKViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imgViewTop;
@property (nonatomic, weak) IBOutlet UILabel *lblTop;
@property (nonatomic, weak) IBOutlet UIButton *btnTop;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityTop;

@property (nonatomic, weak) IBOutlet UIImageView *imgViewBottom;
@property (nonatomic, weak) IBOutlet UILabel *lblBottom;
@property (nonatomic, weak) IBOutlet UIButton *btnBottom;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityBottom;

@end

@implementation WIKViewController

- (NSString *)formattedSizeForData:(NSData *)data {
    return [NSByteCountFormatter stringFromByteCount:(long long int) data.length
                                          countStyle:NSByteCountFormatterCountStyleBinary];
}

- (NSString *)imgDescriptionForImage:(UIImage *)image data:(NSData *)data {
    return [NSString stringWithFormat:@"%.0fx%.0fpx : %@", image.size.width, image.size.height, [self formattedSizeForData:data]];
}

- (NSString *)encodedImgDescriptionForImage:(UIImage *)image data:(NSData *)data duration:(NSTimeInterval)duration {
    return [NSString stringWithFormat:@"%.0fx%.0fpx : %@ in %.2f sec.", image.size.width, image.size.height,
                                      [self formattedSizeForData:data], duration];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSError *loadError;
    __auto_type staticImgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/2.webp"]
                                                      options:NSDataReadingMappedIfSafe
                                                        error:&loadError];
    if (staticImgData) {
        __auto_type image = [UIImage webpImageWithData:staticImgData];
        if (!image) {
            NSLog(@"Error: Can't create UIImage from WebP image data.");
        }
        self.imgViewTop.image = image;
        self.lblTop.text = [self imgDescriptionForImage:image data:staticImgData];
    }
    else {
        NSLog(@"Error: Unable download static image data");
    }

    NSData *animatedImgData = nil;
    __auto_type imgURL = [NSBundle.mainBundle URLForResource:@"world-cup-animation" withExtension:@"webp"];
    if (imgURL) {
        animatedImgData = [NSData dataWithContentsOfURL:imgURL options:NSDataReadingMappedIfSafe error:&loadError];
    }
    else {
        NSLog(@"Error: Image world-cup.webp not found in bundle.");
    }
    if (animatedImgData) {
        __auto_type image = [UIImage webpImageWithData:animatedImgData];
        if (!image) {
            NSLog(@"Error: Can't create animated UIImage from WebP image data.");
        }
        self.imgViewBottom.image = image;
        self.lblBottom.text = [self imgDescriptionForImage:image data:animatedImgData];
    }
}

- (void)encodeImage:(UIImage *)image withComplete:(void (^)(NSData *imgData, NSTimeInterval duration))complete {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        __auto_type start = [NSDate date];
        __auto_type config = [[WIKEncoderConfigBuilder builderWithImageQuality:0.6] construct];
        __auto_type data = [image webpDataWithConfig:config];
        NSTimeInterval duration = fabs([start timeIntervalSinceNow]);
        dispatch_sync(dispatch_get_main_queue(), ^{
            complete(data, duration);
        });
    });
}

- (IBAction)encodeAndReopenTop:(id)sender {
    self.btnTop.enabled = NO;
    [self.activityTop startAnimating];
    __weak typeof(self) wSelf = self;
    [self encodeImage:self.imgViewTop.image withComplete:^(NSData *imgData, NSTimeInterval duration) {
        __auto_type image = [UIImage webpImageWithData:imgData];
        wSelf.imgViewTop.image = image;
        wSelf.lblTop.text = [self encodedImgDescriptionForImage:image data:imgData duration:duration];
        [wSelf.activityTop stopAnimating];
        wSelf.btnTop.enabled = YES;
    }];
}

- (IBAction)encodeAndReopenBottom:(id)sender {
    self.btnBottom.enabled = NO;
    [self.activityBottom startAnimating];
    __weak typeof(self) wSelf = self;
    [self encodeImage:self.imgViewBottom.image withComplete:^(NSData *imgData, NSTimeInterval duration) {
        __auto_type image = [UIImage webpImageWithData:imgData];
        wSelf.imgViewBottom.image = image;
        wSelf.lblBottom.text = [self encodedImgDescriptionForImage:image data:imgData duration:duration];
        [wSelf.activityBottom stopAnimating];
        wSelf.btnBottom.enabled = YES;
    }];
}

@end
