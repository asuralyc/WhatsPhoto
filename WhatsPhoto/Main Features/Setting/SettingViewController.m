//
//  SettingViewController.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/8/3.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "SettingViewController.h"
#import "SettingLocaleViewController.h"
#import "SettingIMViewController.h"
#import "AppConfig.h"

@interface SettingViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"Setting";
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 50;
    self.tableView.backgroundColor = UIColorFromRGB(0xe6e6e6);
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"CellId";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, tableView.rowHeight-ONE_PIXEL_ON_SCREEN, 320, ONE_PIXEL_ON_SCREEN)];
        lineView.backgroundColor = UIColorFromRGB(0xe1e1e2);
        [cell.contentView addSubview:lineView];
    }
    
    if (indexPath.row == 0) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = NSLocalizedString(@"Language", nil);
        NSString *locale = [AppConfig shareInstance].locale;
        NSString *fullLanguage;
        if ([locale isEqualToString:kTMWorldwideLocale]) {
            fullLanguage = NSLocalizedString(kTMWorldwideLocale, nil);
        } else {
            fullLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:locale];
        }
        cell.detailTextLabel.text = fullLanguage ? fullLanguage : locale;
    } else if (indexPath.row == 1) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = NSLocalizedString(@"Default Instant Messenger", nil);
        DefaultIM defaultIM = [[AppConfig shareInstance] defaultIM];
        if (defaultIM == DefaultIMWeChat) {
            cell.detailTextLabel.text = NSLocalizedString(@"WeChat", nil);
        } else if (defaultIM == DefaultIMWhatsApp) {
            cell.detailTextLabel.text = NSLocalizedString(@"WhatsApp", nil);
        } else if (defaultIM == DefaultIMFBMessenger) {
            cell.detailTextLabel.text = NSLocalizedString(@"FB Messenger", nil);
        } else {
            cell.detailTextLabel.text = NSLocalizedString(@"LINE", nil);
        }

    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    header.backgroundColor = UIColorFromRGB(0xe6e6e6);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 44)];
    label.textColor = [UIColor lightGrayColor];
    label.backgroundColor = UIColorFromRGB(0xe6e6e6);
    label.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    label.text = NSLocalizedString(@"Preferences",  nil);
    [header addSubview:label];
    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        SettingLocaleViewController *slvc = [[SettingLocaleViewController alloc] init];
        slvc.title = NSLocalizedString(@"Language", nil);
        [self.navigationController pushViewController:slvc animated:YES];
    } else if (indexPath.row == 1) {// IM
        SettingIMViewController *sivc = [[SettingIMViewController alloc] init];
        sivc.title = NSLocalizedString(@"Default IM", nil);
        [self.navigationController pushViewController:sivc animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

@end
