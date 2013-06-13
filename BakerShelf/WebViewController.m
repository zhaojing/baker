//
//  WebViewController.m
//  Baker
//
//  Created by jing zhao on 6/13/13.
//
//

#import "WebViewController.h"

@interface WebViewController ()
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSURL *m_url;
@end

@implementation WebViewController

- (void) setURL:(NSURL *)url
{
    self.m_url = url;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = NO;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc]initWithFrame:CGRectMake(0, 0, 1024, 768)];
    
    [self.view addSubview:self.webView];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.m_url]];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
