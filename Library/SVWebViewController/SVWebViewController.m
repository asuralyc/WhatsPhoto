//
//  SVWebViewController.m
//
//  Created by Sam Vermette on 08.11.10.
//  Copyright 2010 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import "SVWebViewController.h"
#import "SVPullToRefresh.h"
#import "UIAlertView+MKBlockAdditions.h"
//#import "AppConfig.h"
//#import "MBProgressHUD.h"

//static NSUInteger DeviceSystemMajorVersion() {
//    static NSUInteger deviceSystemMajorVersion;
//    static dispatch_once_t onceToken;
//	dispatch_once(&onceToken, ^{
//		deviceSystemMajorVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] firstObject] intValue];
//	});
//	return deviceSystemMajorVersion;
//}

@interface SVWebViewController () <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong, readonly) UIBarButtonItem *backButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *productInfoBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *actionBarButtonItem;
@property (nonatomic, strong, readonly) UIActionSheet *pageActionSheet;

@property (nonatomic, strong) UIWebView *mainWebView;
@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, readwrite) BOOL justShowWeb;
@property (nonatomic, readwrite) BOOL startFromPush;

- (id)initWithAddress:(NSString*)urlString;
- (id)initWithURL:(NSURL*)URL;
- (void)loadURL:(NSURL*)URL;

- (void)updateToolbarItems;

- (void)backButtonClicked;
- (void)showProductInfoAction:(UIBarButtonItem *)sender;
- (void)goBackClicked:(UIBarButtonItem *)sender;
- (void)goForwardClicked:(UIBarButtonItem *)sender;
- (void)reloadClicked:(UIBarButtonItem *)sender;
- (void)stopClicked:(UIBarButtonItem *)sender;
- (void)actionButtonClicked:(UIBarButtonItem *)sender;

- (void)lineScreenshot;
- (void)lineProductLink;
- (UIImage *)getImageFromView:(UIView *)view;
@end


@implementation SVWebViewController

@synthesize availableActions;

@synthesize URL, mainWebView;
@synthesize backButtonItem, productInfoBarButtonItem, backBarButtonItem, forwardBarButtonItem, actionBarButtonItem, pageActionSheet;

#pragma mark - setters and getters

- (UIBarButtonItem *)backButtonItem {
    if (!backButtonItem) {
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        [backButton setBackgroundImage:[UIImage imageNamed:@"tool_btn_back.png"] forState:UIControlStateNormal];
        [backButton setBackgroundImage:[UIImage imageNamed:@"tool_btn_back.png"] forState:UIControlStateHighlighted];
        [backButton addTarget:self action:@selector(backButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    }
    return backButtonItem;
}

- (UIBarButtonItem *)productInfoBarButtonItem {
    if (!productInfoBarButtonItem) {
        productInfoBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"商品介紹" style:UIBarButtonItemStylePlain target:self action:@selector(showProductInfoAction:)];

    }
    return productInfoBarButtonItem;
}

- (UIBarButtonItem *)backBarButtonItem {
    if (!backBarButtonItem) {
        UIButton *backBarButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        [backBarButton setBackgroundImage:[UIImage imageNamed:@"tool_btn_back_enable.png"] forState:UIControlStateNormal];
        [backBarButton addTarget:self action:@selector(goBackClicked:) forControlEvents:UIControlEventTouchUpInside];
        backBarButton.showsTouchWhenHighlighted = YES;
        backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backBarButton];
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!forwardBarButtonItem) {
        UIButton *forwardBarButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        [forwardBarButton setBackgroundImage:[UIImage imageNamed:@"tool_btn_forward_enable.png"] forState:UIControlStateNormal];
        [forwardBarButton addTarget:self action:@selector(goForwardClicked:) forControlEvents:UIControlEventTouchUpInside];
        forwardBarButton.showsTouchWhenHighlighted = YES;
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:forwardBarButton];
    }
    return forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (!_refreshBarButtonItem) {
        _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadClicked:)];
    }
    return _refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (!_stopBarButtonItem) {
        _stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClicked:)];
    }
    return _stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    if (!actionBarButtonItem) {
        UIButton *actionBarButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        [actionBarButton setBackgroundImage:[UIImage imageNamed:@"tool_btn_open.png"] forState:UIControlStateNormal];
        [actionBarButton addTarget:self action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        actionBarButton.showsTouchWhenHighlighted = YES;
        actionBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionBarButton];
    }
    return actionBarButtonItem;
}

