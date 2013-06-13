//
//  sampleViewController.m
//  PopOver
//
//  Created by jing zhao on 6/9/13.
//  Copyright (c) 2013 youdao. All rights reserved.
//

#import "SetUpViewController.h"

@interface SetUpViewController ()
@property (strong,nonatomic)NSArray *arraySettingChoice;

@end

@implementation SetUpViewController
@synthesize arraySettingChoice,setupDelegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.arraySettingChoice = [NSArray arrayWithObjects:@"关于",@"关于本软件", nil];
    
    self.contentSizeForViewInPopover = CGSizeMake(200, 90);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
      static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	// Set the tableview cell text to the name of the sample at the given index
	NSString *cellSampleName = [self.arraySettingChoice objectAtIndex:indexPath.row];
    
    cell.textLabel.text = cellSampleName;
    cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (setupDelegate && [setupDelegate respondsToSelector:@selector(setupViewController:didSelectSetUpRow:)])
    {
        [setupDelegate setupViewController:self didSelectSetUpRow:indexPath.row];
    }
    
}

@end
