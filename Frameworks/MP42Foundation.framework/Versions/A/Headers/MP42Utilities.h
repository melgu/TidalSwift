//
//  MP42Utilities.h
//  MP42Foundation
//
//  Created by Damiano Galassi on 16/11/13.
//  Copyright (c) 2013 Damiano Galassi. All rights reserved.
//

#import "MP42MediaFormat.h"

NS_ASSUME_NONNULL_BEGIN

NSString * StringFromTime(long long time, long timeScale);
MP42Duration TimeFromString(NSString *SMPTE_string, MP42Duration timeScale);

BOOL isTrackMuxable(FourCharCode formatName);
BOOL trackNeedConversion(FourCharCode formatName);

NSString *nameForChannelLayoutTag(UInt32 channelLayoutTag);

NS_ASSUME_NONNULL_END
