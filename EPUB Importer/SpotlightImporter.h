//
//  SpotlightImporter.h
//  EPUB Importer
//
//  Created by Rob Menke on 5/12/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

@interface SpotlightImporter : NSObject

- (BOOL)importFolderAtPath:(NSString *)path attributes:(NSMutableDictionary *)attributes error:(NSError **)error;
- (BOOL)importFileAtPath:(NSString *)path attributes:(NSMutableDictionary *)attributes error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
