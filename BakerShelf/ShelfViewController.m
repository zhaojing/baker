//
//  ShelfViewController.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials
//  provided with the distribution.
//  Neither the name of the Baker Framework nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#define UMShareContent   @"有道杂志"
#define UMShareImageUrl  @"http://ent.appmars.com/prss/part3.png"
#define UMShareHylink    @"http://www.xayoudao.com/qujianglvyou/"
#define CustomActivity_IndicatorViewFrame  CGRectMake(462, 334, 100, 100)
#define CustomActivity_ActivityIndicatorFrame CGRectMake(31, 32, 37, 37)



#import "ShelfViewController.h"
#import "UICustomNavigationBar.h"
#import "Constants.h"
#import "WebViewController.h"

#import "BakerViewController.h"
#import "IssueViewController.h"

#import "NSData+Base64.h"
#import "NSString+Extensions.h"
#import "Utils.h"

#import "UMSocialControllerService.h"
//#import "UMSocialConfigDelegate.h"
#import "UMSocialData.h"
#import "UMSocialConfig.h"
#import "UMSocialSnsPlatformManager.h"
#import "WXApi.h"
#import "SetUpViewController.h"


@interface ShelfViewController ()<UIActionSheetDelegate,SetupDelegate>

@property (strong, nonatomic)UIButton *shareButton;
@property (strong, nonatomic)UIButton *sysTemButton;

@property (strong, nonatomic) NSArray *arrayPlatForm;
@property (strong, nonatomic) NSMutableArray *arrayPlayName;
@property (strong, nonatomic) UIActionSheet * editActionSheet;
@property (strong, nonatomic) SetUpViewController * setUpViewController;
@property (strong, nonatomic) UIPopoverController * pop;
@property (strong, nonatomic) UIView *viewActivityIndicatorView;
@property (strong, nonatomic) UIActivityIndicatorView *largeActivity;

@end

@implementation ShelfViewController
@synthesize issues;
@synthesize issueViewControllers;
@synthesize carousel;
@synthesize subscribeButton;
@synthesize refreshButton;
@synthesize shelfStatus;
@synthesize subscriptionsActionSheet;
@synthesize supportedOrientation;
@synthesize blockingProgressView;
@synthesize bookToBeProcessed;
@synthesize shareButton;
@synthesize sysTemButton;
@synthesize arrayPlatForm;
@synthesize arrayPlayName;
@synthesize editActionSheet;
@synthesize setUpViewController;
@synthesize pop;
@synthesize viewActivityIndicatorView;
@synthesize largeActivity;

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
#ifdef BAKER_NEWSSTAND
        purchasesManager = [PurchasesManager sharedInstance];
        
        [self addPurchaseObserver:@selector(handleProductsRetrieved:)
                             name:@"notification_products_retrieved"];
        [self addPurchaseObserver:@selector(handleProductsRequestFailed:)
                             name:@"notification_products_request_failed"];
        [self addPurchaseObserver:@selector(handleSubscriptionPurchased:)
                             name:@"notification_subscription_purchased"];
        [self addPurchaseObserver:@selector(handleSubscriptionFailed:)
                             name:@"notification_subscription_failed"];
        [self addPurchaseObserver:@selector(handleSubscriptionRestored:)
                             name:@"notification_subscription_restored"];
        [self addPurchaseObserver:@selector(handleRestoreFailed:)
                             name:@"notification_restore_failed"];
        [self addPurchaseObserver:@selector(handleMultipleRestores:)
                             name:@"notification_multiple_restores"];
        [self addPurchaseObserver:@selector(handleRestoredIssueNotRecognised:)
                             name:@"notification_restored_issue_not_recognised"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveBookProtocolNotification:)
                                                     name:@"notification_book_protocol"
                                                   object:nil];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:purchasesManager];
