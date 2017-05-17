//
//  ArchiveDataSource.m
//  EPUB Importer
//
//  Created by Rob Menke on 5/16/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

#import "ArchiveDataSource.h"

#include <zlib.h>

#if BYTE_ORDER == BIG_ENDIAN
#error "Unsupported architecture"
#endif

NS_ASSUME_NONNULL_BEGIN

typedef struct __attribute__((packed)) __ZIPLocalHeader {
    uint32_t signature;
    uint16_t version;
    uint16_t flags;
    uint16_t method;
    uint16_t mod_file_time;
    uint16_t mod_file_date;
    uint32_t crc32;
    uint32_t compressed_size;
    uint32_t uncompressed_size;
    uint16_t file_name_length;
    uint16_t extra_field_length;

    char file_name[];
} ZIPLocalHeader;

unsigned ReadData(void *desc, unsigned char **ptr) {
    NSData *data = (__bridge NSData *)(desc);
    *ptr = (unsigned char *)(data.bytes);
    return (unsigned)(data.length);
}

int WriteData(void *desc, unsigned char *ptr, unsigned size) {
    NSMutableData *data = (__bridge NSMutableData *)(desc);
    [data appendBytes:ptr length:size];
    return 0;
}

NSData * _Nullable GetData(const ZIPLocalHeader *header, NSError **error) {
    NSData *inData = [NSData dataWithBytes:((uint8_t *)(header) + sizeof(ZIPLocalHeader) + header->file_name_length + header->extra_field_length) length:header->compressed_size];

    if (header->method == 0) {
        return inData;
    }
    else if (header->method == 8) {
        NSMutableData *outData = [NSMutableData data];

        z_stream stream = {
            .zalloc = NULL, .zfree = NULL, .opaque = NULL
        };

        uint8_t window[1 << 15];

        int status = inflateBackInit(&stream, 15, window);
        if (status != Z_OK) {
            if (error) *error = [NSError errorWithDomain:@"ZLibErrorDomain" code:status userInfo:@{NSLocalizedDescriptionKey:@(stream.msg ? stream.msg : "Unknown ZLib error")}];
            return nil;
        }

        status = inflateBack(&stream, &ReadData, (__bridge void *)(inData), &WriteData, (__bridge void *)(outData));
        if (status != Z_STREAM_END) {
            if (error) *error = [NSError errorWithDomain:@"ZLibErrorDomain" code:status userInfo:@{NSLocalizedDescriptionKey:@(stream.msg ? stream.msg : "Unknown ZLib error")}];
            return nil;
        }

        status = inflateBackEnd(&stream);
        if (status != Z_OK) {
            if (error) *error = [NSError errorWithDomain:@"ZLibErrorDomain" code:status userInfo:@{NSLocalizedDescriptionKey:@(stream.msg ? stream.msg : "Unknown ZLib error")}];
            return nil;
        }

        return outData;
    }
    else {
        if (error) *error = [NSError errorWithDomain:@"ArchiveDataSourceErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Unsupported compression method"}];
        return nil;
    }
}

@interface ArchiveDataSource ()

@property (nonatomic, nonnull) NSData *data;
@property (nonatomic, nullable) NSString *rootFilePath;
@property (nonatomic, nonnull) NSDictionary<NSString *, NSValue *> *offsets;

@end

@implementation ArchiveDataSource

- (nullable instancetype)initWithPath:(NSString *)path error:(NSError **)error {
    self = [super init];

    if (self) {
        self.data = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:error];
        if (!self.data) return nil;

        const ZIPLocalHeader * header = self.data.bytes;
        const ZIPLocalHeader * const end = (const void *)(header) + self.data.length;

        NSMutableDictionary<NSString *, NSValue *> *offsets = [NSMutableDictionary dictionary];

        while ((header < end) && (header->signature == 0x04034b50)) {
            NSString *name = [[NSString alloc] initWithBytes:header->file_name length:header->file_name_length encoding:NSUTF8StringEncoding];

            offsets[name] = [NSValue valueWithPointer:header];

            header = (const void *)(header) + sizeof(ZIPLocalHeader) + header->file_name_length + header->extra_field_length + header->compressed_size;
        }

        self.offsets = offsets;
    }

    return self;
}

- (nullable NSData *)containerAndReturnError:(NSError **)error {
    NSValue *location = self.offsets[@"META-INF/container.xml"];
    return location ? GetData(location.pointerValue, error) : nil;
}

- (nullable NSData *)package:(NSString *)relativePath error:(NSError **)error {
    NSValue *location = self.offsets[self.rootFilePath = relativePath];
    return location ? GetData(location.pointerValue, error) : nil;
}

- (nullable NSData *)contentFile:(NSString *)relativePath error:(NSError **)error {
    if (!self.rootFilePath) {
        if (error) *error = [NSError errorWithDomain:@"ArchiveDataSourceErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"-[DataSource package:error:] must be called first."}];
        return nil;
    }

    NSURL *rootFile = [NSURL URLWithString:[@"/" stringByAppendingString:self.rootFilePath]];
    NSURL *url = [NSURL URLWithString:relativePath relativeToURL:rootFile];

    NSString *path = url.path;
    while ([path hasPrefix:@"/"]) path = [path substringFromIndex:1];

    NSValue *location = self.offsets[path];
    return location ? GetData(location.pointerValue, error) : nil;
}

@end

NS_ASSUME_NONNULL_END
