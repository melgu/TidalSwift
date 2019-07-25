//
//  MP42MetadataFormat.h
//  MP42Foundation
//
//  Created by Damiano Galassi on 07/10/2016.
//  Copyright © 2016 Damiano Galassi. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *localizedMetadataKeyName(NSString  *key);

// Common Metadata keys
extern NSString *const MP42MetadataKeyName;                     // String
extern NSString *const MP42MetadataKeyTrackSubTitle;            // String

extern NSString *const MP42MetadataKeyAlbum;                    // String
extern NSString *const MP42MetadataKeyAlbumArtist;              // String
extern NSString *const MP42MetadataKeyArtist;                   // String

extern NSString *const MP42MetadataKeyGrouping;                 // String
extern NSString *const MP42MetadataKeyUserComment;              // String
extern NSString *const MP42MetadataKeyUserGenre;                // String
extern NSString *const MP42MetadataKeyReleaseDate;              // Date

extern NSString *const MP42MetadataKeyTrackNumber;              // Array<Int>
extern NSString *const MP42MetadataKeyDiscNumber;               // Array<Int>
extern NSString *const MP42MetadataKeyBeatsPerMin;              // Int

extern NSString *const MP42MetadataKeyKeywords;                 // String
extern NSString *const MP42MetadataKeyCategory;                 // String
extern NSString *const MP42MetadataKeyCredits;                  // String
extern NSString *const MP42MetadataKeyThanks;                   // String
extern NSString *const MP42MetadataKeyCopyright;                // String

extern NSString *const MP42MetadataKeyDescription;              // String
extern NSString *const MP42MetadataKeyLongDescription;          // String
extern NSString *const MP42MetadataKeySeriesDescription;        // String
extern NSString *const MP42MetadataKeySongDescription;          // String

extern NSString *const MP42MetadataKeyRating;                   // String
extern NSString *const MP42MetadataKeyRatingAnnotation;         // String
extern NSString *const MP42MetadataKeyContentRating;            // Int

extern NSString *const MP42MetadataKeyCoverArt;                 // MP42Image
extern NSString *const MP42MetadataKeyMediaKind;                // Int
extern NSString *const MP42MetadataKeyGapless;                  // Bool
extern NSString *const MP42MetadataKeyHDVideo;                  // Int
extern NSString *const MP42MetadataKeyiTunesU;                  // Bool
extern NSString *const MP42MetadataKeyPodcast;                  // Bool

// Encoding Metadata keys
extern NSString *const MP42MetadataKeyEncodedBy;                // String
extern NSString *const MP42MetadataKeyEncodingTool;             // String

// Movie and TV Show Specific keys
extern NSString *const MP42MetadataKeyStudio;                   // String
extern NSString *const MP42MetadataKeyCast;                     // Array<String>
extern NSString *const MP42MetadataKeyDirector;                 // Array<String>
extern NSString *const MP42MetadataKeyCodirector;               // Array<String>
extern NSString *const MP42MetadataKeyProducer;                 // Array<String>
extern NSString *const MP42MetadataKeyExecProducer;             // String
extern NSString *const MP42MetadataKeyScreenwriters;            // Array<String>

// TV Show Specific Metadata keys
extern NSString *const MP42MetadataKeyTVShow;                   // String
extern NSString *const MP42MetadataKeyTVEpisodeNumber;          // Int
extern NSString *const MP42MetadataKeyTVNetwork;                // String
extern NSString *const MP42MetadataKeyTVEpisodeID;              // String
extern NSString *const MP42MetadataKeyTVSeason;                 // Int

// Songs Specific Metadata Keys
extern NSString *const MP42MetadataKeyArtDirector;              // String
extern NSString *const MP42MetadataKeyComposer;                 // String
extern NSString *const MP42MetadataKeyArranger;                 // String
extern NSString *const MP42MetadataKeyAuthor;                   // String
extern NSString *const MP42MetadataKeyLyrics;                   // String
extern NSString *const MP42MetadataKeyAcknowledgement;          // String
extern NSString *const MP42MetadataKeyConductor;                // String
extern NSString *const MP42MetadataKeyLinerNotes;               // String
extern NSString *const MP42MetadataKeyRecordCompany;            // String
extern NSString *const MP42MetadataKeyOriginalArtist;           // String
extern NSString *const MP42MetadataKeyPhonogramRights;          // String
extern NSString *const MP42MetadataKeySongProducer;             // String
extern NSString *const MP42MetadataKeyPerformer;                // String
extern NSString *const MP42MetadataKeyPublisher;                // String
extern NSString *const MP42MetadataKeySoundEngineer;            // String
extern NSString *const MP42MetadataKeySoloist;                  // String
extern NSString *const MP42MetadataKeyDiscCompilation;          // String

// Classic Music Specific Metadata Keys
extern NSString *const MP42MetadataKeyWorkName;                 // String
extern NSString *const MP42MetadataKeyMovementName;             // String
extern NSString *const MP42MetadataKeyMovementNumber;           // Int
extern NSString *const MP42MetadataKeyMovementCount;            // Int
extern NSString *const MP42MetadataKeyShowWorkAndMovement;      // Bool

// iTunes Store Metadata keys
extern NSString *const MP42MetadataKeyXID;                      // String
extern NSString *const MP42MetadataKeyArtistID;                 // Int
extern NSString *const MP42MetadataKeyComposerID;               // Int
extern NSString *const MP42MetadataKeyContentID;                // Int
extern NSString *const MP42MetadataKeyGenreID;                  // Int
extern NSString *const MP42MetadataKeyPlaylistID;               // Int
extern NSString *const MP42MetadataKeyAppleID;                  // String
extern NSString *const MP42MetadataKeyAccountKind;              // Int
extern NSString *const MP42MetadataKeyAccountCountry;           // Int
extern NSString *const MP42MetadataKeyPurchasedDate;            // Date
extern NSString *const MP42MetadataKeyOnlineExtras;             // String

// Sort Metadata Keys
extern NSString *const MP42MetadataKeySortName;                 // String
extern NSString *const MP42MetadataKeySortArtist;               // String
extern NSString *const MP42MetadataKeySortAlbumArtist;          // String
extern NSString *const MP42MetadataKeySortAlbum;                // String
extern NSString *const MP42MetadataKeySortComposer;             // String
extern NSString *const MP42MetadataKeySortTVShow;               // String
