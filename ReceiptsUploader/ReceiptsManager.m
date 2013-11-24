//
//  ReceiptsManager.m
//  TestPicker
//
//  Created by Joel Jeske on 4/21/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import "ReceiptsManager.h"
#import "Reachability.h"

#define MANAGER_PLIST @"manager.plist"

#define STORED_RECEIPTS @"receipts"

#define SERVER_DOMAIN @"http://www.campeagle.org"
#define PORTAL_LOGIN @"/portal/portal_login.php"
#define RECEIPT_ACCOUNTS @"/portal/receipts/receipt_accounts.php"
#define RECEIPT_UPLOAD @"/portal/receipts/receipt_image_uploader.php?mode=live"

@implementation ReceiptsManager

static Reachability *reachability;
static ReceiptsManager *instance;

+ (void) initialize{
    [super initialize];
    reachability = [Reachability reachabilityForInternetConnection];
    instance = [[ReceiptsManager alloc] init];
}


+ (BOOL) loginWithInfo:(NSArray *)info
{
    return [ReceiptsManager loginUser:[info objectAtIndex:0] withPassword:[info objectAtIndex:1]];
}


/**
 * @author Joel Jeske
 * tries to login the user using credentials passed in
 * returns true if login was successful and false if failes
 */
+ (BOOL) loginUser:(NSString *)username withPassword:(NSString *)password
{
    
    // Setup URL. (camp eagle portal login php page)
    NSURL *loginUrl = [NSURL URLWithString:[SERVER_DOMAIN stringByAppendingString:PORTAL_LOGIN]];
    
    // Setup Post data in dictionary and then convert to NSString for data encoding 
    NSMutableDictionary *loginInfo = [[NSMutableDictionary alloc] init];
    [loginInfo setObject:@"basic" forKey:@"type"];
    [loginInfo setObject:username forKey:@"login"];
    [loginInfo setObject:password forKey:@"password"];
    NSData *postData = [[self convertDictionaryToString:loginInfo] dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"%@", loginInfo);
    // Setup HTTP Request Object 
    NSMutableURLRequest *loginRequest = [[NSMutableURLRequest alloc] init];
    [loginRequest setURL:loginUrl];
    [loginRequest setHTTPMethod:@"POST"];
    [loginRequest setHTTPBody:postData];
    
    // Send data synchronously
    NSData *response = [NSURLConnection sendSynchronousRequest:loginRequest returningResponse:NULL error:NULL];
    
    // Convert response to string and parse response
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        
    // Check failues on server side
    NSRange failed = [responseString rangeOfString:@"fail" options:NSCaseInsensitiveSearch];
    if(failed.location == 0)
    {
        NSLog(@"server failed");
        return NO;
    }
    
    // Check failure due to incorrect username or password
    if([responseString isEqual: @"user"] || [responseString  isEqual: @"password"])
    {
        NSLog(@"login info incorrect");
        return NO;
    }
    
    // Login attempt must be successful
    // Open dictionary for sustaining user's login
    NSString *plist = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:MANAGER_PLIST];
    NSMutableDictionary *managerDict = [[NSMutableDictionary alloc] initWithContentsOfFile:plist];
    
    //Create the dictionary if this is first login
    if(managerDict == NULL)
        managerDict = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    //echoStr = $row["id"] . "|" . $row["username"] . "|" . $row["lastname"] . "|" . $row["email"] . "| " . null;
    NSArray *loginRespInfo = [responseString componentsSeparatedByString:@"|"];
    NSMutableDictionary *loginDict = [[NSMutableDictionary alloc] initWithCapacity:4];
    [loginDict setObject:[loginRespInfo objectAtIndex:0] forKey:@"portalid"];
    [loginDict setObject:[loginRespInfo objectAtIndex:1] forKey:@"username"];
    [loginDict setObject:[loginRespInfo objectAtIndex:2] forKey:@"lastname"];
    [loginDict setObject:[loginRespInfo objectAtIndex:3] forKey:@"email"];
    [managerDict setObject:loginDict forKey:@"login-info"];
    
    [managerDict writeToFile:plist atomically:NO];
        
    NSLog(@"%@", managerDict);
    [ReceiptsManager ensureAccountsListIsCurrent];

    return YES;

}

// Helper function to convert a dictionary of strings to format: key0=val0&key1=val1...&keyn=valn
+ (NSString *) convertDictionaryToString:(NSDictionary *) dictionary
{
    NSMutableString *vals = [[NSMutableString alloc] init];

    for(id key in [dictionary allKeys])
    {
        [vals appendString:key];
        [vals appendString:@"="];
        [vals appendString:[dictionary objectForKey:key]];
        [vals appendString:@"&"];
    }
    
    if([vals length] > 0) //if no values were found
        return [vals substringToIndex:[vals length]];

    return @"";            
}

