//
//  SetupViewController.h
//  WhatsApp Legacy
//
//  Created by Gian Luca Russo on 27/07/24.
//  Copyright (c) 2024 Gian Luca Russo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface SetupViewController : UIViewController <UITextFieldDelegate, MBProgressHUDDelegate> {
	MBProgressHUD *HUD;
	MBProgressHUD *HUD1;
}

@property (retain, nonatomic) IBOutlet UITextField *serverA;
@property (retain, nonatomic) IBOutlet UITextField *serverB;
@property (retain, nonatomic) IBOutlet UITextField *serverAport;

- (IBAction)infoBtnPressed;
- (IBAction)doneSetup:(id)sender;

@end
