//
//  MP42RelatedItem.h
//  MP42Foundation
//
//  Created by Damiano Galassi on 09/03/2019.
//  Copyright © 2021 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MP42Foundation/MP42Utilities.h>

NS_ASSUME_NONNULL_BEGIN

MP42_OBJC_DIRECT_MEMBERS
@interface MP42RelatedItem : NSObject<NSFilePresenter>

@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) NSString *extension;

- (instancetype)initWithURL:(NSURL *)URL extension:(NSString *)extension;

@end

NS_ASSUME_NONNULL_END
