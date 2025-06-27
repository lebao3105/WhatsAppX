//
//  VideoMessage.m
//  WhatsApp Legacy
//
//  Created by Gian Luca Russo on 12/10/24.
//  Copyright (c) 2024 Gian Luca Russo. All rights reserved.
//

#import "VideoMessage.h"
#import "AppDelegate.h"
#import "CocoaFetch.h"

#define IS_IOS32orHIGHER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2)

@interface VideoMessage ()
- (void)updateButtonStates;
@end

@implementation VideoMessage
@synthesize downloadBtn;
@synthesize loadingSpinner;
@synthesize imgPreview;
@synthesize durationLabel;
@synthesize view, msgId, msgDuration, moviePlayer, moviePlayerOS4, downloadPlayTap;

- (id)initWithSize:(CGSize)size withId:(NSString *)messageId withDuration:(NSInteger)duration
{
    CGSize redSize = [CocoaFetch resizeToWidth:220.0f fromSize:size];
    self = [super initWithFrame:CGRectMake(0, 0, redSize.width, redSize.height)];
    if (self) {
        [self setup];
        self.msgId = messageId;
        self.msgDuration = duration;
        self.durationLabel.text = [NSString stringWithFormat:@"%@", [CocoaFetch formattedTimeFromSeconds:duration]];
        [self updatePreview:self.msgId];
        [self updateButtonStates];
    }
    return self;
}

- (void)setup {
    [[NSBundle mainBundle] loadNibNamed:@"VideoMessage" owner:self options:nil];
    self.view.frame = self.frame;
    self.tag = (NSInteger)@"VideoMessage";
    [self addSubview:self.view];
}

- (void)updateButtonStates {
    NSString *videoPath = [NSString stringWithFormat:@"%@/%@.mp4",
                           [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject],
                           self.msgId];
    BOOL videoExists = [[NSFileManager defaultManager] fileExistsAtPath:videoPath];
    
    if (videoExists) {
        downloadPlayTap.hidden = NO;
        self.downloadBtn.hidden = YES;
        [self.loadingSpinner stopAnimating];
    } else {
        downloadPlayTap.hidden = YES;
        self.downloadBtn.hidden = NO;
        [self.loadingSpinner stopAnimating];
    }
}


- (IBAction)playButtonTapped:(id)sender {
    self.downloadPlayTap.hidden = YES;
    [self.loadingSpinner startAnimating];
    
    NSString *tempPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                           objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", self.msgId]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
        [self.loadingSpinner stopAnimating];
        downloadPlayTap.hidden = NO;
        [self playVideo];
    } else {
        [self.loadingSpinner startAnimating];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.chatSocket.isConnected && [CocoaFetch connectedToServers]) {
            [self downloadVideoFromURL:[NSString stringWithFormat:@"%@/getMediaData/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"], self.msgId]];
        }
    }
}

- (void)dealloc {
    [msgId release];
    [durationLabel release];
    [imgPreview release];
    if(IS_IOS32orHIGHER){
        [moviePlayerOS4 release];
    } else {
        [moviePlayer release];
    }
    [loadingSpinner release];
    [downloadBtn release];
    [super dealloc];
}

- (void)downloadVideoFromURL:(NSString *)urlString {
    [self performSelectorInBackground:@selector(downloadAndProcessMediaVideo:) withObject:urlString];
}

- (void)downloadAndProcessMediaVideo:(NSString*)urlString {
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
    if (data) {
        // Guardar video en la galería y reproducirlo
        [self saveVideoToGalleryWithData:data];
    }
}

- (void)saveVideoToGalleryWithData:(NSData *)videoData {
    NSString *tempPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                           objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", self.msgId]];
    [videoData writeToFile:tempPath atomically:YES];
    
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(tempPath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(tempPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
    
    // Update UI regardless of save
    [self performSelectorOnMainThread:@selector(updateButtonStates) withObject:nil waitUntilDone:NO];
}

- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loadingSpinner stopAnimating];
        self.downloadBtn.hidden = YES;
        downloadPlayTap.hidden = NO;
    });
    
    if (error) {
        NSLog(@"Failed to save video: %@", error.localizedDescription);
    } else {
        NSLog(@"Video saved successfully.");
    }
}

