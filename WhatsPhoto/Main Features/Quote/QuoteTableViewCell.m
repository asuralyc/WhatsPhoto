//
//  QuoteTableViewCell.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/7/26.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "QuoteTableViewCell.h"
#import "TTTAttributedLabel.h"
#import "UIImageView+WebCache.h"
#import "TITokenField.h"
#import "UIImage+Color.h"
#import "AppConfig.h"

CGFloat const kMinTitleLabelHeight = 62+19;// 19=4+15 favoriteCountTTTLabel
CGFloat const kQuoteTokenFieldWidth = 300-43;
CGFloat const kQuoteTokenPlusButtonWidth = 43;
CGFloat const kQuoteVPadding = 4;
CGFloat const kQuoteMenuHeight = 40;


@interface QuoteTableViewCell () <TITokenFieldDelegate>

@property (nonatomic, strong) UIImageView *photoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) TTTAttributedLabel *useCountTTTLabel;
//@property (nonatomic, strong) TTTAttributedLabel *favoriteCountTTTLabel;
@property (nonatomic, strong) TITokenFieldView * tokenFieldView;
@property (nonatomic, strong) UIButton *tokenPlusButton;
@property (nonatomic, strong) UIView *menuBaseView;
@property (nonatomic, strong) UIButton *messageButton;

- (CGRect)tokenPlusFrame;
- (void)tapOnPhoto:(UITapGestureRecognizer *)tapgr;
- (void)extendTokenFieldAction;
- (void)favoriteAction;
- (void)messageAction;
- (void)moreAction;

@end

@implementation QuoteTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // photo
        self.photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, kQuoteVPadding, 134, 100)];
        self.photoImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.photoImageView.clipsToBounds = YES;
        self.photoImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *photoTapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnPhoto:)];
        [self.photoImageView addGestureRecognizer:photoTapGr];
        [self.contentView addSubview:self.photoImageView];
        
        // title label
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.photoImageView.frame)+10, kQuoteVPadding, 320-CGRectGetMaxX(self.photoImageView.frame)-10-10, kMinTitleLabelHeight)];
        self.titleLabel.textColor = [UIColor blackColor];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        self.titleLabel.numberOfLines = 0;
        [self.contentView addSubview:self.titleLabel];
        
        // use count label
        self.useCountTTTLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.photoImageView.frame)+10, CGRectGetMaxY(self.titleLabel.frame)+4, 100, 15)];
        self.useCountTTTLabel.textColor = [UIColor lightGrayColor];
        self.useCountTTTLabel.backgroundColor = [UIColor clearColor];
        self.useCountTTTLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10];
        [self.contentView addSubview:self.useCountTTTLabel];
        