#endif
        
        api = [BakerAPI sharedInstance];
        issuesManager = [[IssuesManager sharedInstance] retain];
        notRecognisedTransactions = [[NSMutableArray alloc] init];
        
        self.shelfStatus = [[[ShelfStatus alloc] init] autorelease];
        self.issueViewControllers = [[[NSMutableArray alloc] init] autorelease];
        self.supportedOrientation = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
        self.bookToBeProcessed = nil;
        
#ifdef BAKER_NEWSSTAND
        [self handleRefresh:nil];
#endif
    }
    return self;
}

- (id)initWithBooks:(NSArray *)currentBooks
{
    self = [self init];
    if (self) {
        self.issues = currentBooks;
        
        NSMutableArray *controllers = [NSMutableArray array];
        for (BakerIssue *issue in self.issues) {
            IssueViewController *controller = [self createIssueViewControllerWithIssue:issue];
            [controllers addObject:controller];
        }
        self.issueViewControllers = [NSMutableArray arrayWithArray:controllers];
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    //    [gridView release];
    [issueViewControllers release];
    [issues release];
    [subscribeButton release];
    [refreshButton release];
    [shelfStatus release];
    [subscriptionsActionSheet release];
    [supportedOrientation release];
    [blockingProgressView release];
    [issuesManager release];
    [notRecognisedTransactions release];
    [bookToBeProcessed release];
    
#ifdef BAKER_NEWSSTAND
    [purchasesManager release];
#endif
    
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 分享的内容
    UMSocialData *socialData = [UMSocialData defaultData];
    socialData.shareText = UMShareContent ;
    UMSocialUrlResource *urlresource = [[UMSocialUrlResource alloc] initWithSnsResourceType:UMSocialUrlResourceTypeImage
                                                                                        url:UMShareImageUrl];
    socialData.urlResource = urlresource;
    
    //分享的弹出界面
    self.arrayPlatForm = [NSArray arrayWithObjects:UMShareToSina,UMShareToTencent,UMShareToQzone,UMShareToEmail,UMShareToSms, nil];
    self.arrayPlayName = [NSMutableArray arrayWithObjects:@"微信好友",@"微信朋友圈", nil];
    for (NSString *snsName in self.arrayPlatForm)
    {
        UMSocialSnsPlatform *snsPlatform = [UMSocialSnsPlatformManager getSocialPlatformWithName:snsName];
        [self.arrayPlayName addObject:snsPlatform.displayName];
    }
    self.editActionSheet = [[UIActionSheet alloc] initWithTitle:@"分享" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *snsName in self.arrayPlayName)
    {
        [self.editActionSheet addButtonWithTitle:snsName];
    }
    [self.editActionSheet addButtonWithTitle:@"取消"];
    self.editActionSheet.cancelButtonIndex = self.editActionSheet.numberOfButtons - 1;
    self.editActionSheet.delegate = self;
    
    self.navigationItem.title = NSLocalizedString(@"SHELF_NAVIGATION_TITLE", nil);
    self.background = [[[UIImageView alloc] init] autorelease];
    _wrap = YES;
    
    //滚动Carousel
    self.carousel = [[iCarousel alloc]init];
    self.carousel.dataSource = self;
    self.carousel.delegate = self;
    carousel.type = iCarouselTypeCoverFlow2;
    [self.view addSubview:self.background];
    [self.view addSubview:self.carousel];
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
    [self.carousel reloadData];
    
    
    //progress
    self.viewActivityIndicatorView = [[UIView alloc]initWithFrame:CustomActivity_IndicatorViewFrame];
    [self.viewActivityIndicatorView setBackgroundColor:[UIColor blackColor]];
    [self.viewActivityIndicatorView setAlpha:0.5];
    self.viewActivityIndicatorView.layer.cornerRadius = 10;
    [self.view addSubview:self.viewActivityIndicatorView];
    self.viewActivityIndicatorView.hidden = YES;
    
    self.largeActivity = [[UIActivityIndicatorView alloc]initWithFrame:CustomActivity_ActivityIndicatorFrame];
    self.largeActivity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [self.viewActivityIndicatorView addSubview:self.largeActivity];
    
    
#ifdef BAKER_NEWSSTAND
    
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.refreshButton setImage:[UIImage imageNamed:@"shelf_bg_refresh.png"] forState:UIControlStateNormal];
    [self.refreshButton addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.refreshButton];
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.shareButton setImage:[UIImage imageNamed:@"shelf_bg_share.png"] forState:UIControlStateNormal];
    [self.shareButton addTarget:self action:@selector(handleShare:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.shareButton];
    
    self.sysTemButton= [UIButton buttonWithType:UIButtonTypeCustom];
    [self.sysTemButton setImage:[UIImage imageNamed:@"shelf_bg_system.png"] forState:UIControlStateNormal];
    [self.sysTemButton addTarget:self action:@selector(handleSetUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sysTemButton];
    
    setUpViewController = [[SetUpViewController alloc]initWithStyle:UITableViewStylePlain];
    setUpViewController.setupDelegate = self;
    self.pop = [[UIPopoverController alloc]initWithContentViewController:setUpViewController];
    
    
    self.subscribeButton = [[[UIBarButtonItem alloc]
                             initWithTitle: NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil)
                             style:UIBarButtonItemStylePlain
                             target:self
                             action:@selector(handleSubscribeButtonPressed:)]
                            autorelease];
    
    self.blockingProgressView = [[UIAlertView alloc]
                                 initWithTitle:@"Processing..."
                                 message:@"\n"
                                 delegate:nil
                                 cancelButtonTitle:nil
                                 otherButtonTitles:nil];
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.center = CGPointMake(139.5, 75.5); // .5 so it doesn't blur
    [self.blockingProgressView addSubview:spinner];
    [spinner startAnimating];
    [spinner release];
    
    NSMutableSet *subscriptions = [NSMutableSet setWithArray:AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS];
    if ([FREE_SUBSCRIPTION_PRODUCT_ID length] > 0 && ![purchasesManager isPurchased:FREE_SUBSCRIPTION_PRODUCT_ID]) {
        [subscriptions addObject:FREE_SUBSCRIPTION_PRODUCT_ID];
    }
    [purchasesManager retrievePricesFor:subscriptions andEnableFailureNotifications:NO];
#endif
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController setNavigationBarHidden:YES];
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
    
    for (IssueViewController *controller in self.issueViewControllers) {
        controller.issue.transientStatus = BakerIssueTransientStatusNone;
        [controller refresh];
    }
    