- (UIActionSheet *)pageActionSheet {
    
    if(!pageActionSheet) {
        pageActionSheet = [[UIActionSheet alloc] 
                        initWithTitle:nil//self.mainWebView.request.URL.absoluteString
                        delegate:self 
                        cancelButtonTitle:nil   
                        destructiveButtonTitle:nil   
                        otherButtonTitles:nil]; 
        if((self.availableActions & SVWebViewControllerAvailableActionsLine) == SVWebViewControllerAvailableActionsLine)
            // TODO: NSLocalizedString
            [pageActionSheet addButtonWithTitle:@"馬上 LINE 給好友"];
        
        if((self.availableActions & SVWebViewControllerAvailableActionsCopyLink) == SVWebViewControllerAvailableActionsCopyLink)
            // TODO: NSLocalizedString
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Copy Link", @"SVWebViewController", @"")];
        
        if((self.availableActions & SVWebViewControllerAvailableActionsOpenInSafari) == SVWebViewControllerAvailableActionsOpenInSafari)
            // TODO: NSLocalizedString
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Open in Safari", @"SVWebViewController", @"")];
        
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]] && (self.availableActions & SVWebViewControllerAvailableActionsOpenInChrome) == SVWebViewControllerAvailableActionsOpenInChrome)
            // TODO: NSLocalizedString
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Open in Chrome", @"SVWebViewController", @"")];
        
        if([MFMailComposeViewController canSendMail] && (self.availableActions & SVWebViewControllerAvailableActionsMailLink) == SVWebViewControllerAvailableActionsMailLink)
            // TODO: NSLocalizedString
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Mail Link to this Page", @"SVWebViewController", @"")];
        
        // TODO: NSLocalizedString
        [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"SVWebViewController", @"")];
        pageActionSheet.cancelButtonIndex = [self.pageActionSheet numberOfButtons]-1;
    }
    
    return pageActionSheet;
}

#pragma mark - Initialization

- (id)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (id)initWithURL:(NSURL*)pageURL {
    
    if(self = [super init]) {
        self.URL = pageURL;
        self.availableActions = SVWebViewControllerAvailableActionsOpenInSafari | SVWebViewControllerAvailableActionsOpenInChrome | SVWebViewControllerAvailableActionsMailLink;
    }
    
    return self;
}

- (id)initWithWebURL:(NSURL*)url {
    if(self = [super init]) {
        self.justShowWeb = YES;
        self.URL = url;
        self.availableActions = SVWebViewControllerAvailableActionsOpenInSafari | SVWebViewControllerAvailableActionsOpenInChrome | SVWebViewControllerAvailableActionsMailLink;
    }
    
    return self;
}

- (void)loadURL:(NSURL *)pageURL {
    [mainWebView loadRequest:[NSURLRequest requestWithURL:pageURL]];
//    [MBProgressHUD hideHUDForView:mainWebView animated:YES];
//    [MBProgressHUD showHUDAddedTo:mainWebView animated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.mainWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    self.mainWebView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    mainWebView.delegate = self;
    mainWebView.scalesPageToFit = YES;
    [self loadURL:self.URL];
    if ([[mainWebView subviews] count] > 0) {
        // hide the shadows
        for (UIView* shadowView in [[[mainWebView subviews] objectAtIndex:0] subviews]) {
            [shadowView setHidden:YES];
        }
        // show the content
        [[[[[mainWebView subviews] objectAtIndex:0] subviews] lastObject] setHidden:NO];
    }
    mainWebView.backgroundColor = [UIColor whiteColor];
    
    
    [self.view addSubview:self.mainWebView];
    UIScrollView *sv =  mainWebView.scrollView;
    [sv addPullToRefreshWithActionHandler:^{
        [self reloadClicked:nil];
    }];
    
    
    sv.pullToRefreshView.arrowColor = UIColorFromRGB(0xEDABBC);//UIColorFromRGB(0xF97C85);
    sv.pullToRefreshView.textColor = UIColorFromRGB(0xEDABBC);//UIColorFromRGB(0xF97C85);
    [sv.pullToRefreshView setTitle:@"下拉螢幕以更新" forState:SVPullToRefreshStateStopped];
    [sv.pullToRefreshView setTitle:@"正在更新..." forState:SVPullToRefreshStateLoading];
    [sv.pullToRefreshView setTitle:@"放開螢幕以更新" forState:SVPullToRefreshStateTriggered];
    sv.pullToRefreshView.activityIndicatorViewColor = UIColorFromRGB(0xEDABBC);//UIColorFromRGB(0xF97C85);
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self updateToolbarItems];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    mainWebView = nil;
    backBarButtonItem = nil;
    forwardBarButtonItem = nil;
    actionBarButtonItem = nil;
    pageActionSheet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    NSAssert(self.navigationController, @"SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.");
    
	[super viewWillAppear:animated];
	
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:NO animated:animated];
//        [self.navigationController setNavigationBarHidden:YES animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:YES animated:animated];
//        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)dealloc {
    [mainWebView stopLoading];
 	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    mainWebView.delegate = nil;
}

#pragma mark - Toolbar

