//
//  AddQuoteViewController.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/7/18.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "AddQuoteViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MBProgressHUD.h"
#import "TITokenField.h"
#import "UIImage+Rotate.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "AssetTableViewCell.h"
#import "AppConfig.h"

static const NSTimeInterval TMFadeAnimationDuration = 0.3;
static const CGFloat kMaxImageSize = 1024;// for previewImageView.image
static const CGFloat kMaxUploadImageSize = 1280;// HD 720p=1280x720, Full HD 1080p=1920x1080 // finally self.sourceImage size to
static const NSTimeInterval kAnimationIntervalReset = 0.25;

typedef enum _PickerViewMode {
    PickerViewModePick,
    PickerViewModeRotate,
    PickerViewModeEdit,
} PickerViewMode;

@interface AddQuoteViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, TITokenFieldDelegate> {
    CGRect _selectedImageFrame;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *tmAssets;
@property (nonatomic, strong) ALAssetsLibrary *library;

@property (nonatomic, assign) PickerViewMode mode;
@property (nonatomic,strong) UIImageView *previewImageView;
@property(nonatomic,copy) UIImage *sourceImage;
@property (nonatomic, assign) CGFloat sourceWidth;
@property (nonatomic, assign) CGFloat sourceHeight;
@property (nonatomic, assign) int rotate90;// 0:up 1:

@property (nonatomic, strong) UIView *editView;
@property (nonatomic, strong) UIImageView *uploadImageView;
@property (nonatomic, strong) UITextField *quoteField;
@property (nonatomic, strong) TITokenFieldView * tokenFieldView;
@property (nonatomic, assign) CGFloat keyboardHeight;

- (void)cancelAction;
- (void)loadAssets;
- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer;

- (void)zoomInFrom:(CGRect)frame toSelectedIndex:(NSInteger)newIndex;
-(void)reset:(BOOL)animated;
- (CGImageRef)newScaledImage:(CGImageRef)source withOrientation:(UIImageOrientation)orientation toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality;
- (UIImage *)scaledImage:(UIImage *)source toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality;

- (void)backToPickerAction;
- (void)rotateRightAction;
- (void)rotateLeftAction;
- (void)doneRotateAction;
- (void)beforePostCheckAction;
- (void)postAction;
- (void)tapOnImageView:(UITapGestureRecognizer *)tapgr;

- (void)backToRotateAction:(UITapGestureRecognizer *)tapgr;
- (void)tokenFieldFrameDidChange:(TITokenField *)tokenField;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

- (void)transform:(CGAffineTransform*)transform andSize:(CGSize *)size forOrientation:(UIImageOrientation)orientation;

@end

@implementation AddQuoteViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"Add a Photo";
    self.view.backgroundColor = [UIColor blackColor];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 104+4;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor blackColor];
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 4)];
    self.tableView.tableHeaderView = headerView;
    [self.view addSubview:self.tableView];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
    
    // load all assets from AssetsLibrary
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryChanged:) name:ALAssetsLibraryChangedNotification object:nil];
    self.library = [[ALAssetsLibrary alloc] init];// using _library instead of library to avoid "ALAssetPrivate past the lifetime of its owning ALAssetsLibrary"
    [self loadAssets];

    // preview image view for rotation
    self.previewImageView = [[UIImageView alloc] init];
    self.previewImageView.alpha = 0;// by default
    self.previewImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnImageView:)];
    [self.previewImageView addGestureRecognizer:tapgr];
    [self.view addSubview:self.previewImageView];
    
    // editor
    self.editView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, ASSET_BY_SCREEN_HEIGHT(228+252, 228+88+252))];// 64(ios7fullscreenbar)+86+36+42+88(4")+252(full screen in order to background white color)
