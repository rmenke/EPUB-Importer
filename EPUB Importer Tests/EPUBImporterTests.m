//
//  EPUBImporterTests.m
//  EPUB Importer Tests
//
//  Created by Rob Menke on 5/12/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

@import XCTest;

#import "SpotlightImporter.h"

extern Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef uti, CFStringRef path);

@interface EPUBImporterTests : XCTestCase

@property (nonatomic) NSBundle *bundle;

@end

@implementation EPUBImporterTests

- (void)setUp {
    [super setUp];

    _bundle = [NSBundle bundleForClass:[self class]];
}

- (void)tearDown {
    _bundle = nil;

    [super tearDown];
}

- (void)testImporter {
    NSError * __autoreleasing error;

    NSURL *epubURL = [_bundle URLForResource:@"childrens" withExtension:@"epub"];
    if (!epubURL) return; // submodule not imported

    SpotlightImporter *importer = [[SpotlightImporter alloc] init];

    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

    XCTAssert([importer importFolderAtPath:epubURL.path attributes:attributes error:&error], @"error - %@", error);

    XCTAssertEqualObjects(attributes[(NSString *)kMDItemTitle], @"Abroad");
    XCTAssertEqualObjects(attributes[(NSString *)kMDItemAuthors], (@[@"Thomas Crane", @"Ellen Elizabeth Houghton"]));
    XCTAssertEqualObjects(attributes[(NSString *)kMDItemPublishers], (@[@"London ; Belfast ; New York : Marcus Ward & Co."]));
}

- (void)testImporterSamples {
    for (NSURL *url in [_bundle URLsForResourcesWithExtension:@"epub" subdirectory:nil]) {
        CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        XCTAssertTrue(GetMetadataForFile(NULL, attributes, CFSTR("org.idpf.epub-folder"), (__bridge CFStringRef)(url.path)));

        CFTypeRef value;

        XCTAssertTrue(CFDictionaryGetValueIfPresent(attributes, kMDItemTitle, &value));
        XCTAssertEqual(CFGetTypeID(value), CFStringGetTypeID());
        XCTAssertTrue(CFDictionaryGetValueIfPresent(attributes, kMDItemAuthors, &value));
        XCTAssertEqual(CFGetTypeID(value), CFArrayGetTypeID());
        XCTAssertTrue(CFDictionaryGetValueIfPresent(attributes, kMDItemTextContent, &value));
        XCTAssertEqual(CFGetTypeID(value), CFStringGetTypeID());

        CFRelease(attributes);
    }
}

- (void)testPerformance {
    NSURL *epubURL = [_bundle URLForResource:@"moby-dick" withExtension:@"epub"];
    if (!epubURL) return; // submodule not imported

    CFStringRef path = (__bridge CFStringRef)(epubURL.path);

    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        [self startMeasuring];
        XCTAssertTrue(GetMetadataForFile(NULL, attributes, CFSTR("org.idpf.epub-folder"), path));
        [self stopMeasuring];
        CFRelease(attributes);
    }];
}

@end
