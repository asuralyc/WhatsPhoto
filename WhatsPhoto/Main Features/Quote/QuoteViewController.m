//
//  QuoteViewController.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/7/18.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "QuoteViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <FacebookSDK/FacebookSDK.h>
#import "GADBannerView.h"
#import "GADRequest.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "SVPullToRefresh.h"
#import "AHKActionSheet.h"
#import "SDWebImageManager.h"
#import "MBProgressHUD.h"
#import "AddQuoteViewController.h"
#import "QuoteTableViewCell.h"
#import "QuotePhotoViewController.h"
#import "SettingLocaleViewController.h"
#import "WXApi.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "AppConfig.h"

// test for vpon
#import "VpadnBanner.h"

typedef enum _QuoteSortType {
    QuoteSortTypeUsed,
//    QuoteSortTypeFavorite,
    QuoteSortTypeNew,
} QuoteSortType;

@interface QuoteViewController () <UITableViewDataSource, UITableViewDelegate, UIDocumentInteractionControllerDelegate, QuoteTableViewCellDelegate, GADBannerViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *quoteMArray;
@property (nonatomic, assign) NSInteger itemOffset;
@property (nonatomic, strong) NSMutableDictionary *extendedTokenIndexDictionary;
@property (nonatomic, strong) UISegmentedControl *sortTypeSegmentedControl;
@property (nonatomic, strong) NSString *currentResultLocale;
@property (nonatomic, assign) DefaultIM currentDefaultIM;
@property (nonatomic, strong) UIDocumentInteractionController * documentInteractionController;
@property (nonatomic, weak) MBProgressHUD *loadingHud;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) UIImage *sharedImage;
@property (nonatomic, strong) PFObject *sharedQuote;

#if defined (AD_NORMAL_ID)
@property (nonatomic, strong) GADBannerView *adBannerView;
#endif
@property (nonatomic, strong) VpadnBanner *vpadnAd;

- (void)changeLanguageAction;
- (void)addAction;
- (void)queryQuotes;
- (void)queryNextQuotes;
- (void)typeChanged;
- (BOOL)lineImage:(UIImage *)image;
- (BOOL)whatsappImage:(UIImage *)image;
- (BOOL)wechatImage:(UIImage *)image thumbnail:(UIImage *)thumbnail;
- (BOOL)fbMessengerImage:(UIImage *)image;
- (void)imageWithURL:(NSURL *)url block:(void (^)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished))block;

@end

@implementation QuoteViewController

- (void)dealloc {
#if defined (AD_NORMAL_ID)
    self.adBannerView.delegate = nil;
#endif
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"Explore";
    
    self.sortTypeSegmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"Hot", nil), NSLocalizedString(@"New", nil), nil]];
    self.sortTypeSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.sortTypeSegmentedControl.selectedSegmentIndex = QuoteSortTypeUsed;
    [self.sortTypeSegmentedControl addTarget:self action:@selector(typeChanged) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.sortTypeSegmentedControl;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-50) style:UITableViewStylePlain];// 320x50 for ad
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 104;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.extendedLayoutIncludesOpaqueBars = YES;
        UIEdgeInsets currentInset = self.tableView.contentInset;
        currentInset.top = self.navigationController.navigationBar.bounds.size.height;
        // On iOS7, you need plus the height of status bar.
        currentInset.top += 20;
        self.tableView.contentInset = currentInset;
    }
    
    // setup pull-to-refresh
    __weak QuoteViewController *weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf queryQuotes];
    }];
    self.tableView.pullToRefreshView.arrowColor = UIColorFromRGB(0xdddddd);//UIColorFromRGB(0xEDABBC);
    self.tableView.pullToRefreshView.textColor = UIColorFromRGB(0xdddddd);//UIColorFromRGB(0xEDABBC);
    [self.tableView.pullToRefreshView setTitle:NSLocalizedString(@"Pull down to refresh...", nil) forState:SVPullToRefreshStateStopped];
    [self.tableView.pullToRefreshView setTitle:NSLocalizedString(@"Loading...", nil) forState:SVPullToRefreshStateLoading];
    [self.tableView.pullToRefreshView setTitle:NSLocalizedString(@"Release to refresh...", nil) forState:SVPullToRefreshStateTriggered];
    self.tableView.pullToRefreshView.activityIndicatorViewColor = UIColorFromRGB(0xdddddd);//UIColorFromRGB(0xEDABBC);
    
    if (self.showLanguageLeftBarButton) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"navbar_global.png"] style:UIBarButtonItemStylePlain target:self action:@selector(changeLanguageAction)];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction)];
    
    self.currentResultLocale = [AppConfig shareInstance].locale;
    self.currentDefaultIM = [[AppConfig shareInstance] defaultIM];
    
    [self.tableView triggerPullToRefresh];

    // hard code origin
    CGPoint origin = CGPointMake(0, CGRectGetHeight(self.view.bounds)-143);
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        origin = CGPointMake(0, CGRectGetHeight(self.view.bounds)-49-50);
    }
