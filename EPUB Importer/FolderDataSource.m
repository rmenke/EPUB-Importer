//
//  FolderDataSource.m
//  EPUB Importer
//
//  Created by Rob Menke on 5/16/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

#import "FolderDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface FolderDataSource ()

@property (nonatomic, readwrite, copy) NSURL *rootFolder, *rootFile;

@end

@implementation FolderDataSource

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];

    if (self) {
        self.rootFolder = [NSURL fileURLWithPath:path isDirectory:YES];
    }

    return self;
}

- (nullable NSData *)containerAndReturnError:(NSError **)error {
    NSURL *containerURL = [NSURL fileURLWithPath:@"META-INF/container.xml" isDirectory:NO relativeToURL:self.rootFolder];
    return [[NSData alloc] initWithContentsOfURL:containerURL options:0 error:error];
}

- (nullable NSData *)package:(NSString *)relativePath error:(NSError **)error {
    self.rootFile = [NSURL fileURLWithPath:relativePath isDirectory:NO relativeToURL:self.rootFolder];
    return [[NSData alloc] initWithContentsOfURL:self.rootFile options:0 error:error];
}

- (nullable NSData *)contentFile:(NSString *)relativePath error:(NSError **)error {
    if (!self.rootFile) {
        if (error) *error = [NSError errorWithDomain:@"ArchiveDataSourceErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"-[DataSource package:error:] must be called first."}];
        return nil;
    }

    NSURL *url = [NSURL fileURLWithPath:relativePath isDirectory:NO relativeToURL:self.rootFile];
    return [[NSData alloc] initWithContentsOfURL:url options:0 error:error];
}

@end

NS_ASSUME_NONNULL_END
