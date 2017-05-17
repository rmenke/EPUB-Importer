//
//  FolderDataSource.h
//  EPUB Importer
//
//  Created by Rob Menke on 5/16/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

@import Cocoa;

#import "DataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface FolderDataSource : NSObject<DataSource>

- (instancetype)init NS_UNAVAILABLE;

/*!
 * @abstract Read from an org.idpf.epub-folder directory.
 *
 * @param path The path to the directory.
 *
 * @return A @c DataSource object that reads from files in a directory.
 */
- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
