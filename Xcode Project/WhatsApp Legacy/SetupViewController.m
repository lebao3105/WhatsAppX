//
//  SetupViewController.m
//  WhatsApp Legacy
//
//  Created by Gian Luca Russo on 27/07/24.
//  Copyright (c) 2024 Gian Luca Russo. All rights reserved.
//

#import "SetupViewController.h"
#import "AppDelegate.h"
#import "JSONUtility.h"
#import "AppDelegate.h"

@interface SetupViewController () <UIAlertViewDelegate>

@end

@implementation SetupViewController
@synthesize serverA;
@synthesize serverB;
@synthesize serverAport;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [serverA resignFirstResponder];
    [serverB resignFirstResponder];
    [serverAport resignFirstResponder];
    return true;
}

- (BOOL)isValidIPv4Address:(NSString *)ipAddress {
    // man
    
    // Expresión regular para validar una dirección IPv4
    //NSString *ipv4Pattern = @"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\."
    //"(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\."
    //"(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\."
    //"(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
    
    //NSPredicate *ipv4Predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", ipv4Pattern];
    //return [ipv4Predicate evaluateWithObject:ipAddress];
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [serverA setDelegate:self];
    [serverB setDelegate:self];
    [serverAport setDelegate:self];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tableViewBackground.png"]];
}

- (void)dealloc
{
    //[self setIpAddressTXT:nil];
    //[serverAport release];
    [super dealloc];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)infoBtnPressed {
    // Create temporary UIViewController
    UIViewController *webVC = [[UIViewController alloc] init];
    webVC.view.frame = self.view.bounds;
    webVC.view.backgroundColor = [UIColor whiteColor];
    
    // Create and add the navigation bar
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, webVC.view.frame.size.width, 44)];
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Info"];
    
    // Create dismiss button for nav bar (left side)
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss"
                                                                      style:UIBarButtonItemStyleDone
                                                                     target:self
                                                                     action:@selector(dismissWebVC:)];
    navItem.leftBarButtonItem = dismissButton;
    
    [navBar setItems:[NSArray arrayWithObject:navItem]];
    
    [webVC.view addSubview:navBar];
    
    [navItem release];
    [dismissButton release];
    [navBar release];
    
    CGRect scrollFrame = webVC.view.bounds;
    scrollFrame.origin.y += 44;       // below nav bar
    scrollFrame.size.height -= 44;    // reduce height by nav bar height
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:scrollFrame];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, scrollFrame.size.width - 20, 0)];
    textLabel.numberOfLines = 0;
    textLabel.lineBreakMode = UILineBreakModeWordWrap;
    textLabel.font = [UIFont systemFontOfSize:14];
    textLabel.text = @"WhatsApp's Terms Of Service forbidding users to reverse enginner clients.\n\nThe server uses the library \"whatsapp-web.js\" to connect your WhatsApp account.\nThe library works by launching the WhatsApp Web browser application and managing it, thereby mitigating the risk of being blocked.\n\nThe only risk of being blocked can happen if you re-link the server to your account numerous times by scanning the QR code. If you already have it linked once, you will be fine. Just be sure to wait a day or two in between re-linking the server in order to not be flagged.";
    
    [textLabel sizeToFit];
    
    scrollView.contentSize = CGSizeMake(scrollFrame.size.width, textLabel.frame.size.height + 20);
    
    [scrollView addSubview:textLabel];
    
    [webVC.view addSubview:scrollView];
    
    [textLabel release];
    [scrollView release];
    
    webVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentModalViewController:webVC animated:YES];
    [webVC release];
}

// Helper method for dismiss button
- (void)dismissWebVC:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}


- (IBAction)doneSetup:(id)sender {
    // Validate input fields
    if ((serverA.text.length == 0) || (serverB.text.length == 0) || (serverAport.text.length == 0)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"A field is empty."
                                                        message:@"Please fill in all fields."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Try creating a HEAD request to check if URL is valid
    NSString *urlString = serverA.text;
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (!connection) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"The address entered is invalid, only IPv4 is supported."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Save values to NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setObject:serverA.text forKey:@"wspl-a-address"];
    [[NSUserDefaults standardUserDefaults] setObject:serverB.text forKey:@"wspl-b-address"];
    [[NSUserDefaults standardUserDefaults] setObject:serverAport.text forKey:@"wspl-a-port"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Dismiss keyboards
    [serverA resignFirstResponder];
    [serverB resignFirstResponder];
    
    // Show loading HUD
    HUD = [[MBProgressHUD alloc] initWithView:self.view.window];
    [self.view.window addSubview:HUD];
    HUD.delegate = self;
    HUD.labelText = @"Connecting to Server A";
    [HUD showWhileExecuting:@selector(waitToTimeout) onTarget:self withObject:nil animated:YES];
    
    // Connect to server
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate connectToServerWithIp:serverA.text andWithPort:[self.serverAport.text intValue]];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 101) {
        if (buttonIndex == 0) {
            NSLog(@"cancel");
        } else if (buttonIndex == 1) {
        } else if (buttonIndex == 2) {
            //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://web.archive.org/web/20250606222048if_/https://wwebjs.dev/guide/#disclaimer"]];
            [self infoBtnPressed];
        }
    }
}



- (void)executeAfterDelay {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //[[NSUserDefaults standardUserDefaults] setObject:serverA.text forKey:@"wspl-a-address"];
    //[[NSUserDefaults standardUserDefaults] setObject:serverB.text forKey:@"wspl-b-address"];
    //[[NSUserDefaults standardUserDefaults] setObject:serverAport.text forKey:@"wspl-a-port"];
    //[[NSUserDefaults standardUserDefaults] synchronize];

    [appDelegate.tabBarController.view setFrame: [[UIScreen mainScreen] applicationFrame]];
    [appDelegate.window addSubview:appDelegate.tabBarController.view];
}

- (void)waitToTimeout {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    sleep(5);
    if(appDelegate.serverConnect == (int*)2) {
        HUD.labelText = @"Syncing Messages";
        [appDelegate.chatsViewController loadMessagesFirstTime];
        [self executeAfterDelay];

    } else {
        appDelegate.serverConnect = 0;
        UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Connection Error" message:@"Failed to connect to Server A (TCP)." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alerta show];
    }
}
- (void)hudWasHidden {
    [HUD removeFromSuperview];
    [HUD release];
}

- (void)viewDidUnload {
    [self setServerAport:nil];
    [super viewDidUnload];
}
@end
