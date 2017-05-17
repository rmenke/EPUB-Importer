//
//  ArchiveDataSource.h
//  EPUB Importer
//
//  Created by Rob Menke on 5/16/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

@import Cocoa;

#import "DataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface ArchiveDataSource : NSObject<DataSource>

- (instancetype)init NS_UNAVAILABLE;

/*!
 * @abstract Read from an org.idpf.epub-container file.
 *
 * @param path The path to the container file.
 * @param error If an error occurs, upon return contains an @c NSError object that describes the problem.
 *
 * @return A @c DataSource object that reads from a container file.
 */
- (nullable instancetype)initWithPath:(NSString *)path error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
