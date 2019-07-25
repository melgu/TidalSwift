//
//  MP42Ratings.h
//  Subler
//
//  Created by Douglas Stebila on 2013-06-02.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MP42Ratings : NSObject

@property (class, readonly) MP42Ratings *defaultManager;

@property (nonatomic, readonly) NSArray<NSString *> *ratings;
@property (nonatomic, readonly) NSArray<NSString *> *iTunesCodes;

@property (nonatomic, readonly) NSArray<NSString *> *ratingsCountries;

- (void)updateRatingsCountry;

- (NSInteger)ratingIndexForiTunesCode:(NSString *)aiTunesCode;
- (NSInteger)ratingIndexForiTunesCountry:(NSString *)aCountry media:(NSString *)aMedia ratingString:(NSString *)aRatingString;

- (nullable NSString *)ratingStringForiTunesCountry:(NSString *)aCountry media:(NSString *)aMedia ratingString:(NSString *)aRatingString;

@end

NS_ASSUME_NONNULL_END
