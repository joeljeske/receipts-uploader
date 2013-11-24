//
//  FormViewViewController.m
//  ReceiptsUploader
//
//  Created by Joel Jeske on 10/14/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import "FormViewViewController.h"
#import "TextFieldCell.h"
#import "FlagCell.h"
#import "ImageCell.h"
#import "ReceiptsManager.h"

@interface FormViewViewController ()

@end

@implementation FormViewViewController

// String contstants
NSString *const CHOOSE_EXISTING = @"Choose Existing";
NSString *const TAKE_NEW_PHOTO = @"Take Photo";

NSMutableArray *splits;
UIActionSheet *sheet;
UITextField *total;
UISwitch *flagged;
UIImage *receiptImage;
UIToolbar *keyboardToolbar;


- (void)viewDidLoad
{
    [super viewDidLoad];
    splits = [[NSMutableArray alloc] init];
    
    [self setupActionSheet];
    [self resetForm];
    
    if( ![ReceiptsManager isLoggedIn] )
        [self performSegueWithIdentifier:@"login" sender:self];

    keyboardToolbar = [self createKeyboardToolbar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)uploadStoredReceipts
{
    [ReceiptsManager uploadStoredReceipts];
}

#pragma mark - General Helper functions

- (UIToolbar*)createKeyboardToolbar {
    //Create basic toolbar
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleDefault];    [toolbar sizeToFit];

    // Create flex space
    UIBarButtonItem *flexibleSpaceLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Create and setup done button
    UIBarButtonItem *doneButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(resignKeyboard)];
    
    // Add buttons to toolbar
    [toolbar setItems:[NSArray arrayWithObjects:flexibleSpaceLeft, doneButton, nil]];
    
    return toolbar;
}

- (void) setupActionSheet 
{
    /* Setup ActionSheet for image choosing */
    sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    if( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] )
        [sheet addButtonWithTitle:TAKE_NEW_PHOTO];
    if( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] )
        [sheet addButtonWithTitle:CHOOSE_EXISTING];
    [sheet addButtonWithTitle:@"Cancel"];
    [sheet setCancelButtonIndex:sheet.numberOfButtons - 1];   
}

// Reset the whole form
- (void)resetForm
{
    [splits removeAllObjects];
    receiptImage = nil;
    total.text = @"";
    [flagged setOn:NO];
    [self.tableView reloadData];
}

- (float) calculateRemaining
{
    float totalAmount = 0;
    float splitAmount = 0;
    
    if([total.text length] != 0)
        totalAmount = [total.text floatValue];
    
    for(NSDictionary *split in splits)
        splitAmount += [[split objectForKey:@"amount"] floatValue];
    
    return totalAmount - splitAmount;
}


- (BOOL) validateForm
{
    BOOL valid = YES;
    
    if(receiptImage == nil)
        valid = NO;
    
    if(valid && [total.text length] == 0)
        valid = NO;
    
    if(valid && [splits count] == 0)
        valid = NO;
    
    if(valid && [self calculateRemaining] != 0)
        valid = NO;
    
    if(!valid)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Receipt" message:@"Make sure you choose a picture and confirm the splits add up to the total." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    return valid;
}

#pragma mark - Action responses
- (void)resignKeyboard
{
    [total resignFirstResponder];
    [self.tableView reloadData];
}

- (void)didChooseImageButton
{
    NSLog(@"Showing image options...");
    [sheet showInView:self.tableView];
}

- (IBAction)didTrySubmit:(id)sender {
   
    UIAlertView *indicatorAlert = [[UIAlertView alloc] initWithTitle:@"Uploading Receipts..." message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles: nil];
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    if( [self validateForm])
    {
        
        [indicatorAlert addSubview:indicator];
        [indicator startAnimating];
        [indicatorAlert show];
        indicator.center = CGPointMake( indicatorAlert.bounds.size.width/2,  indicatorAlert.bounds.size.height/2+10);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^(void) {
            
            NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
            [info setObject:[NSString stringWithFormat:@"%.02f", [total.text floatValue]] forKey:@"total"];
            [info setObject:[flagged isOn]?@"1":@"0" forKey:@"flag"];
            
            NSMutableArray *amountsArray  = [[NSMutableArray alloc] init];
            NSMutableArray *accountsArray = [[NSMutableArray alloc] init];
            NSMutableArray *programsArray = [[NSMutableArray alloc] init];
            NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
            
            for(NSDictionary* split in splits)
            {
                [accountsArray addObject:[[split objectForKey:@"account"] objectForKey:@"name"]];
                [amountsArray addObject:[split objectForKey:@"amount"]];
                [programsArray addObject:[split objectForKey:@"program"]];
                [commentsArray addObject:[split objectForKey:@"comment"]];
            }
            
            NSString *amounts  = [amountsArray componentsJoinedByString:@";"];
            NSString *accounts = [accountsArray componentsJoinedByString:@";"];
            NSString *programs = [programsArray componentsJoinedByString:@";"];
            NSString *comments = [commentsArray componentsJoinedByString:@";"];
            
            [info setObject:amounts  forKey:@"amounts"];
            [info setObject:accounts forKey:@"accounts"];
            [info setObject:programs forKey:@"programs"];
            [info setObject:comments forKey:@"comments"];
            
            [ReceiptsManager storeReceipt:receiptImage withInfo:info];

            
            if( [ReceiptsManager isNetworkAvailable] )
            {
                [ReceiptsManager uploadStoredReceipts];
            }
            else
            {
                [ReceiptsManager showNoNetworkAlert];
            }
            
            [indicatorAlert performSelectorOnMainThread:@selector(dismissWithClickedButtonIndex:animated:) withObject:0 waitUntilDone:YES];
            
            [self performSelectorOnMainThread:@selector(resetForm) withObject:nil waitUntilDone:YES ];
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        });
    }
}

