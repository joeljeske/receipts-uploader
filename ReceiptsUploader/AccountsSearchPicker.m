//
//  AccountsSearchPicker.m
//  ReceiptsUploader
//
//  Created by Joel Jeske on 10/25/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//


#import "AccountsSearchPicker.h"
#import "ReceiptsManager.h"

@interface AccountsSearchPicker ()

@end

@implementation AccountsSearchPicker

NSDictionary *accounts;
NSArray *tableList;



- (void)viewDidLoad
{
    [super viewDidLoad];
//    [self.navigationController setNavigationBarHidden:YES];
    accounts = [ReceiptsManager getAcountsList];
    tableList = [self setupListUsingDictionary:accounts withFilter:@"" forcingChildren:NO withSubtext:@""];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Helper Functions
- (NSMutableArray *)setupListUsingDictionary:(NSDictionary *) dict withFilter:(NSString *) query forcingChildren:(BOOL) force withSubtext:(NSString *) parentSubtext
{
    NSMutableArray *list = [[NSMutableArray alloc] init];
    for(id index in [dict allKeys])
    {
        NSMutableDictionary *node = [dict objectForKey:index];
        BOOL found = false;
        if(node == NULL)
            continue;
        
        if([parentSubtext length] > 0 )
            [node setObject:[parentSubtext substringToIndex:[parentSubtext length]-2] forKey:@"subtext"] ;
        
        NSString *subtext = [parentSubtext stringByAppendingFormat:@"%@ > ", [node objectForKey:@"name"]];
        
        found = force || [query isEqual: @""] || [[node objectForKey:@"name"] rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound;
        
        if(found)
            [list addObject:node];
        
        if( [node objectForKey:@"children"] == NULL || [[node objectForKey:@"children"] count] == 0 )
            continue;
        
        BOOL forceChildren = force || (found && ![query isEqual: @""]);
        
        NSArray *childrenFound = [self setupListUsingDictionary:[node objectForKey:@"children"] withFilter:query forcingChildren:forceChildren withSubtext:subtext];
        [list addObjectsFromArray: childrenFound];
    }
    return list;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"asked for sections");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return MAX([tableList count], 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"] ;
    }
    
    if([tableList count] == 0)
    {
        cell.textLabel.text = @"No Search Results to Display";
        cell.detailTextLabel.text = @"";
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        NSDictionary *account = [tableList objectAtIndex:[indexPath row]];
        cell.textLabel.text = [account objectForKey:@"name"];
        cell.detailTextLabel.text = [account objectForKey:@"subtext"];
        
        if( [[account objectForKey:@"disabled"] intValue] == 1 )
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
    }
    return cell;}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([tableList count] != 0)
    {
        NSDictionary *account = [tableList objectAtIndex:[indexPath row]];
        if( [[account objectForKey:@"disabled"] intValue] != 1 )
        {
            [self.delegate AccountsSearchPickerController:self didFinishPickingAcount:account];
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - SearchViewController
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if(searchText == NULL)
        searchText = @"";
    
    tableList = [self setupListUsingDictionary:accounts withFilter:searchText forcingChildren:NO withSubtext:@""];
    [self.tableView reloadData];
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.view endEditing:YES];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}


@end
