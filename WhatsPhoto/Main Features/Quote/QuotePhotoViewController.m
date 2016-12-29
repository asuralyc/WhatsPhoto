//
//  QuotePhotoViewController.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/8/1.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "QuotePhotoViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AHKActionSheet.h"
#import "UIImageView+WebCache.h"
#import "MBProgressHUD.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "WXApi.h"

@interface QuotePhotoViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *photoImageView;
@property (nonatomic, weak) MBProgressHUD *loadingHud;
@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) UIDocumentInteractionController * documentInteractionController;

- (void)cancelAction;
- (void)showMoreAction;
- (BOOL)lineImage:(UIImage *)image;
- (BOOL)whatsappImage:(UIImage *)image;
- (BOOL)fbMessengerImage:(UIImage *)image;
- (BOOL)wechatImage:(UIImage *)image thumbnail:(UIImage *)thumbnail;
- (void)imageWithURL:(NSURL *)url block:(void (^)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished))block;
- (void)tapOnPhoto:(UITapGestureRecognizer *)tapgr;
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;

@end

@implementation QuotePhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"Quote Photo";
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send Photo", nil) style:UIBarButtonItemStylePlain target:self action:@selector(showMoreAction)];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.scrollView.delegate = self;
    self.scrollView.userInteractionEnabled = YES;
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 4;
    self.scrollView.backgroundColor = [UIColor blackColor];
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
    [self.view addSubview:self.scrollView];
    
    self.photoImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.photoImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.photoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.photoImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnPhoto:)];
    tapgr.numberOfTapsRequired = 2;
    [self.photoImageView addGestureRecognizer:tapgr];
    [self.scrollView addSubview:self.photoImageView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.screenName = @"Quote Photo";
    
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame)-self.scrollView.contentInset.left-self.scrollView.contentInset.right, CGRectGetHeight(self.view.frame)-self.scrollView.contentInset.top-self.scrollView.contentInset.bottom);
    self.photoImageView.frame = CGRectMake(CGRectGetMinX(self.photoImageView.frame), CGRectGetMinY(self.photoImageView.frame), self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    PFFile *imageFile = self.quote[@"image"];
    NSString *originalUrlString = imageFile.url;
    __weak UIImageView *weakImageView = self.photoImageView;
    
    [weakImageView setImageWithURL:[NSURL URLWithString:originalUrlString] placeholderImage:[UIImage imageNamed:@"placeholder-avatar"] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        if (!self.loadingHud) {
            self.loadingHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.loadingHud.mode = MBProgressHUDModeDeterminateHorizontalBar;
        }

        self.loadingHud.progress = (float)receivedSize/expectedSize;
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (self.loadingHud) {
            self.loadingHud.progress = 1;
            [self.loadingHud hide:YES];
        }
        if (cacheType == SDImageCacheTypeNone) {
            [UIView animateWithDuration:0.1 animations:^{
                weakImageView.alpha = 1;
                weakImageView.layer.opacity = 1;
            }];
        } else {
            weakImageView.alpha = 1;
        }
    }];
}

#pragma mark - private

