//
//  NSData+WebP.m
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-11.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import "NSData+WebP.h"

@implementation NSData (WebP)

- (BOOL)webpIsImage {
    if (12 > self.length) {
        return NO;
    }
    uint8_t byte;
    [self getBytes:&byte length:1];
    if (0x52 != byte) {
        return NO;
    }
    NSString *testString = [[NSString alloc] initWithData:[self subdataWithRange:NSMakeRange(0, 12)]
                                                 encoding:NSASCIIStringEncoding];
    return [testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"];
}

@end
