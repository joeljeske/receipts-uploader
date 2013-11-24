//
//  FormViewViewController.h
//  ReceiptsUploader
//
//  Created by Joel Jeske on 10/14/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SplitManager.h"

@interface FormViewViewController : UITableViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SplitManagerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *submitButton;


- (IBAction)didTrySubmit:(id)sender;


@end