//    self.editView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.editView.backgroundColor = [UIColor whiteColor];
    self.editView.alpha = 0;
    [self.view addSubview:self.editView];
    
    CGFloat ios7FullBar = 0;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        ios7FullBar += 64;
    }
    
    self.uploadImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 86+ios7FullBar)];
    self.uploadImageView.userInteractionEnabled = YES;
    self.uploadImageView.contentMode = UIViewContentModeBottom;
    UITapGestureRecognizer *backToRotateTapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backToRotateAction:)];
    [self.uploadImageView addGestureRecognizer:backToRotateTapgr];
    [self.editView addSubview:self.uploadImageView];
    
    self.quoteField = [[UITextField alloc] initWithFrame:CGRectMake(14, CGRectGetMaxY(self.uploadImageView.frame), 320-28, 36)];
    self.quoteField.delegate = self;
    self.quoteField.returnKeyType = UIReturnKeyNext;
    self.quoteField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.quoteField.placeholder = NSLocalizedString(@"Write the subtitle in the photo", nil);
    self.quoteField.font = [UIFont systemFontOfSize:14];
    self.quoteField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.quoteField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.editView addSubview:self.quoteField];
    
    self.tokenFieldView = [[TITokenFieldView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.quoteField.frame), 320, 42)];
    [self.tokenFieldView.separator removeFromSuperview];
    self.tokenFieldView.scrollsToTop = NO;
    self.tokenFieldView.delaysContentTouches = YES;
	self.tokenFieldView.tokenField.delegate = self;
    self.tokenFieldView.tokenField.tokenLimit = kTMTokenLimit;
	[self.tokenFieldView setShouldSortResults:NO];
	[self.tokenFieldView.tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
    self.tokenFieldView.tokenField.removesTokensOnEndEditing = NO;
	[self.tokenFieldView.tokenField setTokenizingCharacters:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    [self.tokenFieldView.tokenField setPromptText:@""];
	[self.tokenFieldView.tokenField setPlaceholder:NSLocalizedString(@"Add Tags", nil)];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.editView addSubview:self.tokenFieldView];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    // set full screen display and show all bars
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
    } else {
//        self.wantsFullScreenLayout = YES;
//        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
//        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    }
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark - property

- (void)setSourceImage:(UIImage *)sourceImage {// avoid Big memory write
    if(sourceImage != _sourceImage) {
        _sourceImage = sourceImage;
    }
}

#pragma mark - private

- (void)assetsLibraryChanged:(NSNotification *)notification {
    if ([notification.userInfo.allValues count] == 0) {
        return;
    }
    if (notification.userInfo[ALAssetLibraryUpdatedAssetsKey]) {
        [self loadAssets];
    }
}

- (void)cancelAction {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)loadAssets {
    NSMutableArray *localAssets = [[NSMutableArray alloc] init];
    [self.library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if(result == nil || index == NSNotFound || *stop == YES) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.tmAssets = localAssets;
                        [self.tableView reloadData];
                        // scroll to bottom
                        NSInteger row = [self tableView:_tableView numberOfRowsInSection:0] - 1;
                        if (row >= 0) {
                            [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                        }
                    });
                    return;
                } else {
                    [localAssets addObject:result];
                }
            }];
        }
    } failureBlock:^(NSError *error) {
        if ([error code] == -3311) {// ALAssetsLibraryErrorDomain
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please Allow Photo Access", nil)
                                                             message:[NSString stringWithFormat:NSLocalizedString(@"This allows you to share photos from your library. Open iPhone Settings > Tap Privacy > Tap Photos > Set “%@” to ON.", nil), NSLocalizedString(@"WhatsPhoto", nil)]
                                                            delegate:nil
                                                   cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                   otherButtonTitles:nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", nil) otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)cellTapped:(UITapGestureRecognizer *)tapRecognizer {
    AssetTableViewCell *cell = (AssetTableViewCell *)tapRecognizer.view;
    CGPoint point = [tapRecognizer locationInView:cell];
    CGRect frame = CGRectMake(0, 0, 104, 104);
    NSIndexPath *index = [self.tableView indexPathForCell:cell];
    for (int i = 0; i < [cell.rowAssets count]; ++i) {
        if (CGRectContainsPoint(frame, point)) {
            NSInteger targetIndex = index.row*3+i;
            self.mode = PickerViewModeRotate;
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
            } else {
                self.wantsFullScreenLayout = YES;
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
                self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
            }
            
            CGRect rectInSuperview = [cell convertRect:frame toView:[_tableView superview]];
            [self zoomInFrom:rectInSuperview toSelectedIndex:targetIndex];
            return;
        }
        frame = CGRectOffset(frame, CGRectGetWidth(frame)+4, 0);
    }
}

