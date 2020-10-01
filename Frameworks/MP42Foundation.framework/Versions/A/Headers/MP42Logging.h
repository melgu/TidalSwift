//
//  MP42Logger.h
//  MP42Foundation
//
//  Created by Damiano Galassi on 26/10/14.
//  Copyright (c) 2020 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MP42Logging <NSObject>

@required
- (void)writeToLog:(NSString *)string;
@optional
- (void)writeErrorToLog:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
