//
//  ServerViewController.h
//  WhatsApp Legacy
//
//  Created by CalvinK19 on 6/15/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServerViewController : UIViewController

@property (retain, nonatomic) IBOutlet UITextField *serverA;
@property (retain, nonatomic) IBOutlet UITextField *serverB;
@property (retain, nonatomic) IBOutlet UITextField *serverAport;

- (IBAction)doneSetup:(id)sender;
- (IBAction)delCacheBtn:(id)sender;

@end
