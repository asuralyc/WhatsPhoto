//
//  SettingLocaleViewController.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/8/2.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "SettingLocaleViewController.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "AppConfig.h"

@interface SettingLocaleViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

- (void)doneAction;

@end

@implementation SettingLocaleViewController

- (void)dealloc {
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"Setting Locale";
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    
    if (self.showDoneBarButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}

#pragma mark - private

- (void)doneAction {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[NSLocale preferredLanguages] count]+1;
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
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(kTMWorldwideLocale, nil);
        if ([[AppConfig shareInstance] isWorldwideLocale]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    } else {
        NSString *locale = [[NSLocale preferredLanguages] objectAtIndex:indexPath.row-1];
        NSString *fullLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:locale];
        cell.textLabel.text = fullLanguage ? fullLanguage : locale;
        if ([[AppConfig shareInstance].locale isEqualToString:locale]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *oldLocale = [AppConfig shareInstance].locale;
    if (indexPath.row == 0) {
        if ([[AppConfig shareInstance].locale isEqualToString:kTMWorldwideLocale]) {
            return;
        }
        [AppConfig shareInstance].locale = kTMWorldwideLocale;
    } else {
        NSString *locale = [[NSLocale preferredLanguages] objectAtIndex:indexPath.row-1];
        if ([[AppConfig shareInstance].locale isEqualToString:locale]) {
            return;
        }
        [AppConfig shareInstance].locale = locale;
    }
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"setting change_locale"
                                                          action:[AppConfig shareInstance].locale // new
                                                           label:oldLocale // old
                                                           value:nil] build]];
    
    [self.tableView reloadData];
}

@end
