//
//  QuoteTableViewCell.h
//  WhatsPhoto
//
//  Created by Sapp on 2014/7/26.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QuoteTableViewCellDelegate.h"

UIKIT_EXTERN CGFloat const kMinTitleLabelHeight;
UIKIT_EXTERN CGFloat const kQuoteTokenFieldWidth;
UIKIT_EXTERN CGFloat const kQuoteTokenPlusButtonWidth;
UIKIT_EXTERN CGFloat const kQuoteVPadding;
UIKIT_EXTERN CGFloat const kQuoteMenuHeight;

@interface QuoteTableViewCell : UITableViewCell

@property (nonatomic, strong) PFObject *quote;
@property (nonatomic, assign) BOOL extendedTokenField;
@property (nonatomic, weak) id <QuoteTableViewCellDelegate> delegate;

- (UIImage *)thumbImage;

+ (CGFloat)calculateHeightForTokens:(NSArray *)tokenArray filedWidth:(CGFloat)filedWidth;
+ (CGFloat)singleLineTokenFieldHeight;

@end
