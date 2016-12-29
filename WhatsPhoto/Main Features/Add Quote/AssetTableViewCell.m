//
//  AssetTableViewCell.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/7/18.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "AssetTableViewCell.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation AssetTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGFloat _xOffset = 0;
        for (int i = 0; i < 3; ++i) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(_xOffset, 0, 104, 104)];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            imageView.tag = 3000+i;
            [self.contentView addSubview:imageView];
            
            _xOffset = CGRectGetMaxX(imageView.frame)+4;
        }
    }
    return self;
}

- (void)setRowAssets:(NSArray *)rowAssets {
    _rowAssets = rowAssets;
    
    for (int i = 0; i < 3; ++i) {
        UIImageView *imageView = (UIImageView *)[self.contentView viewWithTag:3000+i];
        if (i < [_rowAssets count]) {
            imageView.hidden = NO;
            ALAsset *asset = [_rowAssets objectAtIndex:i];
            imageView.image = [UIImage imageWithCGImage:asset.thumbnail];
        } else {
            imageView.hidden = YES;
        }
    }
}

@end
