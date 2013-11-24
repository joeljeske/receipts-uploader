//
//  ReceiptsManager.h
//  TestPicker
//
//  Created by Joel Jeske on 4/21/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Base64.h"

@interface ReceiptsManager : NSObject

+ (int) uploadStoredReceipts;

+ (BOOL) isLoggedIn; // complete

+ (BOOL) loginUser:(NSString *)username withPassword:(NSString *)password; //complete

+ (void) logout; //complete

+ (void) ensureAccountsListIsCurrent; //complete

+ (NSDictionary *) getAcountsList;

+ (void) storeReceipt:(UIImage *) image withInfo:(NSMutableDictionary *) info; //Needs to convert image to data

+ (BOOL) isNetworkAvailable;

+ (void) showNoNetworkAlert;

+ (void) shouldListenForNetwork:(BOOL) shouldListen;


@end