- (void)zoomInFrom:(CGRect)frame toSelectedIndex:(NSInteger)newIndex {
    // zoom in photo
    _selectedImageFrame = frame;
    ALAsset *asset = [_tmAssets objectAtIndex:newIndex];
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    NSDictionary *metadata = [rep metadata];
    UIImageOrientation orientation = UIImageOrientationUp;
    NSNumber *orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
    if (orientationValue != nil) {
        orientation = [orientationValue intValue];
    }
    if (orientation == UIImageOrientationLeft || orientation == UIImageOrientationRight) {
        self.sourceHeight = [[metadata objectForKey:@"PixelWidth"] doubleValue];
        self.sourceWidth = [[metadata objectForKey:@"PixelHeight"] doubleValue];
    } else {
        self.sourceWidth = [[metadata objectForKey:@"PixelWidth"] doubleValue];
        self.sourceHeight = [[metadata objectForKey:@"PixelHeight"] doubleValue];
    }
    
    self.previewImageView.frame = frame;
    self.previewImageView.image = [UIImage imageWithCGImage:[rep fullScreenImage]];
    [UIView animateWithDuration:TMFadeAnimationDuration animations:^{
        self.previewImageView.alpha = 1;
        [self reset:NO];// zoom in to full screen frame
    } completion:^(BOOL finished) {
        // Retrieve the image orientation from the ALAsset
        UIImage *image = [UIImage imageWithCGImage:[rep fullResolutionImage] scale:1 orientation:orientation];
        self.sourceImage = image;
        if (self.previewImageView.image != self.sourceImage) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                CGImageRef hiresCGImage = NULL;
                CGFloat aspect = self.sourceImage.size.height/self.sourceImage.size.width;
                CGSize size;
                if (aspect >= 1.0) { //square or portrait
                    size = CGSizeMake(kMaxImageSize*aspect, kMaxImageSize);
                } else { // landscape
                    size = CGSizeMake(kMaxImageSize, kMaxImageSize*aspect);
                }
                hiresCGImage = [self newScaledImage:self.sourceImage.CGImage withOrientation:self.sourceImage.imageOrientation toSize:size withQuality:kCGInterpolationDefault];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.previewImageView.image = [UIImage imageWithCGImage:hiresCGImage];
                    CGImageRelease(hiresCGImage);
                });
            });
        }
    }];
    
    // zoom out background
    CATransform3D t2 = CATransform3DIdentity;
    double scale = 0.8;
    t2 = CATransform3DScale(t2, scale, scale, 1);
    CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation2.toValue = [NSValue valueWithCATransform3D:t2];
    animation2.beginTime = 0;
    animation2.duration = TMFadeAnimationDuration;
    animation2.fillMode = kCAFillModeForwards;
    animation2.removedOnCompletion = NO;
    [self.tableView.layer addAnimation:animation2 forKey:@"pushBehind"];
    [UIView animateWithDuration:TMFadeAnimationDuration animations:^{
        self.tableView.alpha = 0;
    }];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [backButton setBackgroundImage:[UIImage imageNamed:@"toolbar_back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backToPickerAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    UIButton *rotateLeftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [rotateLeftButton setBackgroundImage:[UIImage imageNamed:@"toolbar_rotate_left.png"] forState:UIControlStateNormal];
    [rotateLeftButton addTarget:self action:@selector(rotateLeftAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rotateLeftButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rotateLeftButton];
    
    UIButton *rotateRightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [rotateRightButton setBackgroundImage:[UIImage imageNamed:@"toolbar_rotate_right.png"] forState:UIControlStateNormal];
    [rotateRightButton addTarget:self action:@selector(rotateRightAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rotateRightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rotateRightButton];
    
    UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneRotateAction)];
    self.toolbarItems = [NSArray arrayWithObjects:backButtonItem, flexibleSpaceButtonItem, rotateLeftButtonItem, flexibleSpaceButtonItem, rotateRightButtonItem, flexibleSpaceButtonItem, doneButtonItem, nil];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)reset:(BOOL)animated {
    CGFloat sourceAspect = self.rotate90%2 == 0 ? self.sourceHeight/self.sourceWidth : self.sourceWidth/self.sourceHeight;
    CGFloat w = 320;
    CGFloat h = sourceAspect*w;
    void (^doReset)(void) = ^{
        if (self.rotate90 == 0) {
            self.previewImageView.transform = CGAffineTransformIdentity;
        }
        self.previewImageView.frame = CGRectMake(CGRectGetMidX(self.view.frame)-w/2, CGRectGetMidY(self.view.frame)-h/2, w, h);
    };
    if(animated) {
        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:kAnimationIntervalReset animations:doReset completion:^(BOOL finished) {
            self.view.userInteractionEnabled = YES;
        }];
    } else {
        doReset();
    }
}