#if defined (AD_NORMAL_ID)
    self.adBannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner origin:origin];
    self.adBannerView.adUnitID = AD_NORMAL_ID;// normal id
    self.adBannerView.delegate = self;
    [self.adBannerView setRootViewController:self];
    [self.view addSubview:self.adBannerView];
    [self.adBannerView loadRequest:[GADRequest request]];
#endif
}

- (void)viewWillAppear:(BOOL)animated {
    if (![self.currentResultLocale isEqualToString:[AppConfig shareInstance].locale]) {
        [self.tableView triggerPullToRefresh];
    } else if (self.currentDefaultIM != [[AppConfig shareInstance] defaultIM]) {
        [self.tableView triggerPullToRefresh];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.screenName = @"Explore";
    // setup infinite scrolling
    __weak QuoteViewController *weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf queryNextQuotes];
    }];
}

#pragma mark - private

- (void)changeLanguageAction {
    SettingLocaleViewController *slvc = [[SettingLocaleViewController alloc] init];
    slvc.title = NSLocalizedString(@"Language", nil);
    slvc.showDoneBarButton = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:slvc];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)addAction {
    AddQuoteViewController *aqvc = [[AddQuoteViewController alloc] init];
    aqvc.title = NSLocalizedString(@"Add a Photo", nil);
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:aqvc];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)queryQuotes {
    self.currentResultLocale = [AppConfig shareInstance].locale;
    self.currentDefaultIM = [[AppConfig shareInstance] defaultIM];
    
    self.itemOffset = 0;
    
    PFQuery *quoteQuery = [PFQuery queryWithClassName:@"Quote"];
    if (self.viewType == QuoteViewTypeTag) {
        [quoteQuery whereKey:@"lowerCaseTags" containedIn:@[[self.viewTypeValue lowercaseString]]];
    } else if (self.viewType == QuoteViewTypeKeyword) {
//        [quoteQuery whereKey:@"title" containsString:self.viewTypeValue];
        [quoteQuery whereKey:@"title" matchesRegex:self.viewTypeValue modifiers:@"i"];
    } else if (self.viewType == QuoteViewTypeKeywordAndTag) {
        PFQuery *quoteContainKeywordQuery = [PFQuery queryWithClassName:@"Quote"];
//        [quoteContainKeywordQuery whereKey:@"title" containsString:self.viewTypeValue];
        [quoteContainKeywordQuery whereKey:@"title" matchesRegex:self.viewTypeValue modifiers:@"i"];
        
        PFQuery *quoteContainTagQuery = [PFQuery queryWithClassName:@"Quote"];
        [quoteContainTagQuery whereKey:@"lowerCaseTags" containedIn:@[[self.viewTypeValue lowercaseString]]];
        quoteQuery = [PFQuery orQueryWithSubqueries:@[quoteContainKeywordQuery, quoteContainTagQuery]];
    }
    [quoteQuery whereKey:@"visibleType" equalTo:@0];
    if (self.viewType != QuoteViewTypeKeywordAndTag && self.viewType != QuoteViewTypeTag) {// skip locale when search tag or keyword
        if (![[AppConfig shareInstance] isWorldwideLocale]) {
            [quoteQuery whereKey:@"locale" equalTo:[AppConfig shareInstance].locale];
        }
    }
    if (self.sortTypeSegmentedControl.selectedSegmentIndex == QuoteSortTypeUsed) {
        [quoteQuery orderByDescending:@"useCount"];
//    } else if (self.sortTypeSegmentedControl.selectedSegmentIndex == QuoteSortTypeFavorite) {
//        [quoteQuery orderByDescending:@"favoriteCount"];
    } else if (self.sortTypeSegmentedControl.selectedSegmentIndex == QuoteSortTypeNew) {
        [quoteQuery orderByDescending:@"createdAt"];
    } else {
        [quoteQuery orderByDescending:@"createdAt"];
    }
    quoteQuery.limit = kTMPagingOffset;
    quoteQuery.skip = self.itemOffset;
    [quoteQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.extendedTokenIndexDictionary = [[NSMutableDictionary alloc] init];
            self.quoteMArray = [[NSMutableArray alloc] init];
            
            [self.quoteMArray addObjectsFromArray:objects];
            self.itemOffset = [objects count];
            
            if ([objects count] < kTMPagingOffset) {
                self.tableView.showsInfiniteScrolling = NO;
            } else {
                self.tableView.showsInfiniteScrolling = YES;
            }
            
            [self.tableView reloadData];
//            if (self.itemOffset > 0) {
//                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
////                self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top*4);
//            }
            
            if (self.tableView.pullToRefreshView.state == SVPullToRefreshStateLoading) {
                [self.tableView.pullToRefreshView stopAnimating];
            }
        } else {// no result
            NSLog(@"error = %@", [error localizedDescription]);
            if (self.tableView.pullToRefreshView.state == SVPullToRefreshStateLoading) {
                [self.tableView.pullToRefreshView stopAnimating];
            }
            // TODO: handle error
            self.tableView.showsInfiniteScrolling = NO;
//            [self.tableView reloadData];
        }
    }];
}

