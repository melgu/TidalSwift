//
//  MP42SubtitleTrack.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2009 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MP42Foundation/MP42VideoTrack.h>

NS_ASSUME_NONNULL_BEGIN

@interface MP42SubtitleTrack : MP42VideoTrack <NSSecureCoding>

@property(nonatomic, readwrite) BOOL verticalPlacement;
@property(nonatomic, readwrite) BOOL someSamplesAreForced;
@property(nonatomic, readwrite) BOOL allSamplesAreForced;

@property(nonatomic, readonly)  MP42TrackId forcedTrackId;
@property(nonatomic, readwrite, weak, nullable) MP42Track *forcedTrack;

@end

NS_ASSUME_NONNULL_END
