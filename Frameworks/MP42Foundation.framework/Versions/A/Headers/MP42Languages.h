//
//  MP42Languages.h
//  Subler
//
//  Created by Damiano Galassi on 13/08/12.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MP42Languages : NSObject

@property (class, readonly) MP42Languages *defaultManager;

+ (nullable NSString *)ISO_639_1CodeForLang:(NSString *)language;
+ (NSString *)langForISO_639_1Code:(NSString *)language;

- (NSString *)ISO_639_2CodeForExtendedTag:(NSString *)code;

- (NSString *)extendedTagForLang:(NSString *)language;
- (NSString *)extendedTagForQTCode:(NSString *)code;
- (NSString *)extendedTagForISO_639_1:(NSString *)code;
- (NSString *)extendedTagForISO_639_2:(NSString *)code;
- (NSString *)extendedTagForISO_639_2b:(NSString *)code;

- (NSString *)extendedTagForLocalizedLang:(NSString *)language;
- (NSString *)localizedLangForExtendedTag:(NSString *)tag;

- (BOOL)validateExtendedTag:(NSString *)tag;

/**
 Returns the complete ISO-639-1 language code list
 */
@property (nonatomic, readonly) NSArray<NSString *> *ISO_639_1Languages;

/**
 Returns the complete ISO-639-2 language code list
 */
@property (nonatomic, readonly) NSArray<NSString *> *ISO_639_2Languages;

/**
 Returns the extended languages list in the current locale
 */
@property (nonatomic, readonly) NSArray<NSString *> *localizedExtendedLanguages;

@end

NS_ASSUME_NONNULL_END