- (void)queryNextQuotes {
    PFQuery *quoteQuery = [PFQuery queryWithClassName:@"Quote"];
    if (self.viewType == QuoteViewTypeTag) {
        [quoteQuery whereKey:@"lowerCaseTags" containedIn:@[[self.viewTypeValue lowercaseString]]];
    } else if (self.viewType == QuoteViewTypeKeyword) {
        [quoteQuery whereKey:@"title" matchesRegex:self.viewTypeValue modifiers:@"i"];
    } else if (self.viewType == QuoteViewTypeKeywordAndTag) {
        PFQuery *quoteContainKeywordQuery = [PFQuery queryWithClassName:@"Quote"];
        [quoteContainKeywordQuery whereKey:@"title" matchesRegex:self.viewTypeValue modifiers:@"i"];
        
        PFQuery *quoteContainTagQuery = [PFQuery queryWithClassName:@"Quote"];
        [quoteContainTagQuery whereKey:@"lowerCaseTags" containedIn:@[[self.viewTypeValue lowercaseString]]];
        quoteQuery = [PFQuery orQueryWithSubqueries:@[quoteContainKeywordQuery, quoteContainTagQuery]];
    }
    [quoteQuery whereKey:@"visibleType" equalTo:@0];
    if (self.viewType != QuoteViewTypeKeywordAndTag && self.viewType != QuoteViewTypeTag) {// skip locale when search tag or keyword
        if (![[AppConfig shareInstance] isWorldwideLocale]) {
            [quoteQuery whereKey:@"locale" equalTo:[AppConfig shareInstance].locale];
        }
    }
    if (self.sortTypeSegmentedControl.selectedSegmentIndex == QuoteSortTypeUsed) {
        [quoteQuery orderByDescending:@"useCount"];
//    } else if (self.sortTypeSegmentedControl.selectedSegmentIndex == QuoteSortTypeFavorite) {
//        [quoteQuery orderByDescending:@"favoriteCount"];
    } else if (self.sortTypeSegmentedControl.selectedSegmentIndex == QuoteSortTypeNew) {
        [quoteQuery orderByDescending:@"createdAt"];
    } else {
        [quoteQuery orderByDescending:@"createdAt"];
    }
    quoteQuery.limit = kTMPagingOffset;
    quoteQuery.skip = self.itemOffset;
    [quoteQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [self.quoteMArray addObjectsFromArray:objects];
            self.itemOffset += [objects count];
            
            if ([objects count] < kTMPagingOffset) {
                self.tableView.showsInfiniteScrolling = NO;
            } else {
                self.tableView.showsInfiniteScrolling = YES;
            }
            
            [self.tableView reloadData];
            
            if (self.tableView.infiniteScrollingView.state == SVInfiniteScrollingStateLoading) {
                [self.tableView.infiniteScrollingView stopAnimating];
            }
        } else {// no result
            NSLog(@"error = %@", [error localizedDescription]);
            if (self.tableView.infiniteScrollingView.state == SVInfiniteScrollingStateLoading) {
                [self.tableView.infiniteScrollingView stopAnimating];
            }
            // TODO: handle error
            self.tableView.showsInfiniteScrolling = NO;
//            [self.tableView reloadData];
        }
    }];
}

