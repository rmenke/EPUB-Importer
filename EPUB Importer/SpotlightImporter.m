//
//  SpotlightImporter.m
//  EPUB Importer
//
//  Created by Rob Menke on 5/12/17.
//  Copyright © 2017 Rob Menke. All rights reserved.
//

#import "SpotlightImporter.h"

#import "FolderDataSource.h"
#import "ArchiveDataSource.h"

NS_ASSUME_NONNULL_BEGIN

#define QUERY_PREFIX "declare default element namespace \"http://www.idpf.org/2007/opf\";\ndeclare namespace dc = \"http://purl.org/dc/elements/1.1/\";\n\n"

#define QUERY(ARG) @QUERY_PREFIX ARG

@implementation SpotlightImporter

/*
 * @abstract Import metadata from an abstract data source.
 *
 * @param dataSource The data source describing the ePub file or folder.
 * @param attributes The attributes to update.
 * @param error If an error occurs, upon return contains an @c NSError object that describes the problem.
 *
 * @return @c YES if the attributes were successfully imported.
 */
- (BOOL)import:(nullable id<DataSource>)dataSource attributes:(NSMutableDictionary<NSString *, id> *)attributes error:(NSError **)error {
    NSData *data = [dataSource containerAndReturnError:error];
    if (!data) return NO;

    NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:0 error:error];
    if (!document) return NO;

    NSArray *xQueryResult = [document.rootElement objectsForXQuery:@"data(rootfiles/rootfile/@full-path)" error:error];
    if (!xQueryResult) return NO;
    if (xQueryResult.count != 1) {
        if (error) *error = [NSError errorWithDomain:@"EPubSpotlightImporterErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"No/multiple root files in container document"}];
        return NO;
    }

    data = [dataSource package:xQueryResult[0] error:error];
    if (!data) return NO;

    document = [[NSXMLDocument alloc] initWithData:data options:0 error:error];
    if (!document) return NO;

    NSXMLElement *metadataElement = [document objectsForXQuery:QUERY(@"/package/metadata") error:error].firstObject;
    if (!metadataElement) return NO;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:identifier)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) attributes[(NSString *)kMDItemIdentifier] = xQueryResult.firstObject;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:title)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) attributes[(NSString *)kMDItemTitle] = xQueryResult.firstObject;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:creator)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) attributes[(NSString *)kMDItemAuthors] = xQueryResult.copy;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:publisher)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) attributes[(NSString *)kMDItemPublishers] = xQueryResult.copy;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:contributor)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) attributes[(NSString *)kMDItemContributors] = xQueryResult.copy;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:language)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) attributes[(NSString *)kMDItemLanguages] = xQueryResult.copy;

    xQueryResult = [metadataElement objectsForXQuery:QUERY(@"data(dc:rights)") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) attributes[(NSString *)kMDItemRights] = xQueryResult.firstObject;

    NSDateFormatter *ISODateFormatter = [[NSDateFormatter alloc] init];
    ISODateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    ISODateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

    xQueryResult = [metadataElement objectsForXQuery:QUERY("data(meta[@property='dcterms:modified'])") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) {
        NSDate *date = [ISODateFormatter dateFromString:xQueryResult[0]];

        attributes[(NSString *)kMDItemContentModificationDate] = date;
        attributes[(NSString *)kMDItemContentCreationDate] = date;
    }

    xQueryResult = [metadataElement objectsForXQuery:QUERY("data(meta[@property='dcterms:created'])") error:error];
    if (!xQueryResult) return NO;

    if (xQueryResult.count) {
        NSDate *date = [ISODateFormatter dateFromString:xQueryResult[0]];

        attributes[(NSString *)kMDItemContentCreationDate] = date;
    }

    xQueryResult = [document.rootElement objectsForXQuery:QUERY(@"count(/package/manifest/item)") error:error];
    if (!xQueryResult) return NO;

    attributes[@"org_idpf_epub_manifest_count"] = xQueryResult.firstObject;

    xQueryResult = [document.rootElement objectsForXQuery:QUERY(@"count(/package/spine/itemref)") error:error];
    if (!xQueryResult) return NO;

    NSUInteger chapterCount = [xQueryResult.firstObject unsignedIntegerValue];
    attributes[@"org_idpf_epub_spine_count"] = xQueryResult.firstObject;

    if (chapterCount < 200) {
        id<NSObject> activity = [NSProcessInfo.processInfo beginActivityWithOptions:NSActivityBackground reason:@"Reading ePub content files"];

        xQueryResult = [document.rootElement objectsForXQuery:QUERY(@"for $id in /package/spine/itemref/@idref\nlet $item := /package/manifest/item[@id=$id]\nwhere $item/@media-type = 'application/xhtml+xml'\nreturn data($item/@href)") error:error];

        NSMutableArray<NSString *> *texts = [NSMutableArray array];

        for (NSString *path in xQueryResult) {
            NSData *data = [dataSource contentFile:path error:error];
            if (!data) return NO;

            NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:data options:0 error:error];
            if (!document) return NO;

            NSArray *xQueryResult = [document.rootElement objectsForXQuery:@"//body//text()" error:error];
            if (!xQueryResult) return NO;

            if (xQueryResult.count > 0) [texts addObject:[xQueryResult componentsJoinedByString:@" "]];
        }

        if (texts.count > 0) attributes[(NSString *)kMDItemTextContent] = [texts componentsJoinedByString:@" "];

        [NSProcessInfo.processInfo endActivity:activity];
    }

    return YES;
}

- (BOOL)importFolderAtPath:(NSString *)path attributes:(NSMutableDictionary<NSString *, id> *)attributes error:(NSError **)error {
    return [self import:[[FolderDataSource alloc] initWithPath:path] attributes:attributes error:error];
}

- (BOOL)importFileAtPath:(NSString *)path attributes:(NSMutableDictionary<NSString *, id> *)attributes error:(NSError **)error {
    return [self import:[[ArchiveDataSource alloc] initWithPath:path error:error] attributes:attributes error:error];
}

@end

NS_ASSUME_NONNULL_END
