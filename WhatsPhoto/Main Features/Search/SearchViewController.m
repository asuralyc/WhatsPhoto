//
//  SearchViewController.m
//  WhatsPhoto
//
//  Created by Sapp on 2014/7/29.
//  Copyright (c) 2014年 Sapp. All rights reserved.
//

#import "SearchViewController.h"
#import "QuoteViewController.h"
#import "MBProgressHUD.h"
#import "UIImage+Color.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

@interface SearchViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *historyMutableArray;

- (void)enqueue:(NSString *)searchKey;
- (void)clearHistoryAction;
- (NSString *)stringAfterCreateTime:(NSDate *)createdOn;
- (void)doSearchWithKeyword:(NSString *)keyword;

@end

@implementation SearchViewController

- (id)init {
    self = [super init];
    if (self) {
        self.historyMutableArray = [[NSMutableArray alloc] init];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SearchHistory"] != nil) {
            NSArray *historyArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"SearchHistory"];
            [self.historyMutableArray addObjectsFromArray:historyArray];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"Search";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 10, 44)];
    self.searchBar.showsCancelButton = YES;
    self.searchBar.delegate = self;
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.navigationItem.titleView = self.searchBar;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 48)];
    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    clearBtn.frame = CGRectMake(10, 4, 300, 40);
    [clearBtn setTitle:NSLocalizedString(@"Clear all", nil) forState:UIControlStateNormal];
    clearBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [clearBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    [clearBtn setBackgroundImage:[UIImage imageWithColor:UIColorFromRGB(0xf7f7f7)] forState:UIControlStateNormal];
    [clearBtn setBackgroundImage:[UIImage imageWithColor:UIColorFromRGB(0xeeeeee)] forState:UIControlStateHighlighted];
    clearBtn.layer.borderWidth = ONE_PIXEL_ON_SCREEN;
    clearBtn.layer.masksToBounds = YES;
    clearBtn.layer.cornerRadius = 5;
    clearBtn.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [tableHeaderView addSubview:clearBtn];
    [clearBtn addTarget:self action:@selector(clearHistoryAction) forControlEvents:UIControlEventTouchUpInside];
    self.tableView.tableHeaderView = tableHeaderView;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.searchBar becomeFirstResponder];
}

#pragma mark - private

- (void)enqueue:(NSString *)searchKey {
    for (int i = 0; i < [self.historyMutableArray count]; ++i) {
        NSDictionary *item = [self.historyMutableArray objectAtIndex:i];
        NSString *keyword = [item objectForKey:@"keyword"];
        if ([keyword isEqualToString:searchKey]) {
            [self.historyMutableArray removeObjectAtIndex:i];
            break;
        }
    }
    [self.historyMutableArray addObject:@{@"keyword": searchKey, @"updateDate" : [NSDate date]}];
    [[NSUserDefaults standardUserDefaults] setObject:self.historyMutableArray forKey:@"SearchHistory"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)clearHistoryAction {
    [self.historyMutableArray removeAllObjects];
    
    // save to NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setObject:self.historyMutableArray forKey:@"SearchHistory"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (NSString *)stringAfterCreateTime:(NSDate *)createdOn {
    double ti = [createdOn timeIntervalSinceDate:[NSDate date]];
    ti = ti * -1;
    if (ti < 60) {
    	return NSLocalizedString(@"Just", nil);//@"剛剛";//less than a minute ago
    } else if (ti < 3600) {
    	int diff = round(ti / 60);
    	return [NSString stringWithFormat:@"%d%@", diff, NSLocalizedString(@"minutes ago", nil)/*@"分鐘前"*/];
    } else if (ti < 86400) {
    	int diff = round(ti / 60 / 60);
    	return[NSString stringWithFormat:@"%d%@", diff, NSLocalizedString(@"hours ago", nil)/*@"小時前"*/];
    } else if (ti < 604800) {
    	int diff = round(ti / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%d%@", diff, NSLocalizedString(@"days ago", nil)/*@"天前"*/];
    } else if (ti < 2419200) {
    	int diff = round(ti / 60 / 60 / 24 / 7);
    	return[NSString stringWithFormat:@"%d%@", diff, NSLocalizedString(@"weeks ago", nil)/*@"週前"*/];
    } else if (ti < 31536000) {
    	int diff = round(ti / 60 / 60 / 24 / 30);
    	return[NSString stringWithFormat:@"%d%@", diff, NSLocalizedString(@"months ago", nil)/*@"個月前"*/];
    } else {
    	int diff = round(ti / 60 / 60 / 24 / 365);
    	return[NSString stringWithFormat:@"%d%@", diff, NSLocalizedString(@"years ago", nil)/*@"年前"*/];
    }
}

- (void)doSearchWithKeyword:(NSString *)keyword {
    QuoteViewController *qvc = [[QuoteViewController alloc] init];
    qvc.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Search", nil), keyword];
    qvc.viewType = QuoteViewTypeKeywordAndTag;
    qvc.viewTypeValue = keyword;
    [self.navigationController pushViewController:qvc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.historyMutableArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellId = @"CellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, tableView.rowHeight-ONE_PIXEL_ON_SCREEN, 320, ONE_PIXEL_ON_SCREEN)];
        lineView.backgroundColor = UIColorFromRGB(0xe1e1e2);
        [cell.contentView addSubview:lineView];
    }
    
    NSDictionary *item = [self.historyMutableArray objectAtIndex:[self.historyMutableArray count]-indexPath.row-1];
    cell.textLabel.text = [item objectForKey:@"keyword"];
    NSDate *date = [item objectForKey:@"updateDate"];
    cell.detailTextLabel.text = [self stringAfterCreateTime:date];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = [self.historyMutableArray objectAtIndex:[self.historyMutableArray count]-indexPath.row-1];
    [self enqueue:[item objectForKey:@"keyword"]];
    
    NSString *keyword = [item objectForKey:@"keyword"];
    [self doSearchWithKeyword:keyword];
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"search"
                                                          action:@"old_keyword"
                                                           label:keyword
                                                           value:nil] build]];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if ([searchBar.text length] > 0) {
        NSString *trimString = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([trimString length] == 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = NSLocalizedString(@"Couldn't load search results", nil);
            [hud hide:YES afterDelay:2];
            return;
        }
        [searchBar resignFirstResponder];
        
        [self enqueue:searchBar.text];
        [self doSearchWithKeyword:searchBar.text];
        
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"search"
                                                              action:@"new_keyword"
                                                               label:searchBar.text
                                                               value:nil] build]];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

@end
