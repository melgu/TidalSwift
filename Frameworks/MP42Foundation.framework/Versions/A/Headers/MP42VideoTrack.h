//
//  MP42VideoTrack.h
//  Subler
//
//  Created by Damiano Galassi on 31/01/09.
//  Copyright 2020 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MP42Foundation/MP42Track.h>

@interface MP42VideoTrack : MP42Track <NSSecureCoding, NSCopying>

@property(nonatomic, readwrite) uint64_t width;
@property(nonatomic, readwrite) uint64_t height;

@property(nonatomic, readwrite) float trackWidth;
@property(nonatomic, readwrite) float trackHeight;

@property(nonatomic, readwrite) CGAffineTransform transform;

// Color
@property(nonatomic, readwrite) uint16_t colorPrimaries;
@property(nonatomic, readwrite) uint16_t transferCharacteristics;
@property(nonatomic, readwrite) uint16_t matrixCoefficients;

// Pixel Aspect Ratio
@property(nonatomic, readwrite) uint64_t hSpacing;
@property(nonatomic, readwrite) uint64_t vSpacing;

// Clean Aperture
@property(nonatomic, readwrite) uint64_t cleanApertureWidthN;
@property(nonatomic, readwrite) uint64_t cleanApertureWidthD;
@property(nonatomic, readwrite) uint64_t cleanApertureHeightN;
@property(nonatomic, readwrite) uint64_t cleanApertureHeightD;
@property(nonatomic, readwrite) uint64_t horizOffN;
@property(nonatomic, readwrite) uint64_t horizOffD;
@property(nonatomic, readwrite) uint64_t vertOffN;
@property(nonatomic, readwrite) uint64_t vertOffD;

// H.264 profile
@property(nonatomic, readwrite) uint8_t origProfile;
@property(nonatomic, readwrite) uint8_t origLevel;
@property(nonatomic, readwrite) uint8_t newProfile;
@property(nonatomic, readwrite) uint8_t newLevel;

@end
