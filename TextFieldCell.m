//
//  TextFieldCell.m
//  ReceiptsUploader
//
//  Created by Joel Jeske on 10/15/13.
//  Copyright (c) 2013 Camp Eagle. All rights reserved.
//

#import "TextFieldCell.h"

@implementation TextFieldCell

@synthesize field;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