- (void)typeChanged {
    if (self.itemOffset > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    [self.tableView triggerPullToRefresh];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote sorttype_changed"
                                                          action:self.sortTypeSegmentedControl.selectedSegmentIndex == 0 ? @"use times" : @"newest"
                                                           label:nil
                                                           value:nil] build]];
}

- (BOOL)lineImage:(UIImage *)image {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"line://"]]) {
        if (image) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.image = image;
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"line://msg/image/%@", pasteboard.name]];
            [[UIApplication sharedApplication] openURL:url];
            return YES;
        }
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = NSLocalizedString(@"LINE not installed", nil);
        [hud hide:YES afterDelay:1];
    }
    return NO;
}

- (BOOL)whatsappImage:(UIImage *)image {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://app"]]){
        NSString *savePath  = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/whatsAppTmp.wai"];
        [UIImagePNGRepresentation(image) writeToFile:savePath atomically:YES];
        self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:savePath]];
        self.documentInteractionController.UTI = @"net.whatsapp.image";
        self.documentInteractionController.delegate = self;
        [self.documentInteractionController presentOpenInMenuFromRect:CGRectMake(0, 0, 0, 0) inView:self.view animated: YES];
        return YES;
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = NSLocalizedString(@"WhatsApp not installed", nil);
        [hud hide:YES afterDelay:1];
    }
    return NO;
}

- (BOOL)wechatImage:(UIImage *)image thumbnail:(UIImage *)thumbnail {
    if ([WXApi isWXAppInstalled]) {
        WXMediaMessage *message = [WXMediaMessage message];
        message.title = @"Some Title";
        message.description = @"Amazing Sunset";
        [message setThumbImage:thumbnail];
        
        WXImageObject *ext = [WXImageObject object];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
        ext.imageData = imageData;
        
        message.mediaObject = ext;
        
        SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
        req.bText = NO;
        req.message = message;
        req.scene = WXSceneSession;
        [WXApi sendReq:req];
        return YES;
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = NSLocalizedString(@"WeChat not installed", nil);
        [hud hide:YES afterDelay:1];
    }
    return NO;
}

