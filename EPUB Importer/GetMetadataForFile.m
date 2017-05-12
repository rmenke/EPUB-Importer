//
//  GetMetadataForFile.m
//  EPUB Importer
//
//  Created by Rob Menke on 5/12/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

@import CoreFoundation;

#if DEBUG
    #define TRY(...) do { \
        NSError * __autoreleasing _Nullable __error = nil; \
        NSError * __autoreleasing _Nullable * _Nonnull const error = &__error; \
        Boolean __status = (__VA_ARGS__); \
        if (__status == FALSE) NSLog(@"error importing %@: %@", thePath, __error); \
        return __status; \
    } while (0)
#else
    #define TRY(...) do { \
        NSError * __autoreleasing * const error = NULL; \
        return (__VA_ARGS__); \
    } while (0)
#endif

#import "SpotlightImporter.h"

Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef uti, CFStringRef path) {
    @autoreleasepool {
        NSString *theType = (__bridge NSString *)(uti);
        NSString *thePath = (__bridge NSString *)(path);
        NSMutableDictionary *theAttributes = (__bridge NSMutableDictionary *)(attributes);

        if ([@"org.idpf.epub-folder" isEqualToString:theType]) {
            TRY([[[SpotlightImporter alloc] init] importFolderAtPath:thePath attributes:theAttributes error:error]);
        }
        else if ([@"org.idpf.epub-container" isEqualToString:theType]) {
            TRY([[[SpotlightImporter alloc] init] importFileAtPath:thePath attributes:theAttributes error:error]);
        }
        else {
            return FALSE;
        }
    }
}