// Checks if the user is currently logged in
+ (BOOL) isLoggedIn
{
    NSString *plist = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:MANAGER_PLIST];
    
    NSDictionary *managerDict = [NSDictionary dictionaryWithContentsOfFile:plist];
    BOOL isLoggedIn = [managerDict objectForKey:@"login-info"] != NULL && [[managerDict objectForKey:@"login-info"] count] != 0;
    
    NSLog(isLoggedIn ? @"Logged in" : @"Not logged in");
    return isLoggedIn;
}

// Logouts user by overwriting the login info with an empty dictionary
+ (void) logout
{
    NSLog(@"logout");
    
    NSString *plist = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:MANAGER_PLIST];
    
    NSMutableDictionary *managerDict = [NSMutableDictionary dictionaryWithContentsOfFile:plist];
    
    [managerDict setObject:[[NSDictionary alloc] init] forKey:@"login-info"];
    
    [managerDict writeToFile:plist atomically:NO];
}

/* Will update the local list of accounts if necessary.
 * this functions will send its version of accounts list to the server and the server will reply with
 * an updated list or n
 */
+ (void) ensureAccountsListIsCurrent
{
    // Open main dictionary to get the version of the local accounts list
    NSString *plist = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:MANAGER_PLIST];
    NSMutableDictionary *managerDict = [NSMutableDictionary dictionaryWithContentsOfFile:plist];
    NSString *localVersion = [[managerDict objectForKey:@"accounts"] objectForKey:@"version"];
    
    // Initialize the version to 0 if the accounts list does not exist
    if(localVersion == NULL)
        localVersion = @"0";
    
    // Setup URL and HTTP Request object from URL
    NSMutableDictionary *requestInfo = [[NSMutableDictionary alloc] init];
    [requestInfo setObject:@"version" forKey:@"action"];
    [requestInfo setObject:localVersion forKey:@"version"];
    NSString *queryString = [@"?" stringByAppendingString:[self convertDictionaryToString:requestInfo]];

    NSURL *accountsUrl = [[NSURL alloc] initWithString: [SERVER_DOMAIN stringByAppendingString:[RECEIPT_ACCOUNTS stringByAppendingString:queryString]]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL: accountsUrl];
    
    //Send HTTP request async to not intterupt users
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //NSLog(@"%s", responseString);
        
        NSArray *accountsInfo = [responseString componentsSeparatedByString:@"###"];
        
        if([accountsInfo count] == 1)
            NSLog(@"local version is current");
        else
        {// Update the Acounts list in the local dictionary
            NSLog(@"local version is out of date. array of size: %d", [accountsInfo count]);
            NSString *currentVersion = [accountsInfo objectAtIndex:0]; //Get new version from response
            NSData *accountsList = [[accountsInfo objectAtIndex:1] dataUsingEncoding:NSUTF8StringEncoding] ; //New accounts list from response
            
            NSMutableDictionary *accounts = [[NSMutableDictionary alloc] init];
            
            [accounts setObject:accountsList forKey:@"list"]; //store list
            [accounts setObject:currentVersion forKey:@"version"]; //store version
            [managerDict setObject:accounts forKey:@"accounts"];
            
            NSLog(@"%@", managerDict);
            [managerDict writeToFile:plist atomically:NO];
        }
    }];
}

// Store the receipt image in the local dictionary
+ (void) storeReceipt:(UIImage *)image withInfo:(NSMutableDictionary *)info{
    
    NSString *receiptsFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:STORED_RECEIPTS];
    NSMutableArray *receipts = [NSMutableArray arrayWithContentsOfFile:receiptsFile];
    
    NSString *plist = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:MANAGER_PLIST];
    NSDictionary *loginInfo = [[[NSDictionary alloc] initWithContentsOfFile:plist] objectForKey:@"login-info"];
    NSString *currentTime = [NSString stringWithFormat:@"%0.f", [[NSDate date] timeIntervalSince1970]];
    
    [info setObject:[loginInfo objectForKey:@"portalid"] forKey:@"portalid"];
    [info setObject:[loginInfo objectForKey:@"username"] forKey:@"username"];
    [info setObject:currentTime forKey:@"datetime"];

    
    if(receipts == NULL)
        receipts = [[NSMutableArray alloc] init];

    NSData *imgData = UIImageJPEGRepresentation(image, .5);
    [info setObject:imgData forKey:@"image"];
    
    [receipts addObject:info];
    [receipts writeToFile:receiptsFile atomically:NO];
}