#ifdef BAKER_NEWSSTAND
    //    NSMutableArray *buttonItems = [NSMutableArray arrayWithObject:self.refreshButton];
    //    if ([purchasesManager hasSubscriptions] || [issuesManager hasProductIDs]) {
    //        [buttonItems addObject:self.subscribeButton];
    //    }
    //    self.navigationItem.leftBarButtonItems = buttonItems;
#endif
}
- (void)viewDidAppear:(BOOL)animated
{
    if (self.bookToBeProcessed) {
        [self handleBookToBeProcessed];
    }
}
- (NSInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [supportedOrientation indexOfObject:[NSString stringFromInterfaceOrientation:interfaceOrientation]] != NSNotFound;
}
- (BOOL)shouldAutorotate
{
    return YES;
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    int width  = 0;
    int height = 0;
    
    CGRect rect = [UIApplication sharedApplication].statusBarFrame;
    
    NSString *image = @"";
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width  = size.width;
        height = size.height - 64;
        image  = @"shelf-bg-portrait";
    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        width  = size.height;
        height = size.width - rect.size.width;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            height = height + 12;
        }
        image  = @"shelf-bg-landscape";
    }
    
    if (size.height == 568) {
        image = [NSString stringWithFormat:@"%@-568h.png", image];
    } else {
        image = [NSString stringWithFormat:@"%@.png", image];
    }
    
    //    int bannerHeight = [ShelfViewController getBannerHeight];
    self.carousel.frame = CGRectMake(0, 117, width, 600);
    self.refreshButton.frame = CGRectMake(24, 10, 60, 60);
    self.shareButton.frame = CGRectMake(size.height - 128, 10, 60, 60);
    self.sysTemButton.frame = CGRectMake(size.height-64, 10, 60, 60);
    
    
    self.background.frame = CGRectMake(0, 0, width, 748);
    self.background.image = [UIImage imageNamed:image];
    
    //    self.gridView.frame = CGRectMake(0, bannerHeight, width, height - bannerHeight);
}
- (IssueViewController *)createIssueViewControllerWithIssue:(BakerIssue *)issue
{
    IssueViewController *controller = [[[IssueViewController alloc] initWithBakerIssue:issue] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReadIssue:) name:@"read_issue_request" object:controller];
    return controller;
}