- (CGImageRef)newScaledImage:(CGImageRef)source withOrientation:(UIImageOrientation)orientation toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality {
    CGSize srcSize = size;
    CGAffineTransform transform;
    [self transform:&transform andSize:&srcSize forOrientation:orientation];
    
//    CGFloat scaleFactor = [UIScreen mainScreen].scale;
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 size.width,
                                                 size.height,
                                                 CGImageGetBitsPerComponent(source),
                                                 0,
                                                 CGImageGetColorSpace(source),
                                                 CGImageGetBitmapInfo(source)
                                                 );
    
    CGContextSetInterpolationQuality(context, quality);
    CGContextTranslateCTM(context, size.width/2, size.height/2);
    CGContextScaleCTM(context, 1, 1);
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(context, CGRectMake(-srcSize.width/2, -srcSize.height/2, srcSize.width, srcSize.height), source);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return resultRef;
}

- (UIImage *)scaledImage:(UIImage *)source toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality {
    CGImageRef cgImage  = [self newScaledImage:source.CGImage withOrientation:source.imageOrientation toSize:size withQuality:quality];
    UIImage *result = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    return result;
}

- (void)backToPickerAction {
    if (self.mode != PickerViewModeRotate) {
        return;
    }
    
    self.tokenFieldView.scrollsToTop = NO;
    self.tableView.scrollsToTop = YES;
    
    self.mode = PickerViewModePick;
    
    self.rotate90 = 0;
    
    // zoom in background (tableview)
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    animation.beginTime = 0;
    animation.duration = TMFadeAnimationDuration;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    
    [self.tableView.layer addAnimation:animation forKey:@"pushforward"];
    
    [UIView animateWithDuration:TMFadeAnimationDuration animations:^{
        self.tableView.alpha = 1;
    }];
    
    [UIView animateWithDuration:TMFadeAnimationDuration animations:^{
        self.previewImageView.frame = _selectedImageFrame;
        self.previewImageView.alpha = 0;
    } completion:^(BOOL finished) {
        self.previewImageView.image = nil;
        [self reset:NO];
    }];
    
    // hide toolbar
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
    } else {
        self.wantsFullScreenLayout = NO;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    }
}

