//
//  AccountsSearchPicker.h
//  ReceiptsUploader
//
//  Created by Joel Jeske on 10/25/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AccountsSearchPicker;

@protocol AccountsSearchPickerDelegate <NSObject>
    - (void)AccountsSearchPickerController:(AccountsSearchPicker *)controller didFinishPickingAcount:(NSDictionary *)account;
@end


@interface AccountsSearchPicker : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

    @property (strong, nonatomic) id <AccountsSearchPickerDelegate> delegate;

    @property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
