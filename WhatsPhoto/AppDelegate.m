//
//  AppDelegate.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/7/17.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "AppDelegate.h"
#import <Crashlytics/Crashlytics.h>
#import "GAI.h"
#import <Parse/Parse.h>
#import <FacebookSDK/FBSessionTokenCachingStrategy.h>
#import <FacebookSDK/FacebookSDK.h>
#import "UIAlertView+MKBlockAdditions.h"
#import "MBProgressHUD.h"
#import "AppConfig.h"
#import "QuoteViewController.h"
#import "SearchViewController.h"
#import "SettingViewController.h"
#import "WXApi.h"

@interface AppDelegate () <WXApiDelegate> {
    id _updateLocaleObserver;
}

@property (nonatomic, strong) UITabBarController *tabbarController;

- (void)appearanceInit;
- (void)clearNotifications;
- (void)handleNotificationWithDataType:(NSString *)dataType key:(NSString *)key userInfo:(NSDictionary *)userInfo;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if defined (CRASHLYTICS_API_KEY)
    [Crashlytics startWithAPIKey:CRASHLYTICS_API_KEY];
#endif
    [Parse setApplicationId:PARSE_APPLICATION_ID clientKey:PARSE_CLIENT_KEY];
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double counting
        // the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];// iOS Silent Push notifications (for background mode)
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    // Optional: set Logger to VERBOSE for debug information.
    //    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    // Initialize tracker.
#if defined (GA_ID)
    __unused id <GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GA_ID];
#endif
    
    [PFFacebookUtils initializeFacebook];
#if defined (WX_ID)
    [WXApi registerApp:WX_ID];
