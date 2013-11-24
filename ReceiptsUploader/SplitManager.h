//
//  AddSplit.h
//  ReceiptsUploader
//
//  Created by Joel Jeske on 6/12/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AccountsSearchPicker.h"
@class SplitManager;

@protocol SplitManagerDelegate <NSObject>
- (void)SplitManagerController:(SplitManager *)controller didFinishCreatingSplit:(NSMutableDictionary *)split;
- (void)SplitManagerController:(SplitManager *)controller didRemoveSplit:(NSMutableDictionary *)split;
@end

@interface SplitManager : UITableViewController <AccountsSearchPickerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UITextView *comment;

@property (nonatomic, weak) IBOutlet id <SplitManagerDelegate> delegate;

@property (nonatomic, strong) NSNumber *remaining;

@property (nonatomic, strong) NSMutableDictionary *split;

@property (weak, nonatomic) IBOutlet UITextField *amount;

- (IBAction)saveSplit:(id) sender;
- (IBAction)cancelOrRemove:(id)sender;
@end
