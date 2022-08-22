//
//  WebpImageKitMacro.m
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-11.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#import "WebpImageKitMacro.h"

void webp_execCleanupBlock(__strong webp_cleanup_block *block) {
    (*block)();
}
