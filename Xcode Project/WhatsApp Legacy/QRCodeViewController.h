//
//  QRCodeViewController.h
//  WhatsApp Legacy
//
//  Created by CalvinK19 on 7/1/25.
//  Copyright (c) 2025 calvink19. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QRCodeViewController : UIViewController {
    IBOutlet UIImageView *qrImageView;
    IBOutlet UIButton *checkAuthButton;
    UIImage *qrImageToSet;
    NSTimer *authCheckTimer;

}

- (void)setQRCodeImage:(UIImage *)image;
- (IBAction)checkAuthenticationTapped:(id)sender;
@property (retain, nonatomic) IBOutlet UILabel *authLabel;


@end