- (void)rotateRightAction {
    self.rotate90++;
    if (self.rotate90 == 4) {
        self.rotate90 = 0;
    }
    [UIView animateWithDuration:0.25 animations:^{
        CGFloat rotateAngel = M_PI*self.rotate90/2.0f;
        self.previewImageView.transform = CGAffineTransformMakeRotation(rotateAngel);
    }];
    [self reset:NO];
}

- (void)rotateLeftAction {
    self.rotate90--;
    if (self.rotate90 == -1) {
        self.rotate90 = 3;
    }
    [UIView animateWithDuration:0.25 animations:^{
        CGFloat rotateAngel = M_PI*self.rotate90/2.0f;
        self.previewImageView.transform = CGAffineTransformMakeRotation(rotateAngel);
    }];
    [self reset:NO];
}

- (void)doneRotateAction {
    self.mode = PickerViewModeEdit;
    
    self.tokenFieldView.scrollsToTop = YES;
    self.tableView.scrollsToTop = NO;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
    } else {
        self.wantsFullScreenLayout = NO;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    }
    self.previewImageView.alpha = 0;

    // must scale first avoid incorrect orientation
    CGFloat sourceAspect = self.sourceHeight/self.sourceWidth;
    // get scale to fit 320 width image
    CGFloat scaledWidth = 320*[UIScreen mainScreen].scale;// for display
    UIImage *scaledImage = [self scaledImage:self.sourceImage toSize:CGSizeMake(scaledWidth, sourceAspect*scaledWidth) withQuality:kCGInterpolationDefault];
    
    // get rotated image
    UIImage *rotatedImage = scaledImage;
    if (self.rotate90 == 0) {
        // Nothing
    } else if (self.rotate90 == 1) {
        rotatedImage = [rotatedImage imageRotatedByRadians:M_PI_2];
    } else if (self.rotate90 == 2) {
        rotatedImage = [rotatedImage imageRotatedByRadians:M_PI];
    } else {// if (self.rotate90 == 3) {
        rotatedImage = [rotatedImage imageRotatedByRadians:-M_PI_2];
    }
    
    self.uploadImageView.image = rotatedImage;

    self.uploadImageView.contentScaleFactor = [UIScreen mainScreen].scale;// for display
    
    [UIView animateWithDuration:0.25 animations:^{
        self.editView.alpha = 1;
    }];

    [self.navigationController setToolbarHidden:YES animated:YES];
    [self.quoteField becomeFirstResponder];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Post", nil) style:UIBarButtonItemStyleDone target:self action:@selector(beforePostCheckAction)];
}

- (void)beforePostCheckAction {
    if ([self.quoteField.text length] == 0) {
        [UIAlertView alertViewWithTitle:NSLocalizedString(@"Empty subtitle", nil) message:NSLocalizedString(@"Continue without subtitle?", nil) cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:@[NSLocalizedString(@"Continue", nil)] onDismiss:^(int buttonIndex) {
            [self postAction];
        } onCancel:^{
        }];
    } else {
        [self postAction];
    }
}