- (void)cancelAction {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)showMoreAction {
    AHKActionSheet *actionSheet = [[AHKActionSheet alloc] initWithTitle:self.quote[@"title"]];
    actionSheet.titleTextAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:14.0f], NSForegroundColorAttributeName:[UIColor whiteColor]};
    actionSheet.cancelButtonTitle = NSLocalizedString(@"Cancel", nil);
    actionSheet.automaticallyTintButtonImages = NO;
    actionSheet.animationDuration = 0.25;
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"LINE", nil)
                              image:[UIImage imageNamed:@"quote_cell_line_icon.png"]
                               type:AHKActionSheetButtonTypeDefault
                            handler:^(AHKActionSheet *as) {
                                PFFile *imageFile = self.quote[@"image"];
                                NSString *originalUrlString = [imageFile url];
                                [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                    if (image) {
                                        BOOL isSend = [self lineImage:image];
                                        if (isSend) {
                                            [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": self.quote.objectId, @"increment": @1}
                                                                        block:^(id object, NSError *error) {
                                                                            if (!error) {}
                                                                        }];
                                        }
                                        
                                        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote photo more_share"
                                                                                              action:@"LINE"
                                                                                               label:self.quote.objectId
                                                                                               value:nil] build]];
                                    }
                                }];
                            }];
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"FB Messenger", nil)
                              image:[UIImage imageNamed:@"quote_cell_fbmessenger_icon.png"]
                               type:AHKActionSheetButtonTypeDefault
                            handler:^(AHKActionSheet *as) {
                                PFFile *imageFile = self.quote[@"image"];
                                NSString *originalUrlString = [imageFile url];
                                [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                    if (image) {
                                        BOOL isSend = [self fbMessengerImage:image];
                                        if (isSend) {
                                            [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": self.quote.objectId, @"increment": @1}
                                                                        block:^(id object, NSError *error) {
                                                                            if (!error) {}
                                                                        }];
                                        }
                                        
                                        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote photo more_share"
                                                                                              action:@"FBMessenger"
                                                                                               label:self.quote.objectId
                                                                                               value:nil] build]];
                                    }
                                }];
                            }];
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"WhatsApp", nil)
                              image:[UIImage imageNamed:@"quote_cell_whatsapp_icon.png"]
                               type:AHKActionSheetButtonTypeDefault
                            handler:^(AHKActionSheet *as) {
                                PFFile *imageFile = self.quote[@"image"];
                                NSString *originalUrlString = [imageFile url];
                                [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                    if (image) {
                                        BOOL isSend = [self whatsappImage:image];
                                        if (isSend) {
                                            [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": self.quote.objectId, @"increment": @1}
                                                                        block:^(id object, NSError *error) {
                                                                            if (!error) {}
                                                                        }];
                                        }
                                        
                                        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote photo more_share"
                                                                                              action:@"WhatsApp"
                                                                                               label:self.quote.objectId
                                                                                               value:nil] build]];
                                    }
                                }];
                            }];
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"WeChat", nil)
                              image:[UIImage imageNamed:@"quote_cell_wechat_icon.png"]
                               type:AHKActionSheetButtonTypeDefault
                            handler:^(AHKActionSheet *as) {
                                PFFile *imageFile = self.quote[@"image"];
                                NSString *originalUrlString = [imageFile url];
                                [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                    if (image) {
                                        PFFile *thumbnailFile = self.quote[@"thumbnail"];
                                        NSString *thumbnailUrlString = [thumbnailFile url];
                                        [self imageWithURL:[NSURL URLWithString:thumbnailUrlString] block:^(UIImage *thumbImage, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                            if (thumbImage) {
                                                BOOL isSend = [self wechatImage:image thumbnail:thumbImage];
                                                if (isSend) {
                                                    [PFCloud callFunctionInBackground:@"incrementUseCount" withParameters:@{@"quoteId": self.quote.objectId, @"increment": @1}
                                                                                block:^(id object, NSError *error) {
                                                                                    if (!error) {}
                                                                                }];
                                                }
                                            }
                                        }];
                                        
                                        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote photo more_share"
                                                                                              action:@"WeChat"
                                                                                               label:self.quote.objectId
                                                                                               value:nil] build]];
                                    }
                                }];
                            }];

    [actionSheet addButtonWithTitle:NSLocalizedString(@"Save to Camera Roll", nil)
                              image:[UIImage imageNamed:@"quote_cell_save_to_camera_roll_icon.png"]
                               type:AHKActionSheetButtonTypeDefault
                            handler:^(AHKActionSheet *as) {
                                PFFile *imageFile = self.quote[@"image"];
                                NSString *originalUrlString = [imageFile url];
                                [self imageWithURL:[NSURL URLWithString:originalUrlString] block:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                    if (image) {
                                        NSData *imageData = UIImageJPEGRepresentation(image, 1);
                                        self.library = [[ALAssetsLibrary alloc] init];
                                        
                                        NSString *albumName = NSLocalizedString(@"KPTaipei", nil);
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
                                        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote photo more_share"
                                                                                              action:@"SaveToCameraRoll"
                                                                                               label:self.quote.objectId
                                                                                               value:nil] build]];
                                    }
                                }];
                            }];
    
    // TODO: Facebook, twitter
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Report", nil)
                              image:nil
                               type:AHKActionSheetButtonTypeDestructive
                            handler:^(AHKActionSheet *as) {
                                [UIAlertView alertViewWithTitle:NSLocalizedString(@"Report", nil) message:NSLocalizedString(@"Report this content?", nil) cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@[NSLocalizedString(@"Report", nil)] onDismiss:^(int buttonIndex) {
                                    [PFCloud callFunctionInBackground:@"incrementReportCount" withParameters:@{@"quoteId": self.quote.objectId, @"increment": @1}
                                                                block:^(id object, NSError *error) {
                                                                    if (!error) {}
                                                                }];
                                    
                                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = NSLocalizedString(@"Thank you for your report.", nil);
                                    [hud hide:YES afterDelay:1];
                                    
                                    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                                    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"quote photo more_share"
                                                                                          action:@"Report"
                                                                                           label:self.quote.objectId
                                                                                           value:nil] build]];
                                } onCancel:^{
                                }];
                            }];
    [actionSheet show];
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

- (void)tapOnPhoto:(UITapGestureRecognizer *)tapgr {
    if(self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    } else {
        float newScale = [self.scrollView zoomScale]*self.scrollView.maximumZoomScale;
        CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[tapgr locationInView:tapgr.view]];
        [self.scrollView zoomToRect:zoomRect animated:YES];
    }
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    // the zoom rect is in the content view's coordinates.
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [self.scrollView frame].size.height / scale;
    zoomRect.size.width = [self.scrollView frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    for (id view in scrollView.subviews) {
        if ([view isMemberOfClass:[UIImageView class]]) {
            return view;
        }
    }
    return nil;
}

@end
