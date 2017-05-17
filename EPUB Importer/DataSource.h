//
//  DataSource.h
//  EPUB Importer
//
//  Created by Rob Menke on 5/16/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol DataSource <NSObject>

/*!
 * @abstract Get the container file from the ePub.
 *
 * @discussion The ePub container file is always located at <code>META-INF/container.xml</code>.
 *
 * @param error If an error occurs, upon return contains an @c NSError object that describes the problem.
 *
 * @return The contents of the container file, or @c nil if an error occurred.
 */
- (nullable NSData *)containerAndReturnError:(NSError **)error;

/*!
 * @abstract Get the package file from the ePub.
 *
 * @discussion The location of the package file is found in the container file.
 *
 * @param path The path to the package file relative to the archive root.
 * @param error If an error occurs, upon return contains an @c NSError object that describes the problem.
 *
 * @return The contents of the package file, or @c nil if an error occurred.
 */
- (nullable NSData *)package:(NSString *)path error:(NSError **)error;

/*!
 * @abstract Get a content file from the ePub.
 *
 * @discussion Content files are listed in the manifest of the package file.
 *
 * @param path The path to the package file relative to the container file.
 * @param error If an error occurs, upon return contains an @c NSError object that describes the problem.
 *
 * @note This method will always return @c nil until the package file has been read.
 *
 * @return The contents of the content file, or @c nil if an error occurred.
 */
- (nullable NSData *)contentFile:(NSString *)path error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