//#pragma mark - Shelf data source

//- (NSUInteger)numberOfItemsInGridView:(AQGridView *)aGridView
//{
//    return [issueViewControllers count];
//}
//- (AQGridViewCell *)gridView:(AQGridView *)aGridView cellForItemAtIndex:(NSUInteger)index
//{
//    CGSize cellSize = [IssueViewController getIssueCellSize];
//    CGRect cellFrame = CGRectMake(0, 0, cellSize.width, cellSize.height);
//
//    static NSString *cellIdentifier = @"cellIdentifier";
//    AQGridViewCell *cell = (AQGridViewCell *)[self.gridView dequeueReusableCellWithIdentifier:cellIdentifier];
//	if (cell == nil)
//	{
//		cell = [[[AQGridViewCell alloc] initWithFrame:cellFrame reuseIdentifier:cellIdentifier] autorelease];
//		cell.selectionStyle = AQGridViewCellSelectionStyleNone;
//
//        cell.contentView.backgroundColor = [UIColor clearColor];
//        cell.backgroundColor = [UIColor clearColor];
//	}
//
//    IssueViewController *controller = [self.issueViewControllers objectAtIndex:index];
//    UIView *removableIssueView = [cell.contentView viewWithTag:42];
//    if (removableIssueView) {
//        [removableIssueView removeFromSuperview];
//    }
//    [cell.contentView addSubview:controller.view];
//
//    return cell;
//}
//- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)aGridView
//{
//    return [IssueViewController getIssueCellSize];
//}

#ifdef BAKER_NEWSSTAND
- (void)handleRefresh:(NSNotification *)notification {
    [self setrefreshButtonEnabled:NO];
    
    self.viewActivityIndicatorView.hidden = NO;
    [self.largeActivity startAnimating];
    
    if([issuesManager refresh]) {
        self.issues = issuesManager.issues;
        
        [purchasesManager retrievePurchasesFor:[issuesManager productIDs]];
        
        [shelfStatus load];
        for (BakerIssue *issue in self.issues) {
            issue.price = [shelfStatus priceFor:issue.productID];
        }
        
        [self.issues enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            // NOTE: this block changes the issueViewController array while looping
            
            IssueViewController *existingIvc = nil;
            if (idx < [self.issueViewControllers count]) {
                existingIvc = [self.issueViewControllers objectAtIndex:idx];
            }
            
            BakerIssue *issue = (BakerIssue*)object;
            if (!existingIvc || ![[existingIvc issue].ID isEqualToString:issue.ID]) {
                IssueViewController *ivc = [self createIssueViewControllerWithIssue:issue];
                [self.issueViewControllers insertObject:ivc atIndex:idx];
                [self.carousel reloadData];
            } else {
                existingIvc.issue = issue;
                [existingIvc refreshContentWithCache:NO];
            }
        }];
        
        [purchasesManager retrievePricesFor:issuesManager.productIDs andEnableFailureNotifications:NO];
    }
    else{
        [Utils showAlertWithTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_TITLE", nil)
                          message:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_MESSAGE", nil)
                      buttonTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_CLOSE", nil)];
    }
    [self setrefreshButtonEnabled:YES];
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.viewActivityIndicatorView.hidden = YES;
        [self.largeActivity stopAnimating];
    });
    
}