//        // favorite count label
//        self.favoriteCountTTTLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.photoImageView.frame)+10, CGRectGetMaxY(self.useCountTTTLabel.frame)+4, 100, 15)];
//        self.favoriteCountTTTLabel.textColor = [UIColor lightGrayColor];
//        self.favoriteCountTTTLabel.backgroundColor = [UIColor clearColor];
//        self.favoriteCountTTTLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10];
//        [self.contentView addSubview:self.favoriteCountTTTLabel];
        
        // token field
        self.tokenFieldView = [[TITokenFieldView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.photoImageView.frame), kQuoteTokenFieldWidth, 39)];
        self.tokenFieldView.scrollsToTop = NO;
        self.tokenFieldView.scrollEnabled = NO;
        self.tokenFieldView.delaysContentTouches = YES;
        self.tokenFieldView.tokenField.delegate = self;
        self.tokenFieldView.tokenField.editable = NO;
        [self.tokenFieldView setShouldSortResults:NO];
        [self.tokenFieldView.tokenField setTokenizingCharacters:[NSCharacterSet characterSetWithCharactersInString:@",;. "]]; // Default is a comma
        [self.tokenFieldView.tokenField setPromptText:@""];
        [self.contentView addSubview:self.tokenFieldView];
        
        // token plus button
        self.tokenPlusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.tokenPlusButton.frame = CGRectMake(CGRectGetMaxX(self.tokenFieldView.frame)+4, CGRectGetMinY(self.tokenFieldView.frame)+7, kQuoteTokenPlusButtonWidth, 25/*39*/);
        [self.tokenPlusButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [self.tokenPlusButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.tokenPlusButton setBackgroundImage:[UIImage imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateHighlighted];
        self.tokenPlusButton.titleLabel.font = [UIFont systemFontOfSize:14];
        self.tokenPlusButton.layer.borderWidth = ONE_PIXEL_ON_SCREEN;
        self.tokenPlusButton.layer.masksToBounds = YES;
        self.tokenPlusButton.layer.cornerRadius = 12;
        self.tokenPlusButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
        [self.tokenPlusButton addTarget:self action:@selector(extendTokenFieldAction) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.tokenPlusButton];
        
        // menu view
        self.menuBaseView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.tokenFieldView.frame), 320, kQuoteMenuHeight)];
        self.menuBaseView.backgroundColor = UIColorFromRGB(0xfafafa);
        
        self.messageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.messageButton.frame = CGRectMake(10, 0, 160-2, kQuoteMenuHeight);
        [self.messageButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [self.messageButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
        self.messageButton.titleLabel.font = [UIFont systemFontOfSize:14];
        self.messageButton.imageEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        self.messageButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
        self.messageButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        self.messageButton.imageView.layer.cornerRadius = 18;
        self.messageButton.imageView.clipsToBounds = YES;
        [self.messageButton addTarget:self action:@selector(messageAction) forControlEvents:UIControlEventTouchUpInside];
        [self.menuBaseView addSubview:self.messageButton];
        
        UIButton *moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moreButton.frame = CGRectMake(320-10-36/*CGRectGetMaxX(self.messageButton.frame)+4+112*/, 0, /*150-2-112*/36, kQuoteMenuHeight);
        [moreButton setImage:[UIImage imageNamed:@"quote_cell_more_icon.png"] forState:UIControlStateNormal];
        [moreButton setImage:[UIImage imageNamed:@"quote_cell_more_highlighted_icon.png"] forState:UIControlStateHighlighted];
        [moreButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [moreButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        moreButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [moreButton addTarget:self action:@selector(moreAction) forControlEvents:UIControlEventTouchUpInside];
        [self.menuBaseView addSubview:moreButton];
        [self.contentView addSubview:self.menuBaseView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // photo
    __weak UIImageView *photoImageView = self.photoImageView;
    photoImageView.alpha = 0;
    photoImageView.image = nil;
    PFFile *thumbnailFile = self.quote[@"thumbnail"];
    NSString *originalUrlString = [thumbnailFile url];
    [photoImageView setImageWithURL:[NSURL URLWithString:originalUrlString] placeholderImage:[UIImage imageNamed:@"placeholder-avatar"] options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (cacheType == SDImageCacheTypeNone) {
            [UIView animateWithDuration:0.1 animations:^{
                photoImageView.alpha = 1;
                photoImageView.layer.opacity = 1;
            }];
        } else {
            photoImageView.alpha = 1;
        }
    }];
    
    // title label
    self.titleLabel.text = self.quote[@"title"];
    self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.photoImageView.frame)+10, kQuoteVPadding, 320-CGRectGetMaxX(self.photoImageView.frame)-10-10, 58);
    [self.titleLabel sizeToFit];
    
    // use count label
    CGFloat topOffset = (CGRectGetHeight(self.titleLabel.frame) > kMinTitleLabelHeight) ? CGRectGetMaxY(self.titleLabel.frame) : kQuoteVPadding+kMinTitleLabelHeight;
    CGRect useCountFrame = self.useCountTTTLabel.frame;
    useCountFrame.origin.y = topOffset+4;
    self.useCountTTTLabel.frame = useCountFrame;
    NSString *useCountString = [NSString stringWithFormat:@"%d", [self.quote[@"useCount"] intValue]];
    [self.useCountTTTLabel setText:useCountString afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSMutableAttributedString *resultMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Used: ", nil)];
        NSRange titleRange = NSMakeRange(0, [resultMutableAttributedString length]);
        NSRange countRange = NSMakeRange([resultMutableAttributedString length], [mutableAttributedString length]);
        // TODO: color
        [resultMutableAttributedString appendAttributedString:mutableAttributedString];
        [resultMutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[[UIColor lightGrayColor] CGColor] range:titleRange];
        [resultMutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[[UIColor lightGrayColor] CGColor] range:countRange];
        
        return resultMutableAttributedString;
    }];
    
    // favorite count label
//    CGRect favoriteCountFrame = self.useCountTTTLabel.frame;
//    favoriteCountFrame.origin.y = CGRectGetMaxY(useCountFrame)+4;
//    self.favoriteCountTTTLabel.frame = favoriteCountFrame;
//    NSString *favoriteCountString = [NSString stringWithFormat:@"%d", [self.quote[@"favoriteCount"] intValue]];
//    [self.favoriteCountTTTLabel setText:favoriteCountString afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
//        // TODO:
//        NSMutableAttributedString *resultMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Favorite: ", nil)];
//        NSRange titleRange = NSMakeRange(0, [resultMutableAttributedString length]);
//        NSRange countRange = NSMakeRange([resultMutableAttributedString length], [mutableAttributedString length]);
//        // TODO: color
//        [resultMutableAttributedString appendAttributedString:mutableAttributedString];
//        [resultMutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[[UIColor lightGrayColor] CGColor] range:titleRange];
//        [resultMutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[[UIColor lightGrayColor] CGColor] range:countRange];
//        
//        return resultMutableAttributedString;
//    }];
    
    // token frame
    [self.tokenFieldView.tokenField removeAllTokens];
    
    NSArray *quoteTagArray = self.quote[@"tags"];
    BOOL tokenPlusButtonHidden = NO;
    NSString *tokenPlusTitle = @"";
    if ([quoteTagArray count] == 0) {
        self.tokenFieldView.hidden = YES;
        tokenPlusButtonHidden = YES;
        
        // menu view
        CGRect mbFrame = self.menuBaseView.frame;
//        if (CGRectGetMaxY(self.favoriteCountTTTLabel.frame) > CGRectGetMaxY(self.photoImageView.frame)) {
//            mbFrame.origin.y = CGRectGetMaxY(self.favoriteCountTTTLabel.frame);
        if (CGRectGetMaxY(self.useCountTTTLabel.frame) > CGRectGetMaxY(self.photoImageView.frame)) {
            mbFrame.origin.y = CGRectGetMaxY(self.useCountTTTLabel.frame);
        } else {
            mbFrame.origin.y = CGRectGetMaxY(self.photoImageView.frame);
        }
        self.menuBaseView.frame = mbFrame;
    } else {
        self.tokenFieldView.hidden = NO;
        if (self.extendedTokenField) {
            tokenPlusButtonHidden = YES;
            [self.tokenFieldView.tokenField addTokensWithTitleArray:quoteTagArray animated:NO];
            for (TIToken *token in self.tokenFieldView.tokenField.tokens) {
                token.textColor = [UIColor darkGrayColor];
                token.tintColor = UIColorFromRGB(0x77afef);
            }
            CGFloat tokenFieldHeight = [[self class] calculateHeightForTokens:quoteTagArray filedWidth:CGRectGetWidth(self.tokenFieldView.tokenField.frame)];
            CGRect tfFrame = self.tokenFieldView.frame;
            tfFrame.size.height = tokenFieldHeight;
//            if (CGRectGetMaxY(self.favoriteCountTTTLabel.frame) > CGRectGetMaxY(self.photoImageView.frame)) {
//                tfFrame.origin.y = CGRectGetMaxY(self.favoriteCountTTTLabel.frame);
            if (CGRectGetMaxY(self.useCountTTTLabel.frame) > CGRectGetMaxY(self.photoImageView.frame)) {
                tfFrame.origin.y = CGRectGetMaxY(self.useCountTTTLabel.frame);
            } else {
                tfFrame.origin.y = CGRectGetMaxY(self.photoImageView.frame);
            }
            self.tokenFieldView.frame = tfFrame;
        } else {
            CGFloat lineHeight = [[self class] singleLineTokenFieldHeight];
            int stopIndex = 0;
            NSMutableArray *tagMArray = [[NSMutableArray alloc] init];

            for (int i = 0; i < [quoteTagArray count]; ++i) {
                NSString *tagTitle = quoteTagArray[i];
                [tagMArray addObject:tagTitle];
                CGFloat currentHeight = [[self class] calculateHeightForTokens:tagMArray filedWidth:CGRectGetWidth(self.tokenFieldView.tokenField.frame)];
                if (currentHeight > lineHeight) {
                    stopIndex = i;
                    break;
                }
            }
            
            if (stopIndex == 0) {
                tokenPlusButtonHidden = YES;
            } else {
                tokenPlusTitle = [NSString stringWithFormat:@"+%d", [quoteTagArray count]-stopIndex];
            }
            if (stopIndex > 0) {
                [tagMArray removeLastObject];
            }
            
            [self.tokenFieldView.tokenField addTokensWithTitleArray:tagMArray animated:NO];
            for (TIToken *token in self.tokenFieldView.tokenField.tokens) {
                token.textColor = [UIColor darkGrayColor];
                token.tintColor = UIColorFromRGB(0x77afef);
            }
            CGFloat tokenFieldHeight = [[self class] calculateHeightForTokens:tagMArray filedWidth:CGRectGetWidth(self.tokenFieldView.tokenField.frame)];
            CGRect tfFrame = self.tokenFieldView.frame;
            tfFrame.size.height = tokenFieldHeight;
//            if (CGRectGetMaxY(self.favoriteCountTTTLabel.frame) > CGRectGetMaxY(self.photoImageView.frame)) {
//                tfFrame.origin.y = CGRectGetMaxY(self.favoriteCountTTTLabel.frame);
            if (CGRectGetMaxY(self.useCountTTTLabel.frame) > CGRectGetMaxY(self.photoImageView.frame)) {
                tfFrame.origin.y = CGRectGetMaxY(self.useCountTTTLabel.frame);
            } else {
                tfFrame.origin.y = CGRectGetMaxY(self.photoImageView.frame);
            }
            self.tokenFieldView.frame = tfFrame;
        }
        
        // menu view
        CGRect mbFrame = self.menuBaseView.frame;
        mbFrame.origin.y = CGRectGetMaxY(self.tokenFieldView.frame);
        self.menuBaseView.frame = mbFrame;
    }
    
    // token plus button
    self.tokenPlusButton.hidden = tokenPlusButtonHidden;
    if (!tokenPlusButtonHidden) {
        CGRect localTokenPlusFrame = [self tokenPlusFrame];
        CGRect tokenPlusFrame = self.tokenPlusButton.frame;
        tokenPlusFrame.origin.y = CGRectGetMinY(self.tokenFieldView.frame)+CGRectGetMinY(localTokenPlusFrame);
        tokenPlusFrame.size.height = CGRectGetHeight(localTokenPlusFrame);
        self.tokenPlusButton.frame = tokenPlusFrame;
        [self.tokenPlusButton setTitle:tokenPlusTitle forState:UIControlStateNormal];
    }
    
    // menu
    if ([[AppConfig shareInstance] defaultIM] == DefaultIMLINE) {
        [self.messageButton setImage:[UIImage imageNamed:@"quote_cell_line_icon.png"] forState:UIControlStateNormal];
        [self.messageButton setTitle:NSLocalizedString(@"LINE", nil) forState:UIControlStateNormal];
    } else if ([[AppConfig shareInstance] defaultIM] == DefaultIMWhatsApp) {
        [self.messageButton setImage:[UIImage imageNamed:@"quote_cell_whatsapp_icon.png"] forState:UIControlStateNormal];
        [self.messageButton setTitle:NSLocalizedString(@"WhatsApp", nil) forState:UIControlStateNormal];
    } else if ([[AppConfig shareInstance] defaultIM] == DefaultIMWeChat) {
        [self.messageButton setImage:[UIImage imageNamed:@"quote_cell_wechat_icon.png"] forState:UIControlStateNormal];
        [self.messageButton setTitle:NSLocalizedString(@"WeChat", nil) forState:UIControlStateNormal];
    } else if ([[AppConfig shareInstance] defaultIM] == DefaultIMFBMessenger) {
        [self.messageButton setImage:[UIImage imageNamed:@"quote_cell_fbmessenger_icon.png"] forState:UIControlStateNormal];
        [self.messageButton setTitle:NSLocalizedString(@"FB Messenger", nil) forState:UIControlStateNormal];
    }
}

