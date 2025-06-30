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
#import <UIKit/UIKit.h>

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

- (void)dismissQRCodePopup {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/loggedInYet", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"]]];
    NSError *error = nil;
    
    NSString *responseString = [NSString stringWithContentsOfURL:url
                                                        encoding:NSUTF8StringEncoding
                                                           error:&error];
    if (error || responseString == nil) {
        NSLog(@"Error fetching response: %@", error);
    }
    
    responseString = [responseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"%@", responseString);
    
    if ([responseString isEqualToString:@"false"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Paired"
                                                        message:@"If you've scanned the code, please wait for it to pair."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        
    } else if ([responseString isEqualToString:@"true"]) {
        // go to data sync screen, and set nsuserdefaults key as so
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"setupStage1"];

        [self dismissModalViewControllerAnimated:YES];
    } else {
        NSLog(@"Invalid response string: %@", responseString);
    }
    
    //[self dismissModalViewControllerAnimated:YES];
}

- (void)showQRCodeFromEndpoint {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/qr", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"]]];
    
    NSError *error = nil;
    NSString *responseString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    if (error || responseString == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Failed to load QR code."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    NSString *prefix = @"data:image/png;base64,";
    if ([responseString hasPrefix:prefix]) {
        NSString *base64String = [responseString substringFromIndex:[prefix length]];
        NSData *imageData = [self dataFromBase64String:base64String];
        
        if (imageData == nil) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Failed to decode QR code."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
        
        UIImage *qrImage = [UIImage imageWithData:imageData];
        if (!qrImage) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Invalid QR image data."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
        
        // Create a popup view controller
        UIViewController *popupVC = [[UIViewController alloc] init];
        popupVC.view.backgroundColor = [UIColor whiteColor];
        
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenBounds.size.width;
        CGFloat screenHeight = screenBounds.size.height;
        
        // Make QR image take up full width, and square (width = height)
        CGFloat qrSize = screenWidth;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:qrImage];
        imageView.frame = CGRectMake(0, 0, qrSize, qrSize);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [popupVC.view addSubview:imageView];
        [imageView release];
        
        // Add a button neatly below the image
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        CGFloat buttonWidth = screenWidth - 40.0; // 20pt padding on both sides
        CGFloat buttonHeight = 44.0;
        CGFloat buttonY = CGRectGetMaxY(imageView.frame) + 20.0;
        closeButton.frame = CGRectMake((screenWidth - buttonWidth) / 2, buttonY, buttonWidth, buttonHeight);
        
        [closeButton setTitle:@"Check for Authentication" forState:UIControlStateNormal];
        closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        closeButton.layer.cornerRadius = 8.0;
        closeButton.layer.borderWidth = 1.0;
        closeButton.layer.borderColor = [[UIColor grayColor] CGColor];
        [closeButton addTarget:self action:@selector(dismissQRCodePopup) forControlEvents:UIControlEventTouchUpInside];
        [popupVC.view addSubview:closeButton];
        
        [self presentModalViewController:popupVC animated:YES];
        [popupVC release];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Unexpected QR code format."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

// Base64 modified decoder for iOS 3 (from http://www.cocoadev.com/index.pl?BaseSixtyFour)
- (NSData *)dataFromBase64String:(NSString *)aString {
    const char *characters = [aString cStringUsingEncoding:NSASCIIStringEncoding];
    if (characters == NULL) // Not ASCII string
        return nil;
    size_t length = strlen(characters);
    
    static char decodingTable[256];
    static BOOL tableInitialized = NO;
    const char CHAR64_PAD = '=';
    const char CHAR64_INVALID = 64; // invalid marker
    
    if (!tableInitialized) {
        for (int i = 0; i < 256; i++) {
            decodingTable[i] = CHAR64_INVALID; // invalid
        }
        for (int i = 'A'; i <= 'Z'; i++) {
            decodingTable[i] = i - 'A';
        }
        for (int i = 'a'; i <= 'z'; i++) {
            decodingTable[i] = i - 'a' + 26;
        }
        for (int i = '0'; i <= '9'; i++) {
            decodingTable[i] = i - '0' + 52;
        }
        decodingTable[(unsigned)'+'] = 62;
        decodingTable[(unsigned)'/'] = 63;
        decodingTable[(unsigned)CHAR64_PAD] = 0;
        tableInitialized = YES;
    }
    
    NSMutableData *decoded = [NSMutableData dataWithLength:length];
    if (decoded == nil)
        return nil;
    
    size_t outIndex = 0;
    int accumulator = 0;
    int bitsCollected = 0;
    
    unsigned char *outputBytes = (unsigned char *)[decoded mutableBytes];
    
    for (size_t i = 0; i < length; i++) {
        unsigned char c = characters[i];
        char decodedValue = decodingTable[c];
        
        if (decodedValue == CHAR64_INVALID) {
            // Skip invalid chars (whitespace, newlines)
            continue;
        }
        
        accumulator = (accumulator << 6) | decodedValue;
        bitsCollected += 6;
        
        if (bitsCollected >= 8) {
            bitsCollected -= 8;
            outputBytes[outIndex++] = (accumulator >> bitsCollected) & 0xFF;
        }
    }
    
    [decoded setLength:outIndex];
    return decoded;
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
        NSLog(@"loading messages first time");
        [self showQRCodeFromEndpoint];

        //[appDelegate.chatsViewController loadMessagesFirstTime];
        //[self executeAfterDelay];

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
