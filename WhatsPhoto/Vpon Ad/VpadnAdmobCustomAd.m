//
//  VpadnAdmobCustomAd.m
//  BalinMediaiton_Banner
//
//  Created by Kelly on 13/12/24.
//  Copyright (c) 2013年 Vpadn. All rights reserved.
//

#import "VpadnAdmobCustomAd.h"
#import "GADCustomEventBanner.h"
#import "GADCustomEventRequest.h"
#import "VpadnBanner.h"

@interface VpadnAdmobCustomAd () <GADCustomEventBanner, VpadnBannerDelegate>

@property (nonatomic, strong) VpadnBanner *vpadnBannerAd;

@end

@implementation VpadnAdmobCustomAd

// Will be set by the AdMob SDK.
@synthesize delegate = _delegate;

#pragma mark - GADCustomEventBanner

- (void)dealloc {
    if (_delegate) {
        _delegate = nil;
    }
    self.vpadnBannerAd.delegate = nil;
}

- (void)requestBannerAd:(GADAdSize)adSize parameter:(NSString *)serverParameter label:(NSString *)serverLabel request:(GADCustomEventRequest *)request {
    UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
    CGPoint origin = CGPointMake(0.0,0.0);
    NSString *strSizeType = NSStringFromGADAdSize(adSize);
    VpadnAdSize vpadnAdSize = VpadnAdSizeSmartBannerPortrait;
    if ([strSizeType isEqualToString:@"kGADAdSizeBanner"]) {
        vpadnAdSize = VpadnAdSizeBanner;
    } else if ([strSizeType isEqualToString:@"kGADAdSizeFullBanner"]) {
        vpadnAdSize = VpadnAdSizeFullBanner;
    } else if ([strSizeType isEqualToString:@"kGADAdSizeLeaderboard"]) {
        vpadnAdSize = VpadnAdSizeLeaderboard;
    } else if ([strSizeType isEqualToString:@"kGADAdSizeSmartBannerLandscape"]) {
        vpadnAdSize = VpadnAdSizeSmartBannerLandscape;
    } else if ([strSizeType isEqualToString:@"kGADAdSizeMediumRectangle"]) {
        vpadnAdSize = VpadnAdSizeMediumRectangle;
    }
    
    self.vpadnBannerAd.delegate = nil;
    self.vpadnBannerAd = [[VpadnBanner alloc] initWithAdSize:vpadnAdSize origin:origin];
    self.vpadnBannerAd.strBannerId = serverParameter;
    self.vpadnBannerAd.delegate = self;
    self.vpadnBannerAd.platform = @"TW";
    [self.vpadnBannerAd setAdAutoRefresh:NO];
    [self.vpadnBannerAd setRootViewController:window.rootViewController];
    [self.vpadnBannerAd startGetAd:[self getTestIdentifiers]];
//    NSLog(@"serverParameter = %@", serverParameter);
}

- (void)onVpadnGetAd:(UIView *)bannerView {
    [bannerView removeFromSuperview];
    [self.delegate customEventBanner:self didReceiveAd:bannerView];
}

- (void)onVpadnAdReceived:(UIView *)bannerView {
    // 通知拉取廣告成功pre-fetch完成
//    NSLog(@"%s", __FUNCTION__);
}

- (void)onVpadnAdFailed:(UIView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    // 通知拉取廣告失敗
    [self.delegate customEventBanner:self didFailAd:error];
//    NSLog(@"%s, error = %@", __FUNCTION__, [error localizedDescription]);
}

- (void)onVpadnPresent:(UIView *)bannerView {
    // 通知開啟vpadn廣告頁面
    [self.delegate customEventBannerWillPresentModal:self];
}

- (void)onVpadnDismiss:(UIView *)bannerView {
    // 通知關閉vpadn廣告頁面
    [self.delegate customEventBannerDidDismissModal:self];
}

#pragma mark 通知離開publisher application
- (void)onVpadnLeaveApplication:(UIView *)bannerView {
    [self.delegate customEventBannerWillLeaveApplication:self];
}

-(NSArray*)getTestIdentifiers {
    // add your test Id
    return [NSArray arrayWithObjects:nil];
}

@end
