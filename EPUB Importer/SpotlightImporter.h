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

/*!
 * @abstract Import a folder containing ePub content.
 *
 * @param path The path to the ePub folder.
 * @param attributes The dictionary of attributes to update.
 * @param error If an error occurs, upon return contains an @c NSError object that describes the problem.
 *
 * @return @c YES if the attributes were successfully imported.
 */
- (BOOL)importFolderAtPath:(NSString *)path attributes:(NSMutableDictionary<NSString *, id> *)attributes error:(NSError **)error;

/*!
 * @abstract Import a file containing ePub content.
 *
 * @param path The path to the ePub file.
 * @param attributes The dictionary of attributes to update.
 * @param error If an error occurs, upon return contains an @c NSError object that describes the problem.
 *
 * @return @c YES if the attributes were successfully imported.
 */
- (BOOL)importFileAtPath:(NSString *)path attributes:(NSMutableDictionary<NSString *, id> *)attributes error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