- (void)updateToolbarItems {
    self.backBarButtonItem.enabled = self.mainWebView.canGoBack;
    UIButton *backBarButton = (UIButton *)self.backBarButtonItem.customView;
    [backBarButton setBackgroundImage:self.backBarButtonItem.enabled ? [UIImage imageNamed:@"tool_btn_back_enable.png"] : [UIImage imageNamed:@"tool_btn_back_disable.png"] forState:UIControlStateNormal];
    
    self.forwardBarButtonItem.enabled = self.mainWebView.canGoForward;
    UIButton *forwardBarButton = (UIButton *)self.forwardBarButtonItem.customView;
    [forwardBarButton setBackgroundImage:self.forwardBarButtonItem.enabled ? [UIImage imageNamed:@"tool_btn_forward_enable.png"] : [UIImage imageNamed:@"tool_btn_forward_disable.png"] forState:UIControlStateNormal];
    
    
//    UIBarButtonItem *refreshStopBarButtonItem = mainWebView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    
    if (!self.mainWebView.isLoading) {
        UIScrollView *sv =  mainWebView.scrollView;
        if (sv.pullToRefreshView.state == SVPullToRefreshStateLoading) {
            [sv.pullToRefreshView stopAnimating];
        }
        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [MBProgressHUD hideHUDForView:mainWebView animated:YES];
//        });
    }
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        NSArray *items;
    
    if (self.justShowWeb) {
        if(self.availableActions == 0) {
            items = [NSArray arrayWithObjects:
                     self.backButtonItem,
                     flexibleSpace,
                     self.backBarButtonItem,
                     flexibleSpace,
                     self.forwardBarButtonItem,
                     flexibleSpace,
                     nil];
        } else {
            items = [NSArray arrayWithObjects:
//                     self.backButtonItem,
//                     flexibleSpace,
                     self.backBarButtonItem,
                     flexibleSpace,
                     self.forwardBarButtonItem,
                     flexibleSpace,
                     self.actionBarButtonItem,
                     fixedSpace,
                     nil];
        }
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        // ios 7 blur view
    } else {
        [self.navigationController.toolbar setBackgroundImage:[self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault] forToolbarPosition:UIBarPositionBottom barMetrics:UIBarMetricsDefault];
    }
        self.toolbarItems = items;
//    }
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([self.svDelegate respondsToSelector:@selector(svWebView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.svDelegate svWebView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateToolbarItems];
    
    if ([self.svDelegate respondsToSelector:@selector(svWebViewDidStartLoad:)]) {
        [self.svDelegate svWebViewDidStartLoad:webView];
    }
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
//    self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self updateToolbarItems];
    
//    [webView stringByEvaluatingJavaScriptFromString:@"var script = document.createElement('script');"
//     "script.type = 'text/javascript';"
//     "script.text = \"function tmybdelbar() { "
//     "var deck = document.getElementById('deck');"
//     "deck.removeChild(deck.childNodes[0]);"// remove navigation bar
//     "deck.childNodes[0].style.paddingTop = '0px';"// move to top
//     "}\";"
//     "document.getElementsByTagName('head')[0].appendChild(script);"];
//    [webView stringByEvaluatingJavaScriptFromString:@"tmybdelbar();"];

    
    if ([self.svDelegate respondsToSelector:@selector(svWebViewDidFinishLoad:)]) {
        [self.svDelegate svWebViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbarItems];
    
    if ([self.svDelegate respondsToSelector:@selector(svWebView:didFailLoadWithError:)]) {
        [self.svDelegate svWebView:webView didFailLoadWithError:error];
    }
}

#pragma mark - Target actions

- (void)backButtonClicked {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)showProductInfoAction:(UIBarButtonItem *)sender {
    if ([sender.title isEqualToString:@"商品介紹"]) {
        NSString *urlString = self.URL.absoluteString;
        urlString = [urlString stringByReplacingOccurrencesOfString:@"http://tw.buy.yahoo.com/" withString:@"http://m.buy.yahoo.com.tw/"];
        urlString = [urlString stringByReplacingOccurrencesOfString:@"gdsale.asp" withString:@"gdinfo.asp"];
        [self loadURL:[NSURL URLWithString:urlString]];
        sender.title = @"我要購買";
    } else {
        [self loadURL:self.URL];
        sender.title = @"商品介紹";
    }
}

- (void)goBackClicked:(UIBarButtonItem *)sender {
    [mainWebView goBack];
}

- (void)goForwardClicked:(UIBarButtonItem *)sender {
    [mainWebView goForward];
}

- (void)reloadClicked:(UIBarButtonItem *)sender {
    [mainWebView reload];
//    [MBProgressHUD hideHUDForView:mainWebView animated:YES];
//    [MBProgressHUD showHUDAddedTo:mainWebView animated:YES];
}

- (void)stopClicked:(UIBarButtonItem *)sender {
    [mainWebView stopLoading];
	[self updateToolbarItems];
}

- (void)actionButtonClicked:(id)sender {
    
    if(pageActionSheet)
        return;
	
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self.pageActionSheet showFromBarButtonItem:self.actionBarButtonItem animated:YES];
    else
        [self.pageActionSheet showFromToolbar:self.navigationController.toolbar];
    
}

- (void)lineScreenshot {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"line://"]]) {
        UIImage *screenshot = [self getImageFromView:self.mainWebView];
        if (screenshot) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.image = screenshot;
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"line://msg/image/%@", pasteboard.name]];
            [[UIApplication sharedApplication] openURL:url];
        }
    } else {
        // TODO: NSLocalizedString
        [UIAlertView alertViewWithTitle:@"提示訊息" message:@"馬上安裝 LINE 分享照片" cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@[NSLocalizedString(@"Ok", nil)] onDismiss:^(int buttonIndex) {
            NSURL *url = [NSURL URLWithString:@"https://itunes.apple.com/app/line/id443904275"];
            [[UIApplication sharedApplication] openURL:url];
        } onCancel:^{
        }];
    }
}

