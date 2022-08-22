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

#endif /* WebpImageKitMacro_h */
