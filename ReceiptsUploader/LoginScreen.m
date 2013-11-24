//
//  LoginScreen.m
//  ReceiptsUploader
//
//  Created by Joel Jeske on 6/12/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import "LoginScreen.h"
#import "ReceiptsManager.h"

@interface LoginScreen ()

@end

@implementation LoginScreen

@synthesize username, password;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    NSLog(@"Requesting logout...");
    [ReceiptsManager logout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)login{
    if( ![ReceiptsManager isNetworkAvailable] )
    {
        [ReceiptsManager showNoNetworkAlert];
        return;
    }
    UIAlertView *notice = [[UIAlertView alloc] initWithTitle:@"Logging in..." message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    
    [notice performSelectorInBackground:@selector(show) withObject:nil];
    
    NSString *user = username.text == NULL ? @"" : username.text;
    NSString *pass = password.text == NULL ? @"" : password.text;
    
    BOOL isLoggedIn = [ReceiptsManager loginUser:user withPassword:pass];
    
    [notice dismissWithClickedButtonIndex:0 animated:YES];

    if(isLoggedIn)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        password.text = @"";
        [password becomeFirstResponder];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Your username or password is incorrect. Please enter them again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(indexPath.section == 1)
        [self login];
    else if(indexPath.row == 0)
        [self.username becomeFirstResponder];
    else if(indexPath.row == 1)
        [self.password becomeFirstResponder];
            
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == username)
    {
        [username resignFirstResponder];
        [password becomeFirstResponder];
    }
    if(textField == password)
    {
        [password resignFirstResponder];
        [self login];
    }
    return NO;
}

@end