- (BOOL)fbMessengerImage:(UIImage *)image {
    if ([FBDialogs canPresentMessageDialogWithPhotos]) {
        FBPhotoParams *params = [[FBPhotoParams alloc] init];
        params.photos = @[image];
        
        [FBDialogs presentMessageDialogWithPhotoParams:params
                                           clientState:nil
                                               handler:^(FBAppCall *call,
                                                         NSDictionary *results,
                                                         NSError *error) {
                                                   if (error) {
                                                       NSLog(@"Error: %@", error.description);
                                                   } else {
                                                       NSLog(@"Success!");
                                                   }
                                               }];
        return YES;
    } else {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = NSLocalizedString(@"Messenger not installed", nil);
        [hud hide:YES afterDelay:1];
    }
    return NO;
}

- (void)imageWithURL:(NSURL *)url block:(void (^)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished))block {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadWithURL:url options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        if (!self.loadingHud) {
            self.loadingHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.loadingHud.mode = MBProgressHUDModeAnnularDeterminate;
            self.loadingHud.minSize = CGSizeMake(104, 104);
            self.loadingHud.labelText = NSLocalizedString(@"Loading...", nil);
        }
        self.loadingHud.progress = (float)receivedSize/expectedSize;
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
        if (self.loadingHud) {
            self.loadingHud.progress = 1;
            [self.loadingHud hide:YES];
        }
        if (block) {
            block(image, error, cacheType, finished);
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.quoteMArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    QuoteTableViewCell *cell = (QuoteTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[QuoteTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    PFObject *quote = [self.quoteMArray objectAtIndex:indexPath.row];
    
    cell.quote = quote;
    cell.delegate = self;
    NSString *key = [NSString stringWithFormat:@"%d", indexPath.row];
    if ([self.extendedTokenIndexDictionary objectForKey:key]) {
        cell.extendedTokenField = YES;
    } else {
        cell.extendedTokenField = NO;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *quote = [self.quoteMArray objectAtIndex:indexPath.row];
    
    CGFloat cellHeight = self.tableView.rowHeight+kQuoteMenuHeight;
    CGSize titleSizeToFit = [quote[@"title"] sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:14] constrainedToSize:CGSizeMake(300-144, CGFLOAT_MAX) lineBreakMode:NSLineBreakByTruncatingTail];
    CGFloat titleHeight = ceilf(titleSizeToFit.height);
    if (titleHeight > kMinTitleLabelHeight) {// title exceed default height
        cellHeight += (titleHeight-kMinTitleLabelHeight);
    }
    
    if ([quote[@"tags"] count] == 0) {// no tags
        return cellHeight;
    }
    
    NSString *key = [NSString stringWithFormat:@"%d", indexPath.row];
    if ([self.extendedTokenIndexDictionary objectForKey:key]) {
        CGFloat tokenHeight = [QuoteTableViewCell calculateHeightForTokens:quote[@"tags"] filedWidth:kQuoteTokenFieldWidth];
        return cellHeight+tokenHeight;
    } else {
        return cellHeight+[QuoteTableViewCell singleLineTokenFieldHeight];
    }
}

#pragma mark - QuoteTableViewCellDelegate

- (void)showPhotoWithQuoteTableViewCell:(QuoteTableViewCell *)cell {
    PFFile *imageFile = cell.quote[@"image"];
    QuotePhotoViewController *qpvc = [[QuotePhotoViewController alloc] init];
    qpvc.quote = cell.quote;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:qpvc];
    nav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:nav animated:YES completion:NULL];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote tap_on_photo"
                                                          action:imageFile.url
                                                           label:cell.quote.objectId
                                                           value:nil] build]];
}

- (void)quoteTableViewCell:(QuoteTableViewCell *)cell didSelectTokenTitle:(NSString *)title {
    QuoteViewController *qvc = [[QuoteViewController alloc] init];
    qvc.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Tag", nil), title];
    qvc.viewType = QuoteViewTypeTag;
    qvc.viewTypeValue = title;
    [self.navigationController pushViewController:qvc animated:YES];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote tap_on_tag"
                                                          action:title
                                                           label:cell.quote.objectId
                                                           value:nil] build]];
}