#pragma mark iCarouselDelegate

-(void)handleSetUp:(id)sender
{
    [self.pop presentPopoverFromRect:CGRectMake(self.sysTemButton.frame.origin.x, self.sysTemButton.frame.origin.y+10, 200, 100) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    
}

-(void)handleShare:(id)sender
{
    [self.editActionSheet showInView:self.view];
}

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return [issueViewControllers count];
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
    //note: placeholder views are only displayed on some carousels if wrapping is disabled
    return 2;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    IssueViewController *issueViewController = [self.issueViewControllers objectAtIndex:index];
    view = issueViewController.view;
    return view;
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    //customize carousel display
    switch (option)
    {
        case iCarouselOptionWrap:
        {
            //normally you would hard-code this to YES or NO
            return _wrap;
        }
        case iCarouselOptionSpacing:
        {
            //add a bit of spacing between the item views
            return value * 1.05f;
        }
        case iCarouselOptionFadeMax:
        {
            if (carousel.type == iCarouselTypeCustom)
            {
                //set opacity based on distance from camera
                return 0.0f;
            }
            return value;
        }
        default:
        {
            return value;
        }
    }
}

#pragma mark - Store Kit

- (void)handleSubscribeButtonPressed:(NSNotification *)notification {
    if (subscriptionsActionSheet.visible) {
        [subscriptionsActionSheet dismissWithClickedButtonIndex:(subscriptionsActionSheet.numberOfButtons - 1) animated:YES];
    } else {
        self.subscriptionsActionSheet = [self buildSubscriptionsActionSheet];
        [subscriptionsActionSheet showFromBarButtonItem:self.subscribeButton animated:YES];
    }
}

