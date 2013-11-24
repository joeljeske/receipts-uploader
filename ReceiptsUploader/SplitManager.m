//
//  AddSplit.m
//  ReceiptsUploader
//
//  Created by Joel Jeske on 6/12/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import "SplitManager.h"

@interface SplitManager ()

@end


UITextField *program;
UIPickerView *programPicker;
BOOL isNewSplit = NO;

@implementation SplitManager

@synthesize delegate, remaining, split, table, amount, comment;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;

    if( split == nil)
    {
        split = [[NSMutableDictionary alloc] init];
        isNewSplit = YES;
    }
    else
        isNewSplit = NO;
    
    // initialize amount inputfield
    if( !isNewSplit )
        amount.text = [NSString stringWithFormat:@"%.02f", [[split objectForKey:@"amount"] floatValue]];
    else if( [remaining floatValue] > 0 )
        amount.text = [NSString stringWithFormat:@"%.02f", [remaining floatValue]];

    
    // setup comment textarea
    if( !isNewSplit )
        comment.text = [split objectForKey:@"comment"];
    
    // setup program picker view 
    program = [[UITextField alloc] init ];
    programPicker = [[UIPickerView alloc] init];
    programPicker.delegate = self;
    programPicker.dataSource = self;
    programPicker.showsSelectionIndicator = YES;
    [program setEnabled:YES];
    program.inputView =programPicker;
    [self.view addSubview:program];
    
    
    //setup keyboard toolbar
    UIToolbar *keyboardToolbar = [self createKeyboardToolbar];

    [program setInputAccessoryView:keyboardToolbar];
    [comment setInputAccessoryView:keyboardToolbar];
    [amount setInputAccessoryView:keyboardToolbar];
    
    // Change cancel to remove if it is not a new split
    if( !isNewSplit )
    {
        self.navigationItem.leftBarButtonItem.tintColor = [UIColor redColor];
        self.navigationItem.leftBarButtonItem.title = @"Delete";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Button responses

// DONE (Keyboard Accessory View Button)
- (void)resignKeyboard
{
    if([program isFirstResponder])
    {
        [self pickerView:programPicker didSelectRow:[programPicker selectedRowInComponent:0] inComponent:0];
        [program resignFirstResponder];
    }
    
    if([comment isFirstResponder])
        [comment resignFirstResponder];
    
    if([amount isFirstResponder])
        [amount resignFirstResponder];
}

// PREVIOUS (Keyboard Accessory View Button)
- (void)previousField
{
    if( [amount isFirstResponder] )
    {
        [amount resignFirstResponder];
        [comment becomeFirstResponder];
    }
    else if( [program isFirstResponder] )
    {
        [self pickerView:programPicker didSelectRow:[programPicker selectedRowInComponent:0] inComponent:0];
        [program resignFirstResponder];
        [self pickAccount];
    }
    else if( [comment isFirstResponder] )
    {
        [comment resignFirstResponder];
        [self pickProgram];
    }
}
// NEXT (Keyboard Accessory View Button)
- (void)nextField
{
    if( [comment isFirstResponder] )
    {
        [comment resignFirstResponder];
        [amount becomeFirstResponder];
    }
    
    else if( [amount isFirstResponder] )
    {
        [amount resignFirstResponder];
        [self pickAccount];
    }
    
    else if( [program isFirstResponder] )
    {
        [self pickerView:programPicker didSelectRow:[programPicker selectedRowInComponent:0] inComponent:0];
        [program resignFirstResponder];
        [comment becomeFirstResponder];
    }

}

// Cancel / Remove
- (IBAction)cancelOrRemove:(id) sender
{
    if( !isNewSplit )
        [self.delegate SplitManagerController:self didRemoveSplit:split];
     
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveSplit:(id) sender
{
    [self resignKeyboard];
    
    if( [self validateForm] )
    {
        [split setObject:[comment.text stringByReplacingOccurrencesOfString:@";" withString:@""] forKey:@"comment"]; //removes split char ';'
        [split setObject:[NSString stringWithFormat:@"%.02f",[amount.text floatValue]] forKey:@"amount"];
        [self.delegate SplitManagerController:self didFinishCreatingSplit:split];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
#pragma mark - General Helper functions

- (UIToolbar*)createKeyboardToolbar {
    //Create basic toolbar
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar setBarStyle:UIBarStyleDefault];
    [toolbar sizeToFit];
    
    // Create and setup previous button
    UIBarButtonItem *previousButton = [[UIBarButtonItem alloc]initWithTitle:@"Previous" style:UIBarButtonItemStyleBordered
                                 
                                                                     target:self action:@selector(previousField)];
    // Create and setup next button
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleBordered
                                                                  target:self action:@selector(nextField)];
    
    // Create flex space
    UIBarButtonItem *flexibleSpaceLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    // Create and setup done button
    UIBarButtonItem *doneButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(resignKeyboard)];
    
    // Add buttons to toolbar
    [toolbar setItems:[NSArray arrayWithObjects:previousButton, nextButton, flexibleSpaceLeft, doneButton, nil]];
    
    return toolbar;
}

- (BOOL)validateForm
{
    BOOL valid = YES;
    
    //Validate amount decimal count
    NSArray *components = [amount.text componentsSeparatedByString:@"."];
    if( [components count] > 2)
        valid = NO;
    
    //Validate positive amount
    if( [amount.text floatValue] <= 0)
        valid = NO;
    
    //Validate account
    if( [split objectForKey:@"account"] == nil )
        valid = NO;
    
    //Validate Pogram
    if( [split objectForKey:@"program"] == nil)
        valid = NO;

    // Show alert
    if(!valid)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Split" message:@"Make sure you set a valid amount, account and program." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    return valid;
}

- (void)pickAccount
{
    [self resignKeyboard];

    AccountsSearchPicker *accountsPicker = [self.storyboard instantiateViewControllerWithIdentifier:@"accounts_search"];
    accountsPicker.delegate = self;
    [self.navigationController pushViewController:accountsPicker animated:YES];
}

- (void)pickProgram
{
    if( [split objectForKey:@"account"] != nil)
    {
        NSLog(@"Opening program picker...");
        [(UIPickerView *)program.inputView reloadAllComponents];
        [program becomeFirstResponder];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pick an Account" message:@"Please choose an account before you choose a program." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


#pragma  mark - Accounts picker delegate
- (void)AccountsSearchPickerController:(AccountsSearchPicker *)controller didFinishPickingAcount:(NSDictionary *)account
{
    [split setObject:account forKey:@"account"];
    [split setObject:@"" forKey:@"program"];
    [table reloadData];
    [self pickProgram];
}


#pragma mark - Table view data source
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    switch (section) {
        case 0:
            title = [NSString stringWithFormat:@"$%.02f remaining", [remaining floatValue]];
            break;
        case 1:
            title = @"Comment";
            break;
            
        default:
            title = @"";
            break;
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if(indexPath.section == 0)
    {
        NSString *replacementDetailLabel;
        
        switch (indexPath.row) {
            case 1:
                replacementDetailLabel = [[split objectForKey:@"account"] objectForKey: @"name"];
                break;
            case 2:
                replacementDetailLabel = [split objectForKey:@"program"];
                break;
                
            default:
                break;
        }

        if(replacementDetailLabel != nil && [replacementDetailLabel length] != 0)
            cell.detailTextLabel.text = replacementDetailLabel;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0)
    {
        switch( [indexPath row] )
        {
            case 0:
                [self.amount becomeFirstResponder];
                break;
            case 1: //Pick account button
                [self pickAccount];
                break;
            case 2: //Pick Program button
                [self pickProgram];
                break;
        
            default:
                break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Picker view data source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1; //Only one category
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if( [split objectForKey:@"account"] == nil) //If there are no available programs
        return 0;

    //else return the amount of programs available
    return [[[split objectForKey:@"account"] objectForKey:@"program"] count];
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    //return the name of the program
    return [[[split objectForKey:@"account"] objectForKey:@"program"] objectAtIndex:row]; 
}

#pragma  mark - Picker view delegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // Get the selected program and store it in the splits dictionary
    NSString *program = [[[split objectForKey:@"account"] objectForKey:@"program"] objectAtIndex:row];
    [split setObject:program forKey:@"program"];
    
    // display changes
    [table reloadData];
}
@end
