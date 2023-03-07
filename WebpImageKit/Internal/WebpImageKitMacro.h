//
//  WebpImageKitMacro.h
//  WebpImageKit
//
//  Created by Oleg Komaristov on 2022-08-11.
//  Copyright © 2022 Oleg Komaristov. All rights reserved.
//

#ifndef WebpImageKitMacro_h
#define WebpImageKitMacro_h

#define meta_macro_concat(A, B) meta_macro_concat_(A, B)

#if DEBUG
#define webp_keyword autoreleasepool {}
#else
#define webp_keyword try {} @catch (...) {}
#endif

typedef void(^webp_cleanup_block)(void);

#ifndef webp_defer
#define webp_defer webp_keyword \
__strong webp_cleanup_block meta_macro_concat(webp_deferBlock_, __LINE__) __attribute__((cleanup(webp_execCleanupBlock), unused)) = ^
#endif

#if defined(__cplusplus)
extern "C" {
#endif
void webp_execCleanupBlock(__strong webp_cleanup_block *block);
#if defined(__cplusplus)
}
#endif

#define meta_macro_concat_(A, B) A ## B

NS_INLINE CGSize scaledImageSize(const CGSize imgSize, const CGSize targetSize, const CGFloat scaleFactor) {
    __auto_type rWidth = imgSize.width;
    __auto_type rHeight = imgSize.height;
    if (targetSize.width > 0.0 && targetSize.height > 0.0) {
        const __auto_type tWidth = targetSize.width * MAX(1.0, scaleFactor);
        const __auto_type tHeight = targetSize.height * MAX(1.0, scaleFactor);
        const __auto_type sRatio = imgSize.width / imgSize.height;
        const __auto_type tRatio = tWidth / tHeight;
        if (sRatio > tRatio) {
            rWidth = tWidth;
            rHeight = ceil(tWidth / sRatio);
        }
        else {
            rHeight = tHeight;
            rWidth = ceil(tHeight * sRatio);
        }
        rWidth = MIN(imgSize.width, rWidth);
        rHeight = MIN(imgSize.height, rHeight);
    }
    return CGSizeMake(rWidth, rHeight);
}


#endif /* WebpImageKitMacro_h */
