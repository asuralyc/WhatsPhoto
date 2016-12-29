//
//  SettingIMViewController.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/8/3.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "SettingIMViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "AppConfig.h"

@interface SettingIMViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation SettingIMViewController

- (void)dealloc {
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"Setting IM";
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 50;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return DefaultIMCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, tableView.rowHeight-ONE_PIXEL_ON_SCREEN, 320, ONE_PIXEL_ON_SCREEN)];
        lineView.backgroundColor = UIColorFromRGB(0xe1e1e2);
        [cell.contentView addSubview:lineView];
    }
    
    if (indexPath.row == DefaultIMLINE) {
        cell.textLabel.text = NSLocalizedString(@"LINE", nil);
        if ([[AppConfig shareInstance] defaultIM] == DefaultIMLINE) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        cell.imageView.image = [UIImage imageNamed:@"setting_im_line_icon.png"];
    } else if (indexPath.row == DefaultIMWhatsApp) {
        cell.textLabel.text = NSLocalizedString(@"WhatsApp", nil);
        if ([[AppConfig shareInstance] defaultIM] == DefaultIMWhatsApp) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        cell.imageView.image = [UIImage imageNamed:@"setting_im_whatsapp_icon.png"];
    } else if (indexPath.row == DefaultIMWeChat) {
        cell.textLabel.text = NSLocalizedString(@"WeChat", nil);
        if ([[AppConfig shareInstance] defaultIM] == DefaultIMWeChat) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        cell.imageView.image = [UIImage imageNamed:@"setting_im_wechat_icon.png"];
    } else if (indexPath.row == DefaultIMFBMessenger) {
        cell.textLabel.text = NSLocalizedString(@"FB Messenger", nil);
        if ([[AppConfig shareInstance] defaultIM] == DefaultIMFBMessenger) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        cell.imageView.image = [UIImage imageNamed:@"setting_im_fbmessenger_icon.png"];
    }
    
    cell.imageView.layer.cornerRadius = 20;
    cell.imageView.clipsToBounds = YES;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[AppConfig shareInstance] defaultIM] == indexPath.row) {
        return;
    }
    
    NSString *preferredLocale = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    NSString *imName = @"LINE";
    if (indexPath.row == DefaultIMLINE) {
        imName = @"LINE";
    } else if (indexPath.row == DefaultIMWeChat) {
        imName = @"WeChat";
    } else if (indexPath.row == DefaultIMWhatsApp) {
        imName = @"WhatsApp";
    } else if (indexPath.row == DefaultIMFBMessenger) {
        imName = @"FBMessenger";
    }
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"setting im"
                                                          action:imName
                                                           label:preferredLocale
                                                           value:nil] build]];
    
    [[AppConfig shareInstance] setDefaultIM:indexPath.row];
    [self.tableView reloadData];
}

@end
