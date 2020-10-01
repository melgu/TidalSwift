//
//  MP42Utilities.h
//  MP42Foundation
//
//  Created by Damiano Galassi on 16/11/13.
//  Copyright (c) 2020 Damiano Galassi. All rights reserved.
//

#import <MP42Foundation/MP42MediaFormat.h>

// Direct method and property calls increases performance and reduces binary size.
#if defined(__IPHONE_14_0) || defined(__MAC_10_16) || defined(__MAC_11_0) || defined(__TVOS_14_0) || defined(__WATCHOS_7_0)
#define MP42_OBJC_DIRECT_MEMBERS __attribute__((objc_direct_members))
#define MP42_OBJC_DIRECT __attribute__((objc_direct))
#define MP42_DIRECT ,direct
#else
#define MP42_OBJC_DIRECT_MEMBERS
#define MP42_OBJC_DIRECT
#define MP42_DIRECT
#endif

NS_ASSUME_NONNULL_BEGIN

NSString * StringFromTime(long long time, int32_t timeScale);
MP42Duration TimeFromString(NSString *SMPTE_string, int32_t timeScale);

BOOL isTrackMuxable(FourCharCode formatName);
BOOL trackNeedConversion(FourCharCode formatName);

NSString *nameForChannelLayoutTag(UInt32 channelLayoutTag);

NS_ASSUME_NONNULL_END