- (void)playVideo {
    NSLog(@"Play video");
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *tempPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                          stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", self.msgId]];
    NSURL *videoURL = [NSURL fileURLWithPath:tempPath];
    
    if (IS_IOS32orHIGHER) {
        MPMoviePlayerViewController *movieVC = [[[MPMoviePlayerViewController alloc] initWithContentURL:videoURL] autorelease];
        
        UIViewController *presentingVC = appDelegate.chatViewController;
        
        void (^tryPresent)(void) = ^{
            if (presentingVC.presentedViewController == nil && presentingVC.view.window) {
                [self.loadingSpinner stopAnimating];
                self.downloadPlayTap.hidden = NO;
                [presentingVC presentMoviePlayerViewControllerAnimated:movieVC];
            } else {
                NSLog(@"Still not safe to present MPMoviePlayerViewController.");
                [self.loadingSpinner stopAnimating];
                self.downloadPlayTap.hidden = NO;
            }
        };
        
        if (presentingVC.isViewLoaded && presentingVC.view.window && presentingVC.presentedViewController == nil) {
            tryPresent();
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), tryPresent);
        }
    } else {
        if (!self.moviePlayer) {
            self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
        }
        [self.loadingSpinner stopAnimating];
        self.downloadPlayTap.hidden = NO;
        [self.moviePlayer play];
    }
}


- (void)downloadPreviewFromURL:(NSString *)urlString {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSData* oimageData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@-mediaimage", urlString]];
    if(oimageData){
        [appDelegate.mediaImages setObject:[UIImage imageWithData:oimageData] forKey:urlString];
    }
    if(![appDelegate.mediaImages objectForKey:urlString]){
        [self performSelectorInBackground:@selector(downloadAndProcessMediaImage:) withObject:urlString];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.imgPreview setImage:[appDelegate.mediaImages objectForKey:urlString]];
        });
    }
}

- (void)downloadAndProcessMediaImage:(NSString *)imgURL {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSData *oimageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/getVideoThumbnail/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"], imgURL]]];
    if (appDelegate.chatSocket.isConnected == YES && [CocoaFetch connectedToServers]){
        UIImage *profImg = [UIImage imageWithData:oimageData];
        
        // Verificar si la imagen se descargó correctamente
        if (profImg) {
            // Guardar la imagen en el cache y en NSUserDefaults
            [appDelegate.mediaImages setObject:profImg forKey:imgURL];
            [[NSUserDefaults standardUserDefaults] setObject:UIImagePNGRepresentation(profImg) forKey:[NSString stringWithFormat:@"%@-mediaimage", imgURL]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.imgPreview setImage:[appDelegate.mediaImages objectForKey:imgURL]];
            });
            
        }
    }
}

- (void)updatePreview:(NSString *)urlString {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSData* oimageData = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@-mediaimage", urlString]];
    if(oimageData){
        [appDelegate.mediaImages setObject:[UIImage imageWithData:oimageData] forKey:urlString];
        [self.imgPreview setImage:[appDelegate.mediaImages objectForKey:urlString]];
    } else {
        [self downloadPreviewFromURL:self.msgId];
    }
}

- (IBAction)downloadBtn:(id)sender {
    self.downloadBtn.hidden = YES;
    [self.loadingSpinner startAnimating];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.chatSocket.isConnected && [CocoaFetch connectedToServers]) {
        NSString *videoURL = [NSString stringWithFormat:@"%@/getMediaData/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"], self.msgId];
        [self downloadVideoFromURL:videoURL];
    } else {
        NSLog(@"Not connected to server");
        [self.loadingSpinner stopAnimating];
        self.downloadBtn.hidden = NO;
    }
}

@end
