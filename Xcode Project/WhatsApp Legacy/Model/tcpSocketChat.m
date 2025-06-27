//
//  tcpSocketChat.m
//  sampleNodejsChat
//
//  Created by saturngod
//

#import "tcpSocketChat.h"
#import "AppDelegate.h"

@interface tcpSocketChat()
@property(nonatomic,retain) AsyncSocket* asyncSocket;
@property(nonatomic,retain) NSString* HOST;
@property(nonatomic) NSInteger PORT;
@end

@implementation tcpSocketChat
@synthesize delegate = _delegate;
@synthesize asyncSocket = _asyncSocket;
@synthesize HOST = _HOST;
@synthesize PORT = _PORT;
-(id)initWithDelegate:(id)delegateObject AndSocketHost:(NSString*)host AndPort:(NSInteger)port {
    self = [super init];
    if(self)
    {
        _HOST = host;
        _PORT = port;
        _delegate = delegateObject;
        _asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
        
        NSError* err;
        if([self.asyncSocket connectToHost:_HOST onPort:_PORT error:&err])
        {
            
        }
        else {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSLog(@"ERROR %@",[err description]);
        }
            
    }
    return self;
}

-(void)sendMessage:(NSString *)str
{
    [self.asyncSocket writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}

-(void)disconnect {
    [self.asyncSocket disconnect];
}

-(void)reconnect {
    NSError* err;
    if(![self isConnected]) {
        if([self.asyncSocket connectToHost:_HOST onPort:_PORT error:&err])
        {
            
        }
        else {
            NSLog(@"ERROR %@",[err description]);
        }
    }
}

#pragma mark - AsyncDelegate
// On connect
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"Connected to Server A (TCP), connecting to Server B (HTTP)");
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.connectionTimeoutTimer invalidate];
    appDelegate.connectionTimeoutTimer = nil;

    //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    NSURL *url = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"wspl-b-address"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:10.0];
    

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (error || !data) {
                NSLog(@"Connection timed out (HTTP)");
                UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                                 message:@"Failed to connect to Server B (HTTP)."
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil] autorelease];
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

                [alert show];
            } else {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSLog(@"Connected to Server B (HTTP)", (long)httpResponse.statusCode);
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            }
        });
    });
    
    [appDelegate.chatsViewController reloadChats];
    [self.asyncSocket readDataWithTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if([self.delegate respondsToSelector:@selector(receivedMessage:)])
    {
        NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self.delegate receivedMessage:str];
    }
    [self.asyncSocket readDataWithTimeout:-1 tag:0];
}

#pragma mark - Diagnostics

- (BOOL)isConnected {
    return [self.asyncSocket isConnected];
}
@end
