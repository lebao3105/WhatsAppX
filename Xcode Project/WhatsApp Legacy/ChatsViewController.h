//
//  ChatsViewController.h
//  WhatsApp Legacy
//
//  Created by Gian Luca Russo on 29/07/24.
//  Copyright (c) 2024 Gian Luca Russo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "JSONFetcher.h"

@class AppDelegate;
@interface ChatsViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, JSONFetcherDelegate> {
    NSInteger pendingDownloads;
}

@property (assign, nonatomic) IBOutlet UISearchBar *searchBar;
@property (retain, nonatomic) UIView *btnMetaAiView;
@property (copy, nonatomic) NSArray* chatList;
@property (copy, nonatomic) NSArray* groupList;

@property (copy, nonatomic) NSMutableArray *filteredChatList;
@property BOOL isFiltered;
@property int chatBadge;
@property int unreadCount;

@property (nonatomic) NSInteger pendingDownloads;

-(void)reloadChats;
-(void)loadMessagesFirstTime;
@end
