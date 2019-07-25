//
//  MP42RelatedItem.h
//  MP42Foundation
//
//  Created by Damiano Galassi on 09/03/2019.
//  Copyright © 2019 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MP42RelatedItem : NSObject<NSFilePresenter>

@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly) NSString *extension;

- (instancetype)initWithURL:(NSURL *)URL extension:(NSString *)extension;

@end

NS_ASSUME_NONNULL_END