- (UIActionSheet *)buildSubscriptionsActionSheet {
    NSString *title;
    if ([api canGetPurchasesJSON]) {
        if (purchasesManager.subscribed) {
            title = NSLocalizedString(@"SUBSCRIPTIONS_SHEET_SUBSCRIBED", nil);
        } else {
            title = NSLocalizedString(@"SUBSCRIPTIONS_SHEET_NOT_SUBSCRIBED", nil);
        }
    } else {
        title = NSLocalizedString(@"SUBSCRIPTIONS_SHEET_GENERIC", nil);
    }
    
    UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:title
                                                      delegate:self
                                             cancelButtonTitle:nil
                                        destructiveButtonTitle:nil
                                             otherButtonTitles: nil];
    NSMutableArray *actions = [NSMutableArray array];
    
    if (!purchasesManager.subscribed) {
        if ([FREE_SUBSCRIPTION_PRODUCT_ID length] > 0 && ![purchasesManager isPurchased:FREE_SUBSCRIPTION_PRODUCT_ID]) {
            [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_FREE", nil)];
            [actions addObject:FREE_SUBSCRIPTION_PRODUCT_ID];
        }
        
        for (NSString *productId in AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS) {
            NSString *title = NSLocalizedString(productId, nil);
            NSString *price = [purchasesManager priceFor:productId];
            if (price) {
                [sheet addButtonWithTitle:[NSString stringWithFormat:@"%@ %@", title, price]];
                [actions addObject:productId];
            }
        }
    }
    
    if ([issuesManager hasProductIDs]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_RESTORE", nil)];
        [actions addObject:@"restore"];
    }
    
    [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_CLOSE", nil)];
    [actions addObject:@"cancel"];
    
    self.subscriptionsActionSheetActions = actions;
    
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    return sheet;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == subscriptionsActionSheet) {
        NSString *action = [self.subscriptionsActionSheetActions objectAtIndex:buttonIndex];
        if ([action isEqualToString:@"cancel"]) {
            NSLog(@"Action sheet: cancel");
            [self setSubscribeButtonEnabled:YES];
        } else if ([action isEqualToString:@"restore"]) {
            [self.blockingProgressView show];
            [purchasesManager restore];
            NSLog(@"Action sheet: restore");
        } else {
            NSLog(@"Action sheet: %@", action);
            [self setSubscribeButtonEnabled:NO];
            if (![purchasesManager purchase:action]){
                [Utils showAlertWithTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_TITLE", nil)
                                  message:nil
                              buttonTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_CLOSE", nil)];
                [self setSubscribeButtonEnabled:YES];
            }
        }
    }
    else if (actionSheet == self.editActionSheet)
    {
        
        if (buttonIndex == actionSheet.cancelButtonIndex) {
            return;
        }
        UMSocialControllerService *  socialControllerService = [UMSocialControllerService defaultControllerService];
        
        if(buttonIndex == 0|| buttonIndex == 1)
        {
            if ([WXApi isWXAppInstalled] && [WXApi isWXAppSupportApi])
            {
                if (socialControllerService.currentNavigationController != nil) {
                    [socialControllerService performSelector:@selector(close)];
                }
                
                SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
                
                WXMediaMessage *message = [WXMediaMessage message];
                
                //分享的是图片
                if (socialControllerService.socialData.urlResource)
                {
                    UMSocialUrlResource *urlresource = socialControllerService.socialData.urlResource;
                    
                    NSData *dataImage = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlresource.url]];
                    
                    message.thumbData = dataImage;
                }
                
                //分享的文字
                if (socialControllerService.socialData.shareText)
                {
                    message.description = socialControllerService.socialData.shareText;
                }
                
                //分享url
                if (UMShareHylink)
                {
                    WXWebpageObject *ext = [WXWebpageObject object];
                    
                    ext.webpageUrl = UMShareHylink;
                    
                    message.mediaObject = ext;
                }
                
                NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                
                NSString *strTitle = [infoDict objectForKey:@"CFBundleDisplayName"];
                
                message.title = [NSString stringWithFormat:@"来自于[%@]应用",strTitle];
                
                req.message = message;
                
                req.bText = NO;
                
                
                if (buttonIndex == 0) {
                    
                    req.scene = WXSceneSession;
                    
                    //                _socialControllerService = [UMSocialControllerService defaultControllerService];
                    
                    [ socialControllerService.socialDataService postSNSWithTypes:[NSArray arrayWithObject:UMShareToWechatSession] content:req.text image:nil location:nil urlResource:nil completion:nil];
                }
                if (buttonIndex == 1) {
                    //                _socialControllerService = [UMSocialControllerService defaultControllerService];
                    req.scene = WXSceneTimeline;
                    [socialControllerService.socialDataService postSNSWithTypes:[NSArray arrayWithObject:UMShareToWechatTimeline] content:req.text image:nil location:nil urlResource:nil completion:nil];
                }
                [WXApi sendReq:req];
                
            }
            else{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您的设备没有安装微信" delegate:nil cancelButtonTitle:@"好" otherButtonTitles: nil];
                [alertView show];
            }
        }
        else
        {
            NSString *snsName = [self.arrayPlatForm objectAtIndex:buttonIndex-2];
            
            UMSocialSnsPlatform *snsPlatForm = [UMSocialSnsPlatformManager getSocialPlatformWithName:snsName];
            
            snsPlatForm.snsClickHandler(self,socialControllerService,YES);
            
        }
    }
}

- (void)handleRestoreFailed:(NSNotification *)notification {
    NSError *error = [notification.userInfo objectForKey:@"error"];
    [Utils showAlertWithTitle:NSLocalizedString(@"RESTORE_FAILED_TITLE", nil)
                      message:[error localizedDescription]
                  buttonTitle:NSLocalizedString(@"RESTORE_FAILED_CLOSE", nil)];
    
    [self.blockingProgressView dismissWithClickedButtonIndex:0 animated:YES];
    
}