- (void)postAction {
    // disable POST button
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // hide keyboard
    [self.quoteField resignFirstResponder];
    [self.tokenFieldView resignFirstResponder];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    hud.labelText = NSLocalizedString(@"Upload photo", nil);
    
    // must scale first avoid incorrect orientation
    // min(uploadSize, max(width, height))
    CGSize scaledSize = CGSizeZero;
    if (self.sourceWidth > self.sourceHeight) {
        CGFloat minWidth = fminf(self.sourceWidth, kMaxUploadImageSize);
        scaledSize = CGSizeMake(minWidth, minWidth*(self.sourceHeight/self.sourceWidth));
    } else {// self.sourceHeight > self.sourceWidth
        CGFloat minHeight = fminf(self.sourceHeight, kMaxUploadImageSize);
        scaledSize = CGSizeMake(minHeight*(self.sourceWidth/self.sourceHeight), minHeight);
    }
    UIImage *scaledImage = [self scaledImage:self.sourceImage toSize:scaledSize withQuality:kCGInterpolationDefault];
    
    CGFloat newWidth = self.sourceWidth;// for upload
    CGFloat newHeight = self.sourceHeight;
    
    // get rotated image
    UIImage *rotatedImage = scaledImage;
    if (self.rotate90 == 0) {
        // Nothing
    } else if (self.rotate90 == 1) {
        rotatedImage = [rotatedImage imageRotatedByRadians:M_PI_2];
        newWidth = self.sourceHeight;
        newHeight = self.sourceWidth;
    } else if (self.rotate90 == 2) {
        rotatedImage = [rotatedImage imageRotatedByRadians:M_PI];
    } else {// if (self.rotate90 == 3) {
        rotatedImage = [rotatedImage imageRotatedByRadians:-M_PI_2];
        newWidth = self.sourceHeight;
        newHeight = self.sourceWidth;
    }
    
    NSData *uploadImage = UIImageJPEGRepresentation(rotatedImage, 0.7);

    PFFile *imageFile = [PFFile fileWithName:@"image.jpg" data:uploadImage];
    
    if (newWidth > newHeight) {
        CGFloat maxHeight = 200;
        scaledSize = CGSizeMake(maxHeight*(newWidth/newHeight), maxHeight);
    } else {// newHeigh > newWidth
        CGFloat maxWidth = 200;
        scaledSize = CGSizeMake(maxWidth, maxWidth*(newHeight/newWidth));
    }
    scaledImage = [self scaledImage:rotatedImage toSize:scaledSize withQuality:kCGInterpolationDefault];
    NSData *uploadThumbnail = UIImageJPEGRepresentation(scaledImage, 0.8);
    PFFile *thumbnailFile = [PFFile fileWithName:@"thumb.jpg" data:uploadThumbnail];
    
    NSString *title = self.quoteField.text;
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSMutableArray *lowerCaseTags = [[NSMutableArray alloc] init];
                    for (NSString *tokenTitle in self.tokenFieldView.tokenTitles) {
                        [lowerCaseTags addObject:[tokenTitle lowercaseString]];
                    }
                    
                    PFObject *quote = [PFObject objectWithClassName:@"Quote"];
                    quote[@"image"] = imageFile;
                    quote[@"thumbnail"] = thumbnailFile;
                    
                    if (newWidth > newHeight) {
                        CGFloat minWidth = fminf(newWidth, kMaxUploadImageSize);
                        quote[@"imageWidth"] = [NSNumber numberWithFloat:minWidth];
                        quote[@"imageHeight"] = [NSNumber numberWithFloat:minWidth*(newHeight/newWidth)];
                    } else {// newHeigh > newWidth
                        CGFloat minHeight = fminf(newHeight, kMaxUploadImageSize);
                        quote[@"imageWidth"] = [NSNumber numberWithFloat:minHeight*(newWidth/newHeight)];
                        quote[@"imageHeight"] = [NSNumber numberWithFloat:minHeight];
                    }
                    quote[@"title"] = title;
                    quote[@"tags"] = self.tokenFieldView.tokenTitles;
                    quote[@"lowerCaseTags"] = lowerCaseTags;
                    quote[@"locale"] = [[AppConfig shareInstance] getUploadLocale];
                    quote[@"allTagsSaved"] = @NO;// default
                    quote[@"visibleType"] = @0;// default
                    quote[@"useCount"] = @0;
                    quote[@"favoriteCount"] = @0;
                    quote[@"reportCount"] = @0;
                    
                    PFACL *acl = [PFACL ACL];
                    [acl setPublicReadAccess:YES];
                    [acl setWriteAccess:YES forUser:[PFUser currentUser]];
                    quote.ACL = acl;
                    
                    // TagAlias
                    NSMutableArray *tagAliasMArray = [[NSMutableArray alloc] initWithCapacity:[self.tokenFieldView.tokenTitles count]];
                    for (NSString *tagTitle in self.tokenFieldView.tokenTitles) {
                        PFObject *tagAlias = [PFObject objectWithClassName:@"TagAlias"];
                        tagAlias[@"name"] = tagTitle;
                        tagAlias[@"locale"] = [[AppConfig shareInstance] getUploadLocale];
                        tagAlias[@"quote"] = quote;
                        [tagAliasMArray addObject:tagAlias];
                    }

                    [PFObject saveAllInBackground:tagAliasMArray block:^(BOOL succeeded, NSError *error) {
                        if (!error) {
                            quote[@"allTagsSaved"] = @YES;
                        } else {
                            quote[@"allTagsSaved"] = @NO;
                        }
                        [quote saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (!error) {
                                hud.labelText = NSLocalizedString(@"Done", nil);
                                [hud hide:YES afterDelay:1];
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    [self cancelAction];
                                    self.navigationItem.rightBarButtonItem.enabled = YES;
                                });
                            } else {
                                hud.labelText = NSLocalizedString(@"Fail", nil);
                                [hud hide:YES afterDelay:1];
                                NSLog(@"Error: %@ %@", error, [error userInfo]);
                                self.navigationItem.rightBarButtonItem.enabled = YES;
                            }
                        }];
                    }];

                } else {
                    hud.labelText = NSLocalizedString(@"Fail", nil);
                    [hud hide:YES afterDelay:1];
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                }
            } progressBlock:^(int percentDone) {
                hud.progress = ((percentDone/10.0f)+100)/110.0f;
            }];
        } else {
            hud.labelText = NSLocalizedString(@"Fail", nil);
            [hud hide:YES afterDelay:1];
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
    } progressBlock:^(int percentDone) {// 0-100
        hud.progress = percentDone/110.0f;
    }];
}