#pragma mark - public

- (UIImage *)thumbImage {
    return self.photoImageView.image;
}

+ (CGFloat)calculateHeightForTokens:(NSArray *)tokenArray filedWidth:(CGFloat)filedWidth {
    UIFont *font = [UIFont systemFontOfSize:14];
    CGFloat tokenFieldWidth = filedWidth;
    CGFloat hTextPadding = 14;
    CGFloat vTextPadding = 8;
    
	CGFloat topMargin = floor(font.lineHeight * 4 / 7);
    CGFloat leftMargin = 4;
	CGFloat hPadding = 4;
	CGFloat rightMargin = hPadding;
	CGFloat lineHeight = ceilf(font.lineHeight) + topMargin + 5;
	
	int _numberOfLines = 1;
	CGPoint _tokenCaret = (CGPoint){leftMargin, (topMargin - 1)};
    for (NSString *title in tokenArray) {
        CGFloat maxWidth = (tokenFieldWidth - rightMargin - (_numberOfLines > 1 ? hPadding : leftMargin));
        
        CGSize titleSize = [title sizeWithFont:font forWidth:(maxWidth - hTextPadding) lineBreakMode:NSLineBreakByTruncatingTail];
        CGFloat height = floorf(titleSize.height + vTextPadding);
        
        CGSize tokenSize = (CGSize){MAX(floorf(titleSize.width + hTextPadding), height - 3), height};
		
        if (_tokenCaret.x + tokenSize.width + rightMargin > tokenFieldWidth){
            _numberOfLines++;
            _tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
            _tokenCaret.y += lineHeight;
        }
        _tokenCaret.x += tokenSize.width + 4;// +4 for token middle padding
        
        // remove this code if editorMode = NO
//        if (tokenFieldWidth - _tokenCaret.x - rightMargin < 50){
//            _numberOfLines++;
//            _tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
//            _tokenCaret.y += lineHeight;
//        }
    }
	return ceilf(_tokenCaret.y + lineHeight);
}