- (void)handleMultipleRestores:(NSNotification *)notification {
#ifdef BAKER_NEWSSTAND
    if ([notRecognisedTransactions count] > 0) {
        NSSet *productIDs = [NSSet setWithArray:[[notRecognisedTransactions valueForKey:@"payment"] valueForKey:@"productIdentifier"]];
        NSString *productsList = [[productIDs allObjects] componentsJoinedByString:@", "];
        
        [Utils showAlertWithTitle:NSLocalizedString(@"RESTORED_ISSUE_NOT_RECOGNISED_TITLE", nil)
                          message:[NSString stringWithFormat:NSLocalizedString(@"RESTORED_ISSUE_NOT_RECOGNISED_MESSAGE", nil), productsList]
                      buttonTitle:NSLocalizedString(@"RESTORED_ISSUE_NOT_RECOGNISED_CLOSE", nil)];
        
        for (SKPaymentTransaction *transaction in notRecognisedTransactions) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
        [notRecognisedTransactions removeAllObjects];
    }
#endif
    
    [self handleRefresh:nil];
    [self.blockingProgressView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)handleRestoredIssueNotRecognised:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];
    [notRecognisedTransactions addObject:transaction];
}

// TODO: this can probably be removed
- (void)handleSubscription:(NSNotification *)notification {
    [self setSubscribeButtonEnabled:NO];
    [purchasesManager purchase:FREE_SUBSCRIPTION_PRODUCT_ID];
}

- (void)handleSubscriptionPurchased:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];
    
    [purchasesManager markAsPurchased:transaction.payment.productIdentifier];
    [self setSubscribeButtonEnabled:YES];
    
    if ([purchasesManager finishTransaction:transaction]) {
        if (!purchasesManager.subscribed) {
            [Utils showAlertWithTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_TITLE", nil)
                              message:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_MESSAGE", nil)
                          buttonTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_CLOSE", nil)];
            
            [self handleRefresh:nil];
        }
    } else {
        [Utils showAlertWithTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_TITLE", nil)
                          message:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_MESSAGE", nil)
                      buttonTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_CLOSE", nil)];
    }
}

- (void)handleSubscriptionFailed:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];
    
    // Show an error, unless it was the user who cancelled the transaction
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [Utils showAlertWithTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_TITLE", nil)
                          message:[transaction.error localizedDescription]
                      buttonTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_CLOSE", nil)];
    }
    
    [self setSubscribeButtonEnabled:YES];
}

- (void)handleSubscriptionRestored:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];
    
    [purchasesManager markAsPurchased:transaction.payment.productIdentifier];
    
    if (![purchasesManager finishTransaction:transaction]) {
        NSLog(@"Could not confirm purchase restore with remote server for %@", transaction.payment.productIdentifier);
    }
}

- (void)handleProductsRetrieved:(NSNotification *)notification {
    NSSet *ids = [notification.userInfo objectForKey:@"ids"];
    BOOL issuesRetrieved = NO;
    
    for (NSString *productId in ids) {
        if ([productId isEqualToString:FREE_SUBSCRIPTION_PRODUCT_ID]) {
            // ID is for a free subscription
            [self setSubscribeButtonEnabled:YES];
        } else if ([AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS containsObject:productId]) {
            // ID is for an auto-renewable subscription
            [self setSubscribeButtonEnabled:YES];
        } else {
            // ID is for an issue
            issuesRetrieved = YES;
        }
    }
    
    if (issuesRetrieved) {
        NSString *price;
        for (IssueViewController *controller in self.issueViewControllers) {
            price = [purchasesManager priceFor:controller.issue.productID];
            if (price) {
                [controller setPrice:price];
                [shelfStatus setPrice:price for:controller.issue.productID];
            }
        }
        [shelfStatus save];
    }
}

