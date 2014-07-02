//
//  QUEInformationViewController.m
//  QUe
//
/*
 Copyright 2014 Quality and Usability Lab, Telekom Innvation Laboratories, TU Berlin.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


#import "QUEInformationViewController.h"

@implementation QUEInformationViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSURL *url = [NSURL URLWithString:QUEInformationURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UIWebView delegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                            message:error.localizedDescription
                      dismissButton:NSLocalizedString(@"OK", nil)];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSURL *url = [request URL];
        
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"AlertTitleOpenExternalLink", nil)
                                message:[NSString stringWithFormat:NSLocalizedString(@"%@ will be opened in Mobile Safari", @"{Link} will be opened in Mobile Safari."), url]
                           cancelButton:NSLocalizedString(@"Cancel", nil)
                           otherButtons:@[NSLocalizedString(@"OK", nil)]
                          buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                              if (buttonIndex != alert.cancelButtonIndex) {
                                  [[UIApplication sharedApplication] openURL:url];
                              }
                          }];

        return NO;
    }
    
    return YES;
}

@end