+ (CGFloat)singleLineTokenFieldHeight {
    UIFont *font = [UIFont systemFontOfSize:14];
	CGFloat topMargin = floor(font.lineHeight * 4 / 7);
    CGFloat leftMargin = 4;
	CGFloat lineHeight = ceilf(font.lineHeight) + topMargin + 5;

	CGPoint _tokenCaret = (CGPoint){leftMargin, (topMargin - 1)};
    CGFloat fieldHeight = ceilf(_tokenCaret.y + lineHeight);
    
	return fieldHeight;
}

#pragma mark - private

- (CGRect)tokenPlusFrame {
    UIFont *font = [UIFont systemFontOfSize:14];
    CGFloat tokenFieldWidth = CGFLOAT_MAX;
    CGFloat hTextPadding = 14;
    CGFloat vTextPadding = 8;
    
	CGFloat topMargin = floor(font.lineHeight * 4 / 7);
    CGFloat leftMargin = 4;
	CGFloat hPadding = 4;
	CGFloat rightMargin = hPadding;
	CGFloat lineHeight = ceilf(font.lineHeight) + topMargin + 5;
	
	int _numberOfLines = 1;
	CGPoint _tokenCaret = (CGPoint){leftMargin, (topMargin - 1)};
    NSString *title = @"+99";
    CGFloat maxWidth = (tokenFieldWidth - rightMargin - (_numberOfLines > 1 ? hPadding : leftMargin));
    CGSize titleSize = [title sizeWithFont:font forWidth:(maxWidth - hTextPadding) lineBreakMode:NSLineBreakByTruncatingTail];
    CGFloat height = floorf(titleSize.height + vTextPadding);
    CGSize tokenSize = (CGSize){MAX(floorf(titleSize.width + hTextPadding), height - 3), height};
    
    _tokenCaret.x += tokenSize.width + 4;// +4 for token middle padding
    
    CGFloat buttonHeight = height-2;// hard code to fit
    CGFloat fieldHeight = ceilf(_tokenCaret.y + lineHeight);
    
	return CGRectMake(0, (fieldHeight-buttonHeight)/2, tokenSize.width, buttonHeight);
}

- (void)tapOnPhoto:(UITapGestureRecognizer *)tapgr {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showPhotoWithQuoteTableViewCell:)]) {
        [self.delegate showPhotoWithQuoteTableViewCell:self];
    }
}

- (void)extendTokenFieldAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(extendTokenFieldWithQuoteTableViewCell:)]) {
        [self.delegate extendTokenFieldWithQuoteTableViewCell:self];
    }
}

- (void)favoriteAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(favoriteWithQuoteTableViewCell:)]) {
        [self.delegate favoriteWithQuoteTableViewCell:self];
    }
}

- (void)messageAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageWithQuoteTableViewCell:)]) {
        [self.delegate messageWithQuoteTableViewCell:self];
    }
}

- (void)moreAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(moreWithQuoteTableViewCell:)]) {
        [self.delegate moreWithQuoteTableViewCell:self];
    }
}

#pragma mark - TITokenFieldDelegate

- (void)tokenField:(TITokenField *)tokenField touchUpInsideToken:(TIToken *)token {
    if (self.delegate && [self.delegate respondsToSelector:@selector(quoteTableViewCell:didSelectTokenTitle:)]) {
        [self.delegate quoteTableViewCell:self didSelectTokenTitle:token.title];
    }
}

@end