- (void)handleProductsRequestFailed:(NSNotification *)notification {
    NSError *error = [notification.userInfo objectForKey:@"error"];
    
    [Utils showAlertWithTitle:NSLocalizedString(@"PRODUCTS_REQUEST_FAILED_TITLE", nil)
                      message:[error localizedDescription]
                  buttonTitle:NSLocalizedString(@"PRODUCTS_REQUEST_FAILED_CLOSE", nil)];
}

#endif

#pragma mark - Navigation management

- (void)gridView:(AQGridView *)myGridView didSelectItemAtIndex:(NSUInteger)index
{
    [myGridView deselectItemAtIndex:index animated:NO];
}
- (void)readIssue:(BakerIssue *)issue
{
    BakerBook *book = nil;
    NSString *status = [issue getStatus];
    
#ifdef BAKER_NEWSSTAND
    if ([status isEqual:@"opening"]) {
        book = [[[BakerBook alloc] initWithBookPath:issue.path bundled:NO] autorelease];
        if (book) {
            [self pushViewControllerWithBook:book];
        } else {
            NSLog(@"[ERROR] Book %@ could not be initialized", issue.ID);
            issue.transientStatus = BakerIssueTransientStatusNone;
            // Let's refresh everything as it's easier. This is an edge case anyway ;)
            for (IssueViewController *controller in issueViewControllers) {
                [controller refresh];
            }
            [Utils showAlertWithTitle:NSLocalizedString(@"ISSUE_OPENING_FAILED_TITLE", nil)
                              message:NSLocalizedString(@"ISSUE_OPENING_FAILED_MESSAGE", nil)
                          buttonTitle:NSLocalizedString(@"ISSUE_OPENING_FAILED_CLOSE", nil)];
        }
    }
#else
    if ([status isEqual:@"bundled"]) {
        book = [issue bakerBook];
        [self pushViewControllerWithBook:book];
    }
#endif
}
- (void)handleReadIssue:(NSNotification *)notification
{
    IssueViewController *controller = notification.object;
    [self readIssue:controller.issue];
}
- (void)receiveBookProtocolNotification:(NSNotification *)notification
{
    self.bookToBeProcessed = [notification.userInfo objectForKey:@"ID"];
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (void)handleBookToBeProcessed
{
    for (IssueViewController *issueViewController in self.issueViewControllers) {
        if ([issueViewController.issue.ID isEqualToString:self.bookToBeProcessed]) {
            [issueViewController actionButtonPressed:nil];
            break;
        }
    }
    
    self.bookToBeProcessed = nil;
}
- (void)pushViewControllerWithBook:(BakerBook *)book
{
    BakerViewController *bakerViewController = [[BakerViewController alloc] initWithBook:book];
    [self.navigationController pushViewController:bakerViewController animated:YES];
    [bakerViewController release];
}

#pragma mark - Buttons management

-(void)setrefreshButtonEnabled:(BOOL)enabled {
    self.refreshButton.enabled = enabled;
}

-(void)setSubscribeButtonEnabled:(BOOL)enabled {
    self.subscribeButton.enabled = enabled;
    if (enabled) {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil);
    } else {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_DISABLED_TEXT", nil);
    }
}

#pragma mark - Helper methods

- (void)addPurchaseObserver:(SEL)notificationSelector name:(NSString *)notificationName {
#ifdef BAKER_NEWSSTAND
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:notificationSelector
                                                 name:notificationName
                                               object:purchasesManager];
#endif
}

+ (int)getBannerHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 240;
    } else {
        return 104;
    }
}


-(void)setupViewController:(SetUpViewController*)setupViewController didSelectSetUpRow:(NSInteger)terger
{
    [self.pop dismissPopoverAnimated:NO];
    WebViewController *webController = [[WebViewController alloc]init];
    [webController setURL:[NSURL URLWithString:@"http://www.xayoudao.com/qujianglvyou/"]];
//    [self.navigationController presentModalViewController:webController animated:YES];
    [self.navigationController pushViewController:webController animated:YES];
}

@end