// Tries to upload any stored receipts and returns the number of receipts left
+ (int) uploadStoredReceipts{
    NSString *receiptsFile = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:STORED_RECEIPTS];
    NSMutableArray *receipts = [NSMutableArray arrayWithContentsOfFile:receiptsFile];
    NSMutableArray *incompleteReceipts = [[NSMutableArray alloc] init];
    
    [Base64 initialize];

    NSURL *uploadUrl = [NSURL URLWithString:[SERVER_DOMAIN stringByAppendingString:RECEIPT_UPLOAD]];
    NSMutableDictionary *postq = [[NSMutableDictionary alloc] init];
    NSData *response;
    NSMutableURLRequest *uploadRequest = [NSMutableURLRequest requestWithURL:uploadUrl];
    [uploadRequest setHTTPMethod:@"POST"];
    
    NSLog(@"trying to upload %d receipts", [receipts count]);
    
    //Create the the postq for each receipt and use the 
    for(NSDictionary *r in receipts)
    {
        NSString *img = [Base64 encode:[r objectForKey:@"image"]];
        
        [postq removeAllObjects];
        [postq setObject:[r objectForKey:@"portalid"] forKey:@"pid"];
        [postq setObject:[r objectForKey:@"username"] forKey:@"user"];
        [postq setObject:[r objectForKey:@"total"]    forKey:@"total"];
        [postq setObject:[r objectForKey:@"flag"]     forKey:@"flag"];
        [postq setObject:[r objectForKey:@"amounts"]  forKey:@"amounts"];
        [postq setObject:[r objectForKey:@"accounts"] forKey:@"accounts"];
        [postq setObject:[r objectForKey:@"programs"] forKey:@"programs"];
        [postq setObject:[r objectForKey:@"comments"] forKey:@"comments"];
        [postq setObject:[r objectForKey:@"datetime"] forKey:@"date"];
        [postq setObject:@"ios" forKey:@"utype"];
        [postq setObject:img forKey:@"img"];
        
        [uploadRequest setHTTPBody:[[self convertDictionaryToString:postq] dataUsingEncoding:NSUTF8StringEncoding]];
        
        response = [NSURLConnection sendSynchronousRequest:uploadRequest returningResponse:NULL error:NULL];
        NSString *resp = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        
        if([resp isEqual: @"success"])
        {
            NSLog(@"response: %@", resp);
            NSLog(@"sucessful");
        }
        else
        {
            NSLog(@"not sucessful");
            NSLog(@"response: %@", resp);            
            [incompleteReceipts addObject:r];
        }

    } //end for all receipts to upload
    
    [incompleteReceipts writeToFile:receiptsFile atomically:NO]; //
    
    int remaining = [incompleteReceipts count];
    int original = [receipts count];
    
    
    if(original > remaining)
    {
        UIAlertView *alert;
        NSString *message = [NSString stringWithFormat:@"%d receipt(s) have been uploaded successfully.", original - remaining];

        alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:message  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];    }
    
    
    if(remaining > 0)
    {
        UIAlertView *alert;
        NSString *message = [NSString stringWithFormat:@"You have %d receipt(s) that could not be uploaded. They will be retried when you regain network access.", remaining];
        
        alert = [[UIAlertView alloc] initWithTitle:@"Upload Result" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
    }
    
    return remaining; //the number of receipts left
}


+ (NSDictionary *) getAcountsList
{
    NSString *plist = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:MANAGER_PLIST];
    NSData *accountsList = [[[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"accounts"] objectForKey:@"list"];

    if(accountsList == NULL)
        return [[NSDictionary alloc] init];

    return [[[NSJSONSerialization JSONObjectWithData:accountsList options:NSJSONReadingMutableContainers error:NULL] objectAtIndex:0] objectForKey:@"children"];
}


+ (void) showNoNetworkAlert
{
    NSString *message;
    
    if( [ReceiptsManager isLoggedIn] )
        message = @"You may continue to enter receipts but they will not be uploaded until you receive internet connection again.";
    else
        message = @"You must be logged in to enter receipts while offline.";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

+ (BOOL) isNetworkAvailable
{
    NetworkStatus status = [reachability currentReachabilityStatus];
    return status != NotReachable;
}

+ (void) shouldListenForNetwork:(BOOL)shouldListen
{
    if(shouldListen)
    {
        [reachability startNotifier];
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(networkStatusChanged:) name:kReachabilityChangedNotification object:nil];
        
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:instance];
        [reachability stopNotifier];
    }
}

- (void) networkStatusChanged:(NSNotification *) notification
{
    if([ReceiptsManager isNetworkAvailable])
    {
        //Wait 10 seconds to allow for full connection
        NSTimeInterval time = 10;
        [self performSelector:@selector(uploadInSeperateThread) withObject:nil afterDelay:time];
    }
}

- (void) uploadInSeperateThread
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^(void) {
        
        [ReceiptsManager uploadStoredReceipts];
        
    });
}


@end
