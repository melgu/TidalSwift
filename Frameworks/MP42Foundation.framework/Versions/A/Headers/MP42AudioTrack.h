//
//  MP42SubtitleTrack.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MP42Track.h"

@interface MP42AudioTrack : MP42Track <NSSecureCoding, NSCopying>

@property(nonatomic, readwrite) float volume;

@property(nonatomic, readwrite) UInt32 channels;
@property(nonatomic, readwrite) UInt32 channelLayoutTag;

@property(nonatomic, readwrite) MP42AudioEmbeddedExtension extensionType;

@property(nonatomic, readonly) MP42TrackId fallbackTrackId;
@property(nonatomic, readonly) MP42TrackId followsTrackId;

@property(nonatomic, readwrite, weak, nullable) MP42Track *fallbackTrack;
@property(nonatomic, readwrite, weak, nullable) MP42Track *followsTrack;

@end