- (void)extendTokenFieldWithQuoteTableViewCell:(QuoteTableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSString *key = [NSString stringWithFormat:@"%d", indexPath.row];
    [self.extendedTokenIndexDictionary setObject:key forKey:key];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote show_all_tags"
                                                          action:cell.quote.objectId
                                                           label:nil
                                                           value:nil] build]];
}

- (void)favoriteWithQuoteTableViewCell:(QuoteTableViewCell *)cell {
    // TODO: next feature
}

- (void)messageWithQuoteTableViewCell:(QuoteTableViewCell *)cell {
    PFFile *imageFile = cell.quote[@"image"];
    NSString *originalUrlString = [imageFile url];
    [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
        if (image) {
            NSString *imName = @"LINE";
            BOOL isSend = NO;
            if ([[AppConfig shareInstance] defaultIM] == DefaultIMLINE) {
                isSend = [self lineImage:image];
                imName = @"LINE";
            } else if ([[AppConfig shareInstance] defaultIM] == DefaultIMWhatsApp) {
                isSend = [self whatsappImage:image];
                imName = @"WhatsApp";
            } else if ([[AppConfig shareInstance] defaultIM] == DefaultIMWeChat) {
                if (cell.thumbImage) {
                    isSend = [self wechatImage:image thumbnail:cell.thumbImage];
                } else {
                    PFFile *thumbnailFile = cell.quote[@"thumbnail"];
                    NSString *thumbnailUrlString = [thumbnailFile url];
                    [self imageWithURL:[NSURL URLWithString:thumbnailUrlString] block:^(UIImage *thumbImage, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                        if (thumbImage) {
                            BOOL isSend = [self wechatImage:image thumbnail:thumbImage];
                            if (isSend) {
                                [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": cell.quote.objectId, @"increment": @1}
                                                            block:^(id object, NSError *error) {
                                                                if (!error) {}
                                                            }];
                            }
                            
                            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote default_messsage"
                                                                                  action:imName
                                                                                   label:cell.quote.objectId
                                                                                   value:nil] build]];
                        }
                    }];
                    return;// hard code return, and send GA in block
                }
                imName = @"WeChat";
            } else if ([[AppConfig shareInstance] defaultIM] == DefaultIMFBMessenger) {
                isSend = [self fbMessengerImage:image];
                imName = @"FBMessenger";
            }
            
            if (isSend) {
                [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": cell.quote.objectId, @"increment": @1}
                                            block:^(id object, NSError *error) {
                                                if (!error) {}
                                            }];
            }
            
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote default_messsage"
                                                                  action:imName
                                                                   label:cell.quote.objectId
                                                                   value:nil] build]];
        }
    }];
}

