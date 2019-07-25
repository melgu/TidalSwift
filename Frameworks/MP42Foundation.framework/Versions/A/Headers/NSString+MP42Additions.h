//
//  NSString+MP42Additions.h
//  MP42Foundation
//
//  Created by Damiano Galassi on 18/09/15.
//  Copyright © 2015 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (MP42Additions)

- (NSArray<NSString *> *)MP42_componentsSeparatedByRegex:(NSString *)regex;
- (BOOL)MP42_isMatchedByRegex:(NSString *)regex;
- (NSString *)MP42_stringByMatching:(NSString *)regex capture:(NSInteger)capture;

@end

NS_ASSUME_NONNULL_END
