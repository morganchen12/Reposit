//
//  RepoDetailViewController.m
//  Reposit
//
//  Created by Morgan Chen on 1/3/15.
//  Copyright (c) 2015 Morgan Chen. All rights reserved.
//

#import "RepoDetailViewController.h"
#import "Repository.h"

@interface RepoDetailViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;

@end

@implementation RepoDetailViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;
    
    NSString *repoName;
    if (self.repository) {
        repoName = [NSString stringWithFormat:@"%@/%@", self.repository.owner, self.repository.name];
        NSString *urlString = [NSString stringWithFormat:@"https://github.com/%@", repoName];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:urlRequest];
    }
    else {
        NSLog(@"No repo specified to load!");
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.webView stopLoading];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.activityIndicator stopAnimating];
    
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // alert
}

#pragma mark - Interface Builder outlets

- (IBAction)backButtonPressed:(id)sender {
    [self.webView goBack];
}

- (IBAction)forwardButtonPressed:(id)sender {
    [self.webView goForward];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