- (void)chooseImageFromSource:(UIImagePickerControllerSourceType) source {
    NSLog(@"Choosing image...");
    UIImagePickerController *picker;
   
    picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = source;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)didChooseSplitForSplitAtIndex:(NSInteger) index
{
    SplitManager *splitController = [self.storyboard instantiateViewControllerWithIdentifier:@"add_split_controller"];
    
    splitController.delegate = self;
    splitController.remaining = [NSNumber numberWithFloat:[self calculateRemaining]];

    if(index < [splits count]) // Edit existing split
        splitController.split = [splits objectAtIndex:index];
    
    [self.navigationController pushViewController:splitController animated:YES];
}

#pragma mark - Table view data source
// STATIC: always two sections
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

// Number of rows in each section
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows;
    
    switch( section )
    {
        case 0:
            rows = 3; //Always 3 rows in upper section
            break;
        case 1:
            rows = [splits count] + 1; // Always 1 + number of splits
            break;
        default:
            rows = 0;
            break;
    }
    return rows;
}

// Title headers for table sections
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
        return @"Receipt Details";

    if(section == 1)
        return @"Splits";
    
    return nil;
}

// Title footers for table sections
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footer = @"";
    if(section == 1)
    {
        float remaining = [self calculateRemaining];
        if(remaining != 0)
            footer = [NSString stringWithFormat:@"$%.02f remaining", remaining];
    }
    return footer;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier;
    UITableViewCell *cell;
    
    if( [indexPath section] == 0)
    {
        switch ([indexPath row])
        {
            case 0:
                if(receiptImage == nil)
                    CellIdentifier = @"image_not_selected";
                else
                    CellIdentifier = @"image_selected";
                break;
            case 1:
                CellIdentifier = @"total";
                break;
            case 2:
                CellIdentifier = @"flag";
                break;
            default:
                break;
        }
    }
    else
    {
        if([indexPath row] == [splits count]) // Add new split cell
            CellIdentifier = @"add_account";
        else
            CellIdentifier = @"account"; // Finished split cell
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    

    if( [indexPath section] == 0)
    {
        switch ([indexPath row])
        {
            case 0:
                if( receiptImage != nil)
                    ((ImageCell*)cell).image.image = receiptImage;
                break;
            case 1:
                total = ((TextFieldCell*)cell).field;
                [total setInputAccessoryView: keyboardToolbar];
                break;
            case 2:
                flagged = ((FlagCell*)cell).flag;
                break;
            default:
                break;
        }
    }
    else
    {
        if([indexPath row] < [splits count]) // Add new split cell
        {
            NSDictionary *split = [splits objectAtIndex:[indexPath row]];
            cell.textLabel.text = [[[@"$" stringByAppendingString:[split objectForKey:@"amount"]] stringByAppendingString: @" - "] stringByAppendingString:[[split objectForKey:@"account"] objectForKey:@"name" ]];
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
    {
        switch (indexPath.row) {
            case 0:
                [self didChooseImageButton];
                break;
            case 1:
                [total becomeFirstResponder];
                break;
            default:
                break;
        }
    }
    else if(indexPath.section == 1)
    {
        [self didChooseSplitForSplitAtIndex: indexPath.row];
    }
        
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Image picker delegate
- (void)imagePickerController:(UIImagePickerController *) Picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    receiptImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    int originalPixels = receiptImage.size.height * receiptImage.size.width;
    int targetPixels = 409600; // 640*640
    float ratio = receiptImage.size.width / receiptImage.size.height;
    CGSize newSize;
    
    // Portrait
    if( receiptImage.size.height > receiptImage.size.width)
    {
        newSize = CGSizeMake( 640 * ratio, 640);
    }
    // Landscape
    else
    {
        newSize = CGSizeMake( 640, 640 / ratio);
    }
    
    if(  originalPixels > targetPixels )
    {
        receiptImage = [self imageWithImage:receiptImage convertToSize:newSize];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.tableView reloadData];
}

- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}


#pragma mark - Action sheet delegate
- (void)actionSheetCancel:(UIActionSheet *)actionSheet{
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if( [[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:CHOOSE_EXISTING] )
        [self chooseImageFromSource: UIImagePickerControllerSourceTypePhotoLibrary];

         if( [[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:TAKE_NEW_PHOTO] )
        [self chooseImageFromSource: UIImagePickerControllerSourceTypeCamera];
}


#pragma mark - Add Split Delegate
- (void)SplitManagerController:(SplitManager *)controller didFinishCreatingSplit:(NSMutableDictionary *)split
{
    
    if( ![splits containsObject: split] )
        [splits addObject: split];
    
    [self.tableView reloadData];
}

- (void)SplitManagerController:(SplitManager *)controller didRemoveSplit:(NSMutableDictionary *)split
{
    [splits removeObject:split];
    [self.tableView reloadData];
}



@end
