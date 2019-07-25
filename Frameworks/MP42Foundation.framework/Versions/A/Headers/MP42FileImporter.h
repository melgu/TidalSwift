//
//  MP42FileImporter.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2010 Damiano Galassi All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MP42Metadata;
@class MP42Track;

@interface MP42FileImporter : NSObject

+ (NSArray<NSString *> *)supportedFileFormats;
+ (BOOL)canInitWithFileType:(NSString *)fileType;

- (nullable instancetype)initWithURL:(NSURL *)fileURL error:(NSError * __autoreleasing *)error;

@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) MP42Metadata *metadata;
@property (nonatomic, readonly) NSArray<MP42Track *> *tracks;

@end

NS_ASSUME_NONNULL_END
