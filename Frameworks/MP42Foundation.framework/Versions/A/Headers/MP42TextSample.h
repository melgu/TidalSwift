//
//  SBTextSample.h
//  MP42
//
//  Created by Damiano Galassi on 01/11/13.
//  Copyright (c) 2013 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MP42Foundation/MP42MediaFormat.h>
#import <MP42Foundation/MP42Image.h>

NS_ASSUME_NONNULL_BEGIN

@interface MP42TextSample : NSObject <NSSecureCoding>

@property (nonatomic, readwrite, copy) NSString *title;
@property (nonatomic, readwrite, retain, nullable) MP42Image *image;
@property (nonatomic, readwrite) MP42Duration timestamp;

- (NSComparisonResult)compare:(MP42TextSample *)otherObject;

@end

NS_ASSUME_NONNULL_END
