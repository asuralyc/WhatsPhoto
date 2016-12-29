//
//  QuoteViewController.h
//  WhatsPhoto
//
//  Created by Sapp on 2014/7/18.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "GAITrackedViewController.h"

typedef enum _QuoteViewType {
    QuoteViewTypeNormal,
    QuoteViewTypeKeyword,
    QuoteViewTypeTag,
    QuoteViewTypeKeywordAndTag,
//    QuoteViewTypeFavorite,
} QuoteViewType;

@interface QuoteViewController : GAITrackedViewController

@property (nonatomic, assign) QuoteViewType viewType;
@property (nonatomic, strong) id viewTypeValue;
@property (nonatomic, assign) BOOL showLanguageLeftBarButton;

@end
