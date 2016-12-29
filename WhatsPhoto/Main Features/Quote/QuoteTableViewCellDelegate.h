//
//  QuoteTableViewCellDelegate.h
//  WhatsPhoto
//
//  Created by Sapp on 2014/7/27.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QuoteTableViewCell;

@protocol QuoteTableViewCellDelegate <NSObject>

@optional
- (void)showPhotoWithQuoteTableViewCell:(QuoteTableViewCell *)cell;
- (void)quoteTableViewCell:(QuoteTableViewCell *)cell didSelectTokenTitle:(NSString *)title;
- (void)extendTokenFieldWithQuoteTableViewCell:(QuoteTableViewCell *)cell;
- (void)favoriteWithQuoteTableViewCell:(QuoteTableViewCell *)cell;
- (void)messageWithQuoteTableViewCell:(QuoteTableViewCell *)cell;
- (void)moreWithQuoteTableViewCell:(QuoteTableViewCell *)cell;

@end
