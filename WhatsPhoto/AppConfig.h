//
//  AppConfig.h
//  WhatsPhoto
//
//  Created by Sapp on 12/7/21.
//  Copyright (c) 2012年 Sapp. All rights reserved.
//

#ifndef WHATSPHOTO_AppConfig_h
#define WHATSPHOTO_AppConfig_h

//#define CRASHLYTICS_API_KEY @""
//#define GA_ID @""
//#define WX_ID @""
//#define AD_NORMAL_ID @""

#define PARSE_APPLICATION_ID @""
#define PARSE_CLIENT_KEY @""

//#define ADMIN_MODE

UIKIT_EXTERN NSString *const TMPushDataTypeKey;
UIKIT_EXTERN NSString *const TMPushValueKey;
UIKIT_EXTERN NSString *const TMPushTitleKey;

UIKIT_EXTERN NSString *const TMPushDataTypeOutLink;
UIKIT_EXTERN NSString *const TMPushDataTypeWebLink;
UIKIT_EXTERN NSString *const TMPushDataTypeSearchKeyword;

UIKIT_EXTERN NSString *const TMAppTokenUpdateNotification;
UIKIT_EXTERN NSString *const TMRequestLoginNotification;
UIKIT_EXTERN NSString *const TMLoginoutNotification;
UIKIT_EXTERN NSString *const TMUpdateFavoritePostIdsNotification;

UIKIT_EXTERN NSString *const TMUpdateLocaleNotification;

UIKIT_EXTERN NSString *const kTMWorldwideLocale;

UIKIT_EXTERN CGFloat const kTMPostTopPadding;
UIKIT_EXTERN CGFloat const kTMPostBottomPadding;
UIKIT_EXTERN CGFloat const kTMPostCommentDefaultHeight;
UIKIT_EXTERN CGFloat const kTMPostCommentTailAdjust;

UIKIT_EXTERN int const kTMTokenLimit;

UIKIT_EXTERN NSInteger const kTMPagingOffset;

typedef enum _DefaultIM {
    DefaultIMWhatsApp,
    DefaultIMLINE,
    DefaultIMWeChat,
    DefaultIMFBMessenger,
    DefaultIMCount,
} DefaultIM;

@interface AppConfig : NSObject

+ (AppConfig *)shareInstance;

@property (nonatomic, strong) NSString *locale;

- (void)setDefaultIM:(DefaultIM)defaultIM;
- (DefaultIM)defaultIM;
- (NSString *)nameForDefaultIM;//:(DefaultIM)defaultIM;// for PFUser selectedIM

- (BOOL)isWorldwideLocale;
- (NSString *)getUploadLocale;

@end

#endif
