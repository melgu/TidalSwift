//
//  MP42MediaFormat.h
//  Subler
//
//  Created by Damiano Galassi on 08/08/13.
//
//

#import <Foundation/Foundation.h>

/* MP4 primitive types */
typedef void*       MP42FileHandle;
typedef uint32_t    MP42TrackId;
typedef uint64_t    MP42Duration;

// File Type
extern NSString *const MP42FileTypeMP4;
extern NSString *const MP42FileTypeM4V;
extern NSString *const MP42FileTypeM4A;
extern NSString *const MP42FileTypeM4B;
extern NSString *const MP42FileTypeM4R;

NSString *localizedMediaDisplayName(FourCharCode mediaType);
NSString *localizedDisplayName(FourCharCode mediaType, FourCharCode mediaSubtype);

#include <TargetConditionals.h>
#if TARGET_RT_BIG_ENDIAN
#   define FourCC2Str(fourcc) (const char[]){*((char*)&fourcc), *(((char*)&fourcc)+1), *(((char*)&fourcc)+2), *(((char*)&fourcc)+3),0}
#else
#   define FourCC2Str(fourcc) (const char[]){*(((char*)&fourcc)+3), *(((char*)&fourcc)+2), *(((char*)&fourcc)+1), *(((char*)&fourcc)+0),0}
#endif

#define Str2FourCC(str) (str[0] << 24) + (str[1] << 16) + (str[2] << 8) + str[3]


typedef FourCharCode MP42MediaType;
enum : MP42MediaType
{
    kMP42MediaType_Unknown = 'unkn'
};

// Media Type
enum : MP42MediaType
{
    kMP42MediaType_Video            = 'vide',
    kMP42MediaType_Audio            = 'soun',
    kMP42MediaType_Muxed            = 'muxx',
    kMP42MediaType_Text				= 'text',
    kMP42MediaType_ClosedCaption    = 'clcp',
    kMP42MediaType_Subtitle			= 'sbtl',
    kMP42MediaType_TimeCode			= 'tmcd',
    kMP42MediaType_Metadata			= 'meta',
    kMP42MediaType_OD               = 'odsm',
    kMP42MediaType_Scene            = 'sdsm',
    kMP42MediaType_Subpic           = 'subp',
    kMP42MediaType_Hint             = 'hint',
    kMP42MediaType_Control          = 'cnlt'
};

typedef FourCharCode MP42CodecType;

// Video Format
typedef FourCharCode MP42VideoCodecType;
enum : MP42VideoCodecType
{
    kMP42VideoCodecType_Animation           = 'rle ',
    kMP42VideoCodecType_Cinepak             = 'cvid',
    kMP42VideoCodecType_JPEG                = 'jpeg',
    kMP42VideoCodecType_JPEG_OpenDML        = 'dmb1',
    kMP42VideoCodecType_PNG                 = 'png ',

    kMP42VideoCodecType_H263                = 'h263',
    kMP42VideoCodecType_H264                = 'avc1',
    kMP42VideoCodecType_H264_PSinBitstream  = 'avc3',
    kMP42VideoCodecType_HEVC                = 'hvc1',
    kMP42VideoCodecType_HEVC_PSinBitstream  = 'hev1',
    kMP42VideoCodecType_MPEG4Video          = 'mp4v',
    kMP42VideoCodecType_MPEG2Video          = 'mp2v',
    kMP42VideoCodecType_MPEG1Video          = 'mp1v',
    kMP42VideoCodecType_SorensonVideo       = 'SVQ1',
    kMP42VideoCodecType_SorensonVideo3      = 'SVQ3',

    kMP42VideoCodecType_Theora              = 'XiTh',
    kMP42VideoCodecType_VP8                 = 'VP8 ',
    kMP42VideoCodecType_VP9                 = 'VP9 ',
    kMP42VideoCodecType_AV1                 = 'av01',

    kMP42VideoCodecType_AppleProRes4444     = 'ap4h',
    kMP42VideoCodecType_AppleProRes422HQ    = 'apch',
    kMP42VideoCodecType_AppleProRes422      = 'apcn',
    kMP42VideoCodecType_AppleProRes422LT    = 'apcs',
    kMP42VideoCodecType_AppleProRes422Proxy = 'apco',

    kMP42VideoCodecType_DVCNTSC             = 'dvc ',
    kMP42VideoCodecType_DVCPAL              = 'dvcp',
    kMP42VideoCodecType_DVCProPAL           = 'dvpp',
    kMP42VideoCodecType_DVCPro50NTSC        = 'dv5n',
    kMP42VideoCodecType_DVCPro50PAL         = 'dv5p',
    kMP42VideoCodecType_DVCPROHD720p60      = 'dvhp',
    kMP42VideoCodecType_DVCPROHD720p50      = 'dvhq',
    kMP42VideoCodecType_DVCPROHD1080i60     = 'dvh6',
    kMP42VideoCodecType_DVCPROHD1080i50     = 'dvh5',
    kMP42VideoCodecType_DVCPROHD1080p30     = 'dvh3',
    kMP42VideoCodecType_DVCPROHD1080p25     = 'dvh2',

    kMP42VideoCodecType_XAVC_Long_GOP       = 'xalg',

    kMP42VideoCodecType_FairPlay            = 'drmi',
};

