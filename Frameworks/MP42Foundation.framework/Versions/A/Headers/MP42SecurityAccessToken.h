//
//  MP42SecurityAccessToken.h
//  MP42Foundation
//
//  Created by Damiano Galassi on 10/03/2019.
//  Copyright © 2019 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MP42SecurityScope <NSObject>

/*  Given an instance, make the resource referenced by the job accessible to the process.
 */
- (BOOL)startAccessingSecurityScopedResource;

/*  Revokes the access granted to the url by a prior successful call to startAccessingSecurityScopedResource.
 */
- (void)stopAccessingSecurityScopedResource;

@end

@interface NSURL (MP42SecurityScope) <MP42SecurityScope>

- (BOOL)startAccessingSecurityScopedResource;
- (void)stopAccessingSecurityScopedResource;

@end

@interface MP42SecurityAccessToken : NSObject

+ (instancetype)tokenWithObject:(id<MP42SecurityScope>)object;
- (instancetype)initWithObject:(id<MP42SecurityScope>)object;

+ (nullable NSURL *)URLFromBookmark:(NSData *)bookmark bookmarkDataIsStale:(BOOL * _Nullable)isStale error:(NSError **)error;
+ (nullable NSData *)bookmarkFromURL:(NSURL *)url options:(NSURLBookmarkCreationOptions)options error:(NSError **)error;
+ (nullable NSData *)bookmarkFromURL:(NSURL *)url error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
