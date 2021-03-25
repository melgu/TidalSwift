//
//  MP42FileImporter.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/10.
//  Copyright 2021 Damiano Galassi All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MP42Foundation/MP42Utilities.h>

@class MP42SampleBuffer;
@class MP42AudioTrack;
@class MP42VideoTrack;

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

#pragma mark - Override

- (nullable NSData *)magicCookieForTrack:(MP42Track *)track;
- (AudioStreamBasicDescription)audioDescriptionForTrack:(MP42AudioTrack *)track;

- (BOOL)audioTrackUsesExplicitEncoderDelay:(MP42Track *)track;
- (BOOL)supportsPreciseTimestamps;

- (void)setup;
- (void)demux;
- (void)cleanUp:(MP42Track *)track fileHandle:(MP42FileHandle)fileHandle;

#pragma mark - Private

- (void)enqueue:(MP42SampleBuffer * NS_RELEASES_ARGUMENT)sample MP42_OBJC_DIRECT;

@property (nonatomic, readwrite MP42_DIRECT) double progress;
@property (nonatomic, readonly, getter=isCancelled MP42_DIRECT) BOOL cancelled;

@end

NS_ASSUME_NONNULL_END