- (void)moreWithQuoteTableViewCell:(QuoteTableViewCell *)cell {
    AHKActionSheet *actionSheet = [[AHKActionSheet alloc] initWithTitle:NSLocalizedString(@"Send photo to your friends", nil)];
    actionSheet.cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    actionSheet.automaticallyTintButtonImages = NO;
    actionSheet.animationDuration = 0.25;
    
    if ([[AppConfig shareInstance] defaultIM] != DefaultIMLINE) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"LINE", nil)
                                  image:[UIImage imageNamed:@"quote_cell_line_icon.png"]
                                   type:AHKActionSheetButtonTypeDefault
                                handler:^(AHKActionSheet *as) {
                                    PFFile *imageFile = cell.quote[@"image"];
                                    NSString *originalUrlString = [imageFile url];
                                    [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                        if (image) {
                                            BOOL isSend = [self lineImage:image];
                                            if (isSend) {
                                                [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": cell.quote.objectId, @"increment": @1}
                                                                            block:^(id object, NSError *error) {
                                                                                if (!error) {}
                                                                            }];
                                            }
                                            
                                            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote more_share"
                                                                                                  action:@"LINE"
                                                                                                   label:cell.quote.objectId
                                                                                                   value:nil] build]];
                                        }
                                    }];
                                }];
    }
    if ([[AppConfig shareInstance] defaultIM] != DefaultIMWhatsApp) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"WhatsApp", nil)
                                  image:[UIImage imageNamed:@"quote_cell_whatsapp_icon.png"]
                                   type:AHKActionSheetButtonTypeDefault
                                handler:^(AHKActionSheet *as) {
                                    PFFile *imageFile = cell.quote[@"image"];
                                    NSString *originalUrlString = [imageFile url];
                                    [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                        if (image) {
                                            BOOL isSend = [self whatsappImage:image];
                                            if (isSend) {
                                                [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": cell.quote.objectId, @"increment": @1}
                                                                            block:^(id object, NSError *error) {
                                                                                if (!error) {}
                                                                            }];
                                            }
                                            
                                            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote more_share"
                                                                                                  action:@"WhatsApp"
                                                                                                   label:cell.quote.objectId
                                                                                                   value:nil] build]];
                                        }
                                    }];
                                }];
    }
    if ([[AppConfig shareInstance] defaultIM] != DefaultIMWeChat) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"WeChat", nil)
                                  image:[UIImage imageNamed:@"quote_cell_wechat_icon.png"]
                                   type:AHKActionSheetButtonTypeDefault
                                handler:^(AHKActionSheet *as) {
                                    PFFile *imageFile = cell.quote[@"image"];
                                    NSString *originalUrlString = [imageFile url];
                                    [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                        if (image) {
                                            if (cell.thumbImage) {
                                                BOOL isSend = [self wechatImage:image thumbnail:cell.thumbImage];
                                                if (isSend) {
                                                    [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": cell.quote.objectId, @"increment": @1}
                                                                                block:^(id object, NSError *error) {
                                                                                    if (!error) {}
                                                                                }];
                                                }
                                            } else {
                                                PFFile *thumbnailFile = cell.quote[@"thumbnail"];
                                                NSString *thumbnailUrlString = [thumbnailFile url];
                                                [self imageWithURL:[NSURL URLWithString:thumbnailUrlString] block:^(UIImage *thumbImage, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                    if (thumbImage) {
                                                        BOOL isSend = [self wechatImage:image thumbnail:thumbImage];
                                                        if (isSend) {
                                                            [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": cell.quote.objectId, @"increment": @1}
                                                                                        block:^(id object, NSError *error) {
                                                                                            if (!error) {}
                                                                                        }];
                                                        }
                                                    }
                                                }];
                                            }
                                            
                                            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote more_share"
                                                                                                  action:@"WeChat"
                                                                                                   label:cell.quote.objectId
                                                                                                   value:nil] build]];
                                        }
                                    }];
                                }];
    }
    
    if ([[AppConfig shareInstance] defaultIM] != DefaultIMFBMessenger) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"FB Messenger", nil)
                                  image:[UIImage imageNamed:@"quote_cell_fbmessenger_icon.png"]
                                   type:AHKActionSheetButtonTypeDefault
                                handler:^(AHKActionSheet *as) {
                                    PFFile *imageFile = cell.quote[@"image"];
                                    NSString *originalUrlString = [imageFile url];
                                    [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                        if (image) {
                                            BOOL isSend = [self fbMessengerImage:image];
                                            if (isSend) {
                                                [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": cell.quote.objectId, @"increment": @1}
                                                                            block:^(id object, NSError *error) {
                                                                                if (!error) {}
                                                                            }];
                                            }
                                            
                                            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote more_share"
                                                                                                  action:@"FBMessenger"
                                                                                                   label:cell.quote.objectId
                                                                                                   value:nil] build]];
                                        }
                                    }];
                                }];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Save to Camera Roll", nil)
                              image:[UIImage imageNamed:@"quote_cell_save_to_camera_roll_icon.png"]
                               type:AHKActionSheetButtonTypeDefault
                            handler:^(AHKActionSheet *as) {
                                PFFile *imageFile = cell.quote[@"image"];
                                NSString *originalUrlString = [imageFile url];
                                [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                    if (image) {
//                                        [self save to camera roll];
                                        NSData *imageData = UIImageJPEGRepresentation(image, 1);
                                        self.library = [[ALAssetsLibrary alloc] init];
                                        
                                        NSString *albumName = NSLocalizedString(@"WhatsPhoto", nil);
                                        [self.library writeImageDataToSavedPhotosAlbum:imageData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                                            if (!error) {
                                                // show alert
                                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                                hud.mode = MBProgressHUDModeText;
                                                hud.labelText = NSLocalizedString(@"Photo saved", nil);
                                                [hud hide:YES afterDelay:1];
                                                
                                                // add to album
                                                __block BOOL albumWasFound = NO;
                                                //search all photo albums in the library
                                                [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                                    if ([albumName compare:[group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
                                                        albumWasFound = YES;
                                                        [self.library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                                                            [group addAsset: asset];
                                                        } failureBlock:NULL];
                                                        return;
                                                    }
                                                    
                                                    if (!group && !albumWasFound) {
                                                        __weak ALAssetsLibrary* weakLibrary = self.library;
                                                        [self.library addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group) {
                                                            [weakLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                                                                [group addAsset: asset];
                                                            } failureBlock:NULL];
                                                        } failureBlock:NULL];
                                                        return;
                                                    }
                                                } failureBlock:NULL];
                                            }
                                        }];
                                        
                                        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote more_share"
                                                                                              action:@"SaveToCameraRoll"
                                                                                               label:cell.quote.objectId
                                                                                               value:nil] build]];
                                    }
                                }];
                            }];