#endif
    
    [AppConfig shareInstance];// init

    // setup Anonymous PFUser
    [PFUser enableAutomaticUser];// for Anonymous
    PFUser *user = [PFUser currentUser];
    [user incrementKey:@"runCount"];
    user[@"systemLocale"] = [[NSLocale preferredLanguages] objectAtIndex:0];
    user[@"selectedLocale"] = [AppConfig shareInstance].locale;
    user[@"selectedIM"] = [[AppConfig shareInstance] nameForDefaultIM];
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            if (!user.ACL) {// using second saveInBackgroundWithBlock because Parse.com bug https://parse.com/questions/acl-error-with-saveeventually
                user.ACL = [PFACL ACLWithUser:user];
                [user saveInBackground];
            }
        }
    }];
        
    _updateLocaleObserver = [[NSNotificationCenter defaultCenter] addObserverForName:TMUpdateLocaleNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        NSArray *viewControllers = self.tabbarController.viewControllers;
        for (int i = 0; i < [viewControllers count]; ++i) {
            UINavigationController *nav = [viewControllers objectAtIndex:i];
            if (i != [viewControllers count]-1) {// if not Setting View Controller
                [nav popToRootViewControllerAnimated:NO];
            }
        }
        
        // update selectedLocale and selectedIM
        PFUser *user = [PFUser currentUser];
        user[@"systemLocale"] = [[NSLocale preferredLanguages] objectAtIndex:0];
        user[@"selectedLocale"] = [AppConfig shareInstance].locale;
        user[@"selectedIM"] = [[AppConfig shareInstance] nameForDefaultIM];
        [user saveInBackground];
    }];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    [self clearNotifications];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    QuoteViewController *qvc = [[QuoteViewController alloc] init];
    qvc.title = NSLocalizedString(@"Explore", nil);
    qvc.showLanguageLeftBarButton = YES;
    UINavigationController *qnav = [[UINavigationController alloc] initWithRootViewController:qvc];
    qnav.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Explore", nil) image:[UIImage imageNamed:@"tabbar_favorite.png"] tag:0];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        qnav.tabBarItem.selectedImage = [UIImage imageNamed:@"tabbar_selected_favorite.png"];
    }
    
    SearchViewController *svc = [[SearchViewController alloc] init];
    svc.title = NSLocalizedString(@"Search", nil);
    UINavigationController *snav = [[UINavigationController alloc] initWithRootViewController:svc];
    snav.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Search", nil) image:[UIImage imageNamed:@"tabbar_search.png"] tag:0];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        snav.tabBarItem.selectedImage = [UIImage imageNamed:@"tabbar_selected_search.png"];
    }
    
    SettingViewController *settingvc = [[SettingViewController alloc] init];
    settingvc.title = NSLocalizedString(@"Setting", nil);
    UINavigationController *settingnav = [[UINavigationController alloc] initWithRootViewController:settingvc];
    settingnav.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Setting", nil) image:[UIImage imageNamed:@"tabbar_setting.png"] tag:0];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        settingnav.tabBarItem.selectedImage = [UIImage imageNamed:@"tabbar_selected_setting.png"];
    }
    
    self.tabbarController = [[UITabBarController alloc] init];
    [self.tabbarController setViewControllers:@[qnav, snav, settingnav]];
    
    self.window.rootViewController = self.tabbarController;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(remoteNotification){
        // push notification check 1/3
        NSString *dataType = [remoteNotification objectForKey:TMPushDataTypeKey];
        NSString *key = [remoteNotification objectForKey:TMPushValueKey];
        [self handleNotificationWithDataType:dataType key:key userInfo:remoteNotification];// first run app
        //        }
    }
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // push notification
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (application.applicationState == UIApplicationStateInactive) {
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    [self clearNotifications];
    
    // form Inactive to Active status
    if([application applicationState] == UIApplicationStateInactive){
        // push notification check 2/3
        NSString *dataType = [userInfo objectForKey:TMPushDataTypeKey];
        NSString *key = [userInfo objectForKey:TMPushValueKey];
        [self handleNotificationWithDataType:dataType key:key userInfo:userInfo];// from background to foreword
        return;
    }
    
    // Active status
    // push notification check 3/3
    [UIAlertView alertViewWithTitle:NSLocalizedString(@"Message", nil) message:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] cancelButtonTitle:NSLocalizedString(@"Skip", nil) otherButtonTitles:@[NSLocalizedString(@"View", nil)] onDismiss:^(int buttonIndex) {
        NSString *dataType = [userInfo objectForKey:TMPushDataTypeKey];
        NSString *key = [userInfo objectForKey:TMPushValueKey];
        // TODO: by sapp, must more graceful (not just UIAlertView)
        [self handleNotificationWithDataType:dataType key:key userInfo:userInfo];// active run
    } onCancel:^{
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    
    [self clearNotifications];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Facebook style method
    // Facebook SDK * pro-tip *
    // if the app is going away, we close the session object; this is a good idea because
    // things may be hanging off the session, that need releasing (completion block, etc.) and
    // other components in the app may be awaiting close notification in order to do cleanup
    [FBSession.activeSession close];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
#if defined (WX_ID)
    if ([url.absoluteString hasPrefix:WX_ID]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
#endif
    
    // facebook
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
#if defined (WX_ID)
    if ([url.absoluteString hasPrefix:WX_ID]) {
        return [WXApi handleOpenURL:url delegate:self];
    }
#endif
    
    return [PFFacebookUtils handleOpenURL:url];
}

#pragma mark - private

- (void)appearanceInit {
}

- (void)clearNotifications {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)handleNotificationWithDataType:(NSString *)dataType key:(NSString *)key userInfo:(NSDictionary *)userInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([dataType isEqualToString:TMPushDataTypeOutLink]) {// open in safari
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:key]];
        } else if ([dataType isEqualToString:TMPushDataTypeWebLink]) {// show link in app webview
        } else if ([dataType isEqualToString:TMPushDataTypeSearchKeyword]) {// searchKeyword for SearchProductListViewController
        } else {// normal message
            // no-op
        }
        
    });
}

#pragma mark - WXApiDelegate

- (void)onReq:(BaseReq *)req {
//    NSLog(@"%s %@", __FUNCTION__, req);
}

- (void)onResp:(BaseResp *)resp {
//    NSLog(@"%s %@", __FUNCTION__, resp);
//    NSLog(@"%d, %d", resp.type, resp.errCode);
//    NSLog(@"error = %@", resp.errStr);
    
//    WXSuccess           = 0,
//    WXErrCodeCommon     = -1,
//    WXErrCodeUserCancel = -2,
//    WXErrCodeSentFail   = -3,
//    WXErrCodeAuthDeny   = -4,
//    WXErrCodeUnsupport  = -5,
    
}

@end
