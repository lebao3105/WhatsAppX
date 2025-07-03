//
//  DataViewController.m
//  WhatsApp Legacy
//
//  Created by CalvinK19 on 7/1/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "DataViewController.h"
#import "WhatsAppAPI.h"

@interface DataViewController ()

@end

@implementation DataViewController
@synthesize progressView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// prevent phone from sleeping
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

// re-enable sleeping
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Setup";
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBackground.png"]];
    //[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"setupStage2"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:@"PendingDownloadsUpdated" object:nil];
    [WhatsAppAPI getChatListAsync];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [progressView release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}
- (void)viewDidUnload {
    [self setProgressView:nil];
    [super viewDidUnload];
}

- (void)updateProgress:(NSNotification *)notification {
    NSLog(@"update progress notif");
    NSNumber *pending = [notification.userInfo objectForKey:@"pendingDownloads"];
    NSNumber *total = [notification.userInfo objectForKey:@"totalDownloads"];
    if (pending && total && [total intValue] > 0) {
        float progress = 1.0 - ((float)[pending intValue] / (float)[total intValue]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView setProgress:progress animated:YES];
        });
    }
}


@end
