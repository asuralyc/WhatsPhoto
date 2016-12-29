//
//  AppConfig.h
//  WhatsPhoto
//
//  Created by Sapp on 12/7/21.
//  Copyright (c) 2012年 Sapp. All rights reserved.
//

#import "AppConfig.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

NSString *const TMPushDataTypeKey = @"d";
NSString *const TMPushValueKey = @"v";
NSString *const TMPushTitleKey = @"t";

NSString *const TMPushDataTypeOutLink = @"o";
NSString *const TMPushDataTypeWebLink = @"w";
NSString *const TMPushDataTypeSearchKeyword = @"s";

NSString *const TMAppTokenUpdateNotification = @"TM_APP_TOKEN_UPDATE_NOTIFICATION";
NSString *const TMRequestLoginNotification = @"TM_REQUEST_LOGIN_NOTIFICATION";
NSString *const TMLoginoutNotification = @"TM_LOGINOUT_NOTIFICATION";
NSString *const TMUpdateFavoritePostIdsNotification = @"TM_UPDATE_FAVORITE_POST_IDS_NOTIFICATION";

NSString *const TMUpdateLocaleNotification = @"TM_UPDATE_LOCALE_NOTIFICATION";

NSString *const kTMWorldwideLocale = @"Worldwide";

CGFloat const kTMPostTopPadding = 10;
CGFloat const kTMPostBottomPadding = 15;
CGFloat const kTMPostCommentDefaultHeight = 89;
CGFloat const kTMPostCommentTailAdjust = 8;

int const kTMTokenLimit = 30;

NSInteger const kTMPagingOffset = 30;

@interface AppConfig ()

@property (nonatomic, strong) NSNumber *defaultIMNumber;

- (DefaultIM)checkPopularIM;

@end

@implementation AppConfig

- (void)dealloc {
}

+ (AppConfig *)shareInstance {
    static AppConfig *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AppConfig alloc] init];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"locale"] != nil) {
            instance.locale = [[NSUserDefaults standardUserDefaults] objectForKey:@"locale"];
        } else {// load default
            instance.locale = [[NSLocale preferredLanguages] objectAtIndex:0];
            
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"setting default_locale"
                                                                  action:instance.locale
                                                                   label:nil
                                                                   value:nil] build]];
        }
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"defaultIM"] != nil) {
            instance.defaultIMNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultIM"];
        } else {// load default
            [instance setDefaultIM:[instance checkPopularIM]];
        }
    });
    return instance;
}

- (void)setLocale:(NSString *)locale {
    if (locale) {
        if ([_locale isEqualToString:locale]) {
            return;
        }
        _locale = locale;
    } else {
        _locale = [[NSLocale preferredLanguages] objectAtIndex:0];
    }
    [[NSUserDefaults standardUserDefaults] setObject:_locale forKey:@"locale"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TMUpdateLocaleNotification object:self];
}

#pragma mark - public

- (void)setDefaultIM:(DefaultIM)defaultIM {
    self.defaultIMNumber = [NSNumber numberWithInt:defaultIM];
    [[NSUserDefaults standardUserDefaults] setObject:self.defaultIMNumber forKey:@"defaultIM"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TMUpdateLocaleNotification object:self];// for pop all view controller
}

- (DefaultIM)defaultIM {
    return [self.defaultIMNumber intValue];
}

- (NSString *)nameForDefaultIM {//:(DefaultIM)defaultIM {
    if (self.defaultIM == DefaultIMWhatsApp) {
        return @"WhatsApp";
    } else if (self.defaultIM == DefaultIMLINE) {
        return @"LINE";
    } else if (self.defaultIM == DefaultIMWeChat) {
        return @"WeChat";
    } else if (self.defaultIM == DefaultIMFBMessenger) {
        return @"FBMessenger";
    }
    
    return @"UNKNOWN";
}

- (BOOL)isWorldwideLocale {
    return [self.locale isEqualToString:kTMWorldwideLocale];
}

- (NSString *)getUploadLocale {
    if ([self.locale isEqualToString:kTMWorldwideLocale]) {
        return [[NSLocale preferredLanguages] objectAtIndex:0];
    } else {
        return self.locale;
    }
}

#pragma mark - private

- (DefaultIM)checkPopularIM {
    NSString *locale = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSArray *linePopularLocale = @[@"zh-Hant", @"ja", @"ko", @"th", @"id"];
    
    // check LINE
    for (NSString *lineLocale in linePopularLocale) {
        if ([locale isEqualToString:lineLocale]) {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"line://"]]){
                return DefaultIMLINE;
            } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://app"]]){
                return DefaultIMWhatsApp;
            } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]]) {
                return DefaultIMWeChat;
            } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb-messenger-api://"]]) {
                return DefaultIMFBMessenger;
            }
            return DefaultIMLINE;
        }
    }
    
    // check WeChat
    if ([locale isEqualToString:@"zh-Hans"]) {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]]){
            return DefaultIMWeChat;
        } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://app"]]){
            return DefaultIMWhatsApp;
        } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"line://"]]) {
            return DefaultIMLINE;
        } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb-messenger-api://"]]) {
            return DefaultIMFBMessenger;
        }
        return DefaultIMWeChat;
    }
    
    // check WhatsApp
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://app"]]){
        return DefaultIMWhatsApp;
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"line://"]]){
        return DefaultIMLINE;
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]]) {
        return DefaultIMWeChat;
    } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb-messenger-api://"]]) {
        return DefaultIMFBMessenger;
    }

    return DefaultIMWhatsApp;
}

@end