// Audio Format
typedef FourCharCode MP42AudioCodecType;
enum : MP42AudioCodecType
{
    kMP42AudioCodecType_LinearPCM               = 'lpcm',
    kMP42AudioCodecType_AC3                     = 'ac-3',
    kMP42AudioCodecType_60958AC3                = 'cac3',
    kMP42AudioCodecType_AppleIMA4               = 'ima4',
    kMP42AudioCodecType_MPEG4AAC                = 'aac ',
    kMP42AudioCodecType_MPEG4CELP               = 'celp',
    kMP42AudioCodecType_MPEG4HVXC               = 'hvxc',
    kMP42AudioCodecType_MPEG4TwinVQ             = 'twvq',
    kMP42AudioCodecType_MACE3                   = 'MAC3',
    kMP42AudioCodecType_MACE6                   = 'MAC6',
    kMP42AudioCodecType_ULaw                    = 'ulaw',
    kMP42AudioCodecType_ALaw                    = 'alaw',
    kMP42AudioCodecType_QDesign                 = 'QDMC',
    kMP42AudioCodecType_QDesign2                = 'QDM2',
    kMP42AudioCodecType_QUALCOMM                = 'Qclp',
    kMP42AudioCodecType_MPEGLayer1              = '.mp1',
    kMP42AudioCodecType_MPEGLayer2              = '.mp2',
    kMP42AudioCodecType_MPEGLayer3              = '.mp3',
    kMP42AudioCodecType_TimeCode                = 'time',
    kMP42AudioCodecType_MIDIStream              = 'midi',
    kMP42AudioCodecType_ParameterValueStream    = 'apvs',
    kMP42AudioCodecType_AppleLossless           = 'alac',
    kMP42AudioCodecType_MPEG4AAC_HE             = 'aach',
    kMP42AudioCodecType_MPEG4AAC_LD             = 'aacl',
    kMP42AudioCodecType_MPEG4AAC_ELD            = 'aace',
    kMP42AudioCodecType_MPEG4AAC_ELD_SBR        = 'aacf',
    kMP42AudioCodecType_MPEG4AAC_ELD_V2         = 'aacg',
    kMP42AudioCodecType_MPEG4AAC_HE_V2          = 'aacp',
    kMP42AudioCodecType_MPEG4AAC_Spatial        = 'aacs',
    kMP42AudioCodecType_AMR                     = 'samr',
    kMP42AudioCodecType_AMR_WB                  = 'sawb',
    kMP42AudioCodecType_Audible                 = 'AUDB',
    kMP42AudioCodecType_iLBC                    = 'ilbc',
    kMP42AudioCodecType_DVIIntelIMA             = 0x6D730011,
    kMP42AudioCodecType_MicrosoftGSM            = 0x6D730031,
    kMP42AudioCodecType_AES3                    = 'aes3',
    kMP42AudioCodecType_EnhancedAC3             = 'ec-3',
    kMP42AudioCodecType_FLAC                    = 'flac',
    kMP42AudioCodecType_Vorbis                  = 'XiVs',
    kMP42AudioCodecType_DTS                     = 'DTS ',
    kMP42AudioCodecType_TrueHD                  = 'trhd',
    kMP42AudioCodecType_MLP                     = 'mlp ',
    kMP42AudioCodecType_Opus                    = 'opus',
    kMP42AudioCodecType_TTA                     = 'TTA1',

    kMP42AudioCodecType_FairPlay                = 'drms',
    kMP42AudioCodecType_FairPlay_AAC            = 'paac',
    kMP42AudioCodecType_FairPlay_AC3            = 'pac3'
};

// Audio Stream Extension
typedef FourCharCode MP42AudioEmbeddedExtension;
enum : MP42AudioEmbeddedExtension
{
    // EC3
    kMP42AudioEmbeddedExtension_JOC        = 'joc ',
    kMP42AudioEmbeddedExtension_None       = 0
};

// Subtitle Format
typedef FourCharCode MP42SubtitleCodecType;
enum : MP42SubtitleCodecType
{
    kMP42SubtitleCodecType_Text      = 'text',
    kMP42SubtitleCodecType_3GText    = 'tx3g',
    kMP42SubtitleCodecType_WebVTT    = 'wvtt',
    kMP42SubtitleCodecType_VobSub    = 'subp',
    kMP42SubtitleCodecType_PGS       = 'PGS ',
    kMP42SubtitleCodecType_SSA       = 'SSA ',
    kMP42SubtitleCodecType_FairPlay  = 'drmt'
};

// Closed Caption Fromat
typedef FourCharCode MP42ClosedCaptionCodecType;
enum : MP42ClosedCaptionCodecType
{
    kMP42ClosedCaptionCodecType_CEA608	 = 'c608',
    kMP42ClosedCaptionCodecType_CEA708	 = 'c708',
    kMP42ClosedCaptionCodecType_ATSC     = 'atcc',
    kMP42ClosedCaptionCodecType_FairPlay = 'p608'
};

// TimeCode Format
typedef FourCharCode MP42TimeCodeFormatType;
enum : MP42TimeCodeFormatType
{
    kMP42TimeCodeFormatType_TimeCode32	= 'tmcd',
    kMP42TimeCodeFormatType_TimeCode64	= 'tc64',
    kCMP42TimeCodeFormatType_Counter32  = 'cn32',
    kMP42TimeCodeFormatType_Counter64   = 'cn64'
};

// Metadata Format
typedef FourCharCode MP42MetadataFormatType;
enum : MP42MetadataFormatType
{
    kMP42MetadataFormatType_TimedMetadata = 'mebx',
};

// Audio downmixes
typedef SInt64 MP42AudioMixdown;
enum : MP42AudioMixdown
{
    kMP42AudioMixdown_None       = 5,
    kMP42AudioMixdown_Mono       = 4,
    kMP42AudioMixdown_Stereo     = 3,
    kMP42AudioMixdown_Dolby      = 2,
    kMP42AudioMixdown_DolbyPlII  = 1
};