- (void)lineProductLink {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"line://"]]) {
        NSString *text = self.URL.absoluteString;
        NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                      NULL,
                                                                                      (CFStringRef)text,
                                                                                      NULL,
                                                                                      (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                      kCFStringEncodingUTF8 ));
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"line://msg/text/%@", encodedString]];
        [[UIApplication sharedApplication] openURL:url];
    } else {
        // TODO: NSLocalizedString
        [UIAlertView alertViewWithTitle:@"提示訊息" message:@"馬上安裝 LINE 分享連結" cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@[NSLocalizedString(@"Ok", nil)] onDismiss:^(int buttonIndex) {
            NSURL *url = [NSURL URLWithString:@"https://itunes.apple.com/app/line/id443904275"];
            [[UIApplication sharedApplication] openURL:url];
        } onCancel:^{
        }];
    }
}

- (UIImage *)getImageFromView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)doneButtonClicked:(id)sender {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
    [self dismissModalViewControllerAnimated:YES];
#else
    [self dismissViewControllerAnimated:YES completion:NULL];
#endif
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"馬上 LINE 給好友"]) {
        [self lineProductLink];
    }

//    if ([title isEqualToString:@"馬上 LINE 截圖給好友"]) {
//        [self lineScreenshot];
//    }
    
    // TODO: NSLocalizedString
	if([title localizedCompare:NSLocalizedStringFromTable(@"Open in Safari", @"SVWebViewController", @"")] == NSOrderedSame) {
        [[UIApplication sharedApplication] openURL:self.URL];
    }
    
    // TODO: NSLocalizedString
    if([title localizedCompare:NSLocalizedStringFromTable(@"Open in Chrome", @"SVWebViewController", @"")] == NSOrderedSame) {
//        NSURL *inputURL = self.mainWebView.request.URL;
        NSURL *inputURL = self.URL;
        NSString *scheme = inputURL.scheme;
        
        NSString *chromeScheme = nil;
        if ([scheme isEqualToString:@"http"]) {
            chromeScheme = @"googlechrome";
        } else if ([scheme isEqualToString:@"https"]) {
            chromeScheme = @"googlechromes";
        }
        
        if (chromeScheme) {
            NSString *absoluteString = [inputURL absoluteString];
            NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
            NSString *urlNoScheme =
            [absoluteString substringFromIndex:rangeForScheme.location];
            NSString *chromeURLString =
            [chromeScheme stringByAppendingString:urlNoScheme];
            NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
            
            [[UIApplication sharedApplication] openURL:chromeURL];
        }
    }
    
    // TODO: NSLocalizedString
    if([title localizedCompare:NSLocalizedStringFromTable(@"Copy Link", @"SVWebViewController", @"")] == NSOrderedSame) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        //        pasteboard.string = self.mainWebView.request.URL.absoluteString;
        pasteboard.string = self.URL.absoluteString;
    }
    
    // TODO: NSLocalizedString
    else if([title localizedCompare:NSLocalizedStringFromTable(@"Mail Link to this Page", @"SVWebViewController", @"")] == NSOrderedSame) {
        
		MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        
		mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:[self.mainWebView stringByEvaluatingJavaScriptFromString:@"document.title"]];
//  		[mailViewController setMessageBody:self.mainWebView.request.URL.absoluteString isHTML:NO];
  		[mailViewController setMessageBody:self.URL.absoluteString isHTML:NO];
		mailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
		[self presentModalViewController:mailViewController animated:YES];
#else
        [self presentViewController:mailViewController animated:YES completion:NULL];
#endif
	}
    
    pageActionSheet = nil;
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
	[self dismissModalViewControllerAnimated:YES];
#else
    [self dismissViewControllerAnimated:YES completion:NULL];
#endif
}

@end