- (void)tapOnImageView:(UITapGestureRecognizer *)tapgr {
    BOOL hidden = !self.navigationController.toolbar.hidden;
    
    [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:hidden animated:YES];
    [self.navigationController setToolbarHidden:hidden animated:YES];
}

- (void)backToRotateAction:(UITapGestureRecognizer *)tapgr {
    if (self.mode != PickerViewModeEdit) {
        return;
    }
    
    self.mode = PickerViewModeRotate;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
    } else {
        self.wantsFullScreenLayout = YES;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.previewImageView.alpha = 1;
        self.editView.alpha = 0;
    }];
    self.navigationItem.rightBarButtonItem = nil;

    [self.navigationController setToolbarHidden:NO animated:YES];
    [self.quoteField resignFirstResponder];
    [self.tokenFieldView resignFirstResponder];
}

- (void)tokenFieldFrameDidChange:(TITokenField *)tokenField {
    [self.tokenFieldView scrollRectToVisible:CGRectMake(0, self.tokenFieldView.contentSize.height-1, 1, 1) animated:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification {
	CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	self.keyboardHeight = keyboardRect.size.height > keyboardRect.size.width ? keyboardRect.size.width : keyboardRect.size.height;
    
    CGFloat height = ASSET_BY_SCREEN_HEIGHT(78, 78+88)-(self.keyboardHeight-216);// 42+36
    self.tokenFieldView.frame = CGRectMake(0, CGRectGetMinY(self.tokenFieldView.frame), 320, height);
}

- (void)keyboardWillHide:(NSNotification *)notification {
	self.keyboardHeight = 0;
}

# pragma mark - Image Transformation

- (void)transform:(CGAffineTransform *)transform andSize:(CGSize *)size forOrientation:(UIImageOrientation)orientation {
    *transform = CGAffineTransformIdentity;
    BOOL transpose = NO;
    
    switch (orientation) {
        case UIImageOrientationUp:// EXIF 1
        case UIImageOrientationUpMirrored:{// EXIF 2
        } break;
        case UIImageOrientationDown:// EXIF 3
        case UIImageOrientationDownMirrored: {// EXIF 4
            *transform = CGAffineTransformMakeRotation(M_PI);
        } break;
        case UIImageOrientationLeftMirrored:// EXIF 5
        case UIImageOrientationLeft: {// EXIF 6
            *transform = CGAffineTransformMakeRotation(M_PI_2);
            transpose = YES;
        } break;
        case UIImageOrientationRightMirrored:// EXIF 7
        case UIImageOrientationRight: {// EXIF 8
            *transform = CGAffineTransformMakeRotation(-M_PI_2);
            transpose = YES;
        } break;
        default:
            break;
    }
    
    if (orientation == UIImageOrientationUpMirrored || orientation == UIImageOrientationDownMirrored ||
       orientation == UIImageOrientationLeftMirrored || orientation == UIImageOrientationRightMirrored) {
        *transform = CGAffineTransformScale(*transform, -1, 1);
    }
    
    if (transpose) {
        *size = CGSizeMake(size->height, size->width);
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ceil([self.tmAssets count]/3.0f);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    AssetTableViewCell *cell = (AssetTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[AssetTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellTapped:)];
        [cell addGestureRecognizer:tapRecognizer];
    }
    
    NSInteger location = indexPath.row*3;
    NSInteger length = MIN(3, [self.tmAssets count]-location);
    [cell setRowAssets:[self.tmAssets subarrayWithRange:NSMakeRange(location, length)]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.tokenFieldView.tokenField == textField) {
        // check kTMTokenLimit
        if (_tokenFieldView.tokenField.tokenLimit!=-1 && [_tokenFieldView.tokenField.tokens count] >= _tokenFieldView.tokenField.tokenLimit) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.detailsLabelText = NSLocalizedString(@"You cannot post more than 30 tags per post.", nil);
            [hud hide:YES afterDelay:1];
            return NO;
        }
        
        NSMutableString *newString = [[NSMutableString alloc] initWithString:textField.text];
        [newString replaceCharactersInRange:range withString:string];
        
        // fullDelimitingCharset from https://github.com/slubman/canary/blob/master/NSMutableAttributedString%2BORSCanaryAdditions.m
        NSMutableCharacterSet *charset = [[NSMutableCharacterSet alloc] init];
        [charset addCharactersInString:@"±§!#$%^&*()-+={}[];:'\"\\|,./<>?`~ÅÍÎÏ"];
        [charset addCharactersInString:@"¡™£¢∞§¶•ªº–≠œ∑´®†¥¨ˆøπ“‘åß∂ƒ©˙∆˚¬…æ«ÓÔ"];
        [charset addCharactersInString:@"Ω≈ç√∫˜µ≤≥÷⁄€‹›ﬁﬂ‡°·—Œ„´‰ˇÁ¨ˆØ∏”’˝ÒÚÆ"];
        [charset addCharactersInString:@"»¸˛Ç◊ı˜Â¯˘¿"];
        NSRange range = [newString rangeOfCharacterFromSet:charset];
        if (range.location != NSNotFound) {
            return NO;
        }
        
        if ([newString length] > 27) {// kTextEmpty + maximum 26
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.detailsLabelText = NSLocalizedString(@"Tag length must less than 26 words.", nil);
            [hud hide:YES afterDelay:1];
            
            return NO;
        }
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.quoteField) {
        [self.tokenFieldView becomeFirstResponder];
    }
    return YES;
}

#pragma mark - TITokenFieldDelegate

- (BOOL)tokenField:(TITokenField *)tokenField willAddToken:(TIToken *)token {
    for (TIToken *oldToken in tokenField.tokens) {
        if ([oldToken.title isEqualToString:token.title]) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = NSLocalizedString(@"Tag is duplicated.", nil);
            [hud hide:YES afterDelay:1];
            return NO;
        }
    }
    
    token.textColor = [UIColor darkGrayColor];
    token.tintColor = UIColorFromRGB(0x77afef);
    return YES;
}

@end
