//
//  QRCodeViewController.m
//  WhatsApp Legacy
//
//  Created by CalvinK19 on 7/1/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "QRCodeViewController.h"
#import "AppDelegate.h"
#import "DataViewController.h"
#import "WhatsAppAPI.h"

@implementation QRCodeViewController

@synthesize authLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (qrImageToSet && qrImageView) {
        qrImageView.image = qrImageToSet;
        [qrImageToSet release];
        qrImageToSet = nil;
    }
    
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBackground.png"]];
    
    NSLog(@"Setting up auth timer...");
    authCheckTimer = [[NSTimer timerWithTimeInterval:2.0
                                              target:self
                                            selector:@selector(checkAuthenticationLoop)
                                            userInfo:nil
                                             repeats:YES] retain];
    [[NSRunLoop mainRunLoop] addTimer:authCheckTimer forMode:NSRunLoopCommonModes];
    NSLog(@"authCheckTimer: %@", authCheckTimer);
}

- (void)dealloc {
    [authCheckTimer invalidate];
    authCheckTimer = nil;
    
    [qrImageView release];
    [checkAuthButton release];
    [authLabel release];
    [super dealloc];
}

- (void)setQRCodeImage:(UIImage *)image {
    if (qrImageView) {
        qrImageView.image = image;
    } else {
        qrImageToSet = [image retain]; // Keep until view is loaded
    }
}

- (void)checkAuthenticationLoop {
    NSLog(@"Checking authentication");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/qr", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"]]];
    NSError *error = nil;
    
    NSString *responseString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (error || responseString == nil) {
        NSLog(@"Error fetching response: %@", error);
        return;
    }
    
    responseString = [responseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //NSLog(@"Response String: %@", responseString);
    
    if ([responseString isEqualToString:@"Success"]) {
        [authCheckTimer invalidate];
        authCheckTimer = nil;
        
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"setupStage1"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self.view removeFromSuperview];
        
        [self performSelector:@selector(presentDataViewController) withObject:nil afterDelay:0.01];
    }

}

- (void)presentDataViewController {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    DataViewController *dataVC = [[DataViewController alloc] initWithNibName:@"DataViewController" bundle:nil];
    dataVC.view.frame = [[UIScreen mainScreen] applicationFrame]; // Fullscreen
    
    [appDelegate.window addSubview:dataVC.view]; // Bypass modal entirely
    [dataVC release];
    
    [WhatsAppAPI getChatListAsync];
    [appDelegate.chatsViewController loadMessagesFirstTime];
}


- (void)viewDidUnload {
    [self setAuthLabel:nil];
    [super viewDidUnload];
}
@end
