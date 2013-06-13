//
//  sampleViewController.h
//  PopOver
//
//  Created by jing zhao on 6/9/13.
//  Copyright (c) 2013 youdao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SetUpViewController;

@protocol SetupDelegate <NSObject>

-(void)setupViewController:(SetUpViewController*)setupViewController didSelectSetUpRow:(NSInteger)terger;


@end

@interface SetUpViewController : UITableViewController

@property (nonatomic ,assign)id<SetupDelegate> setupDelegate;

@end
