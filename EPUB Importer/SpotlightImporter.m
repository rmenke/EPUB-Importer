//
//  SpotlightImporter.m
//  EPUB Importer
//
//  Created by Rob Menke on 5/12/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

#import "SpotlightImporter.h"

NS_ASSUME_NONNULL_BEGIN

#define QUERY_PREFIX "declare default element namespace \"http://www.idpf.org/2007/opf\";\ndeclare namespace dc = \"http://purl.org/dc/elements/1.1/\";\n\n"

#define QUERY(ARG) @QUERY_PREFIX ARG

@implementation SpotlightImporter

- (BOOL)importFolderAtPath:(NSString *)filePath attributes:(NSMutableDictionary<NSString *, id> *)spotlightData error:(NSError **)error {
    NSURL *folderURL = [NSURL fileURLWithPath:filePath isDirectory:YES];

    NSURL *containerURL = [NSURL fileURLWithPath:@"META-INF/container.xml" isDirectory:NO relativeToURL:folderURL];

    NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:containerURL options:0 error:error];
    if (!document) return NO;

    NSArray *xQueryResult = [document.rootElement objectsForXQuery:@"data(rootfiles/rootfile/@full-path)" error:error];
    if (!xQueryResult) return NO;
    if (xQueryResult.count != 1) {
        if (error) *error = [NSError errorWithDomain:@"EPubSpotlightImporterErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"No/multiple root files in container document"}];
        return NO;
    }

    NSURL *rootFileURL = [NSURL fileURLWithPath:xQueryResult[0] isDirectory:NO relativeToURL:folderURL];

    document = [[NSXMLDocument alloc] initWithContentsOfURL:rootFileURL options:0 error:error];
    if (!document) return NO;

    NSXMLElement *metadataElement = [document objectsForXQuery:QUERY(@"/package/metadata") error:error].firstObject;
    if (!metadataElement) return NO;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:identifier)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) spotlightData[(NSString *)kMDItemIdentifier] = xQueryResult.firstObject;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:title)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) spotlightData[(NSString *)kMDItemTitle] = xQueryResult.firstObject;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:creator)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) spotlightData[(NSString *)kMDItemAuthors] = xQueryResult.copy;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:publisher)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) spotlightData[(NSString *)kMDItemPublishers] = xQueryResult.copy;
    
    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:contributor)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) spotlightData[(NSString *)kMDItemContributors] = xQueryResult.copy;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:language)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) spotlightData[(NSString *)kMDItemLanguages] = xQueryResult.copy;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:rights)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) spotlightData[(NSString *)kMDItemRights] = xQueryResult.firstObject;

    NSDateFormatter *ISODateFormatter = [[NSDateFormatter alloc] init];
    ISODateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    ISODateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

    xQueryResult = [metadataElement objectsForXQuery:QUERY("data(meta[@property='dcterms:modified'])") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) {
        NSDate *date = [ISODateFormatter dateFromString:xQueryResult[0]];

        spotlightData[(NSString *)kMDItemContentModificationDate] = date;
        spotlightData[(NSString *)kMDItemContentCreationDate] = date;
    }
    
    xQueryResult = [metadataElement objectsForXQuery:QUERY("data(meta[@property='dcterms:created'])") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) {
        NSDate *date = [ISODateFormatter dateFromString:xQueryResult[0]];
        
        spotlightData[(NSString *)kMDItemContentCreationDate] = date;
    }

    xQueryResult = [document.rootElement objectsForXQuery:QUERY(@"count(/package/manifest/item)") error:error];
    if (!xQueryResult) return NO;

    spotlightData[@"org_idpf_epub_manifest_count"] = xQueryResult.firstObject;
    
    xQueryResult = [document.rootElement objectsForXQuery:QUERY(@"count(/package/spine/itemref)") error:error];
    if (!xQueryResult) return NO;

    NSUInteger chapterCount = [xQueryResult.firstObject unsignedIntegerValue];
    spotlightData[@"org_idpf_epub_spine_count"] = xQueryResult.firstObject;
    
    if (chapterCount < 200) {
        id<NSObject> activity = [NSProcessInfo.processInfo beginActivityWithOptions:NSActivityBackground reason:@"Reading ePub content files"];

        xQueryResult = [document.rootElement objectsForXQuery:QUERY(@"for $id in /package/spine/itemref/@idref\nlet $item := /package/manifest/item[@id=$id]\nwhere $item/@media-type = 'application/xhtml+xml'\nreturn data($item/@href)") error:error];
        
        NSMutableArray<NSString *> *texts = [NSMutableArray array];

        for (NSString *path in xQueryResult) {
            @autoreleasepool {
                NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO relativeToURL:rootFileURL];

                NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:error];
                if (!document) return NO;

                NSArray *xQueryResult = [document.rootElement objectsForXQuery:@"//body//text()" error:error];
                if (!xQueryResult) return NO;

                if (xQueryResult.count > 0) [texts addObject:[xQueryResult componentsJoinedByString:@" "]];
            }
        }

        if (texts.count > 0) spotlightData[(NSString *)kMDItemTextContent] = [texts componentsJoinedByString:@" "];

        [NSProcessInfo.processInfo endActivity:activity];
    }

    return YES;
}

- (BOOL)importFileAtPath:(NSString *)path attributes:(NSMutableDictionary *)attributes error:(NSError **)error {
    return NO;
}

@end

NS_ASSUME_NONNULL_END