#if defined (ADMIN_MODE)
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Hide this photo", nil)
                              image:nil
                               type:AHKActionSheetButtonTypeDestructive
                            handler:^(AHKActionSheet *as) {
                                
                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                hud.mode = MBProgressHUDModeText;
                                hud.labelText = NSLocalizedString(@"hidding...", nil);
                                
                                [PFCloud callFunctionInBackground:@"markQuoteAsHidden" withParameters:@{@"quoteId": cell.quote.objectId}
                                                            block:^(id object, NSError *error) {
                                                                hud.labelText = !error ? NSLocalizedString(@"Success", nil) : NSLocalizedString(@"Fail", nil);
                                                                [hud hide:YES afterDelay:1];
                                                            }];
                            }];
#endif
    
    // TODO: Facebook, twitter
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Report", nil)
                              image:nil
                               type:AHKActionSheetButtonTypeDestructive
                            handler:^(AHKActionSheet *as) {
                                [UIAlertView alertViewWithTitle:NSLocalizedString(@"Report", nil) message:NSLocalizedString(@"Report this content?", nil) cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@[NSLocalizedString(@"Report", nil)] onDismiss:^(int buttonIndex) {
                                    [PFCloud callFunctionInBackground:@"incrementReportCount" withParameters:@{@"quoteId": cell.quote.objectId, @"increment": @1}
                                                                block:^(id object, NSError *error) {
                                                                    if (!error) {}
                                                                }];
                                    
                                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = NSLocalizedString(@"Thank you for your report.", nil);
                                    [hud hide:YES afterDelay:1];
                                    
                                    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote more_share"
                                                                                          action:@"Report"
                                                                                           label:cell.quote.objectId
                                                                                           value:nil] build]];
                                } onCancel:^{
                                }];
                            }];
    [actionSheet show];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application {
}

#pragma mark - GADBannerViewDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)view {
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView {
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
}

@end
