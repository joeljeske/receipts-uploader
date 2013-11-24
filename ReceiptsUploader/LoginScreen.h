//
//  LoginScreen.h
//  ReceiptsUploader
//
//  Created by Joel Jeske on 6/12/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginScreen :  UITableViewController<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@end
