//
//  ServerViewController.m
//  WhatsApp Legacy
//
//  Created by CalvinK19 on 6/15/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import "ServerViewController.h"
#import "AppDelegate.h"
#import "JSONUtility.h"
#import "AppDelegate.h"

@interface ServerViewController () <UITextFieldDelegate>
@end


@implementation ServerViewController

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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Server";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.serverA.delegate = self;
    self.serverB.delegate = self;
    self.serverAport.delegate = self;
    
    self.serverA.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-a-address"];
    self.serverB.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"];
    self.serverAport.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-a-port"];
    
    // Create Apply button
    UIBarButtonItem *deleteButton = [[[UIBarButtonItem alloc]
                                     initWithTitle:@"Delete Cache"
                                     style:UIBarButtonItemStylePlain
                                     target:self
                                     action:@selector(delCacheBtn:)] autorelease];
    
    // Create Apply button
    UIBarButtonItem *applyButton = [[[UIBarButtonItem alloc]
                                     initWithTitle:@"Apply"
                                     style:UIBarButtonItemStyleDone
                                     target:self
                                     action:@selector(doneSetup:)] autorelease];
    
    // Add both to right side of nav bar
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:applyButton, deleteButton, nil];
}




- (IBAction)doneSetup:(id)sender {
    if((self.serverA.text.length == 0) || (self.serverB.text.length == 0)){
        UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Address is empty." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alerta show];
    } else {
        NSString *urlString = serverA.text;
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"HEAD"];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
        if (connection) {
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [serverA resignFirstResponder];
            [serverB resignFirstResponder];
            
            // Save inputs BEFORE logging or using them
            [[NSUserDefaults standardUserDefaults] setObject:serverA.text forKey:@"wspl-a-address"];
            [[NSUserDefaults standardUserDefaults] setObject:serverB.text forKey:@"wspl-b-address"];
            [[NSUserDefaults standardUserDefaults] setObject:serverAport.text forKey:@"wspl-a-port"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            NSLog(@"%@ . %i", self.serverAport.text, [[[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-a-port"] intValue]);
            
            UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Applied" message:@"Restart the app." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alerta show];

        } else {
            UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Error" message:@"The address entered is invalid." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alerta show];
        }
    }
}

- (IBAction)delCacheBtn:(id)sender {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:&error];
    
    if (error) {
        NSLog(@"Error getting files from documents directory: %@", [error localizedDescription]);
        UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", [error localizedDescription]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alerta show];
        return;
    }
    
    for (NSString *file in files) {
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:file];
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success || error) {
            NSLog(@"Failed to delete file: %@, error: %@", filePath, [error localizedDescription]);
            UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to delete file: %@, error: %@", filePath, [error localizedDescription]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alerta show];
        }
    }
    
    NSLog(@"All files deleted from Documents directory.");
    UIAlertView *alerta = [[UIAlertView alloc]initWithTitle:@"Success" message:@"All cache was deleted." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alerta show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
