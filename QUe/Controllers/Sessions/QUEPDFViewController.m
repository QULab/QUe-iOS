//
//  QUEPDFViewController.h
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


#import "QUEPDFViewController.h"

@interface QUEPDFViewController ()

@property (nonatomic, strong) AFHTTPClient *httpClient;

@end

@implementation QUEPDFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *path = [NSString stringWithFormat:@"papers/%@/download", self.paper.paperId];
    NSString *apiKey = [defaults objectForKey:@"apiKey"];
    
    self.httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:QUEServerURL]];
    self.httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [self.httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"GET"
                                                                 path:path
                                                           parameters:@{@"api_key":apiKey}];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation,
                                               id responseObject) {
        [self.pdfWebView loadData:(NSData *)responseObject
                         MIMEType:@"application/pdf"
                 textEncodingName:@"utf-8"
                          baseURL:nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                message:error.localizedDescription
                          dismissButton:NSLocalizedString(@"OK", nil)];
    }];
    
    [operation start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)sendPDF:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *apiKey = [defaults objectForKey:@"apiKey"];
    NSString *path = [NSString stringWithFormat: @"papers/%@/send_mail",self.paper.paperId];
    
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST"
                                                                 path:path
                                                           parameters:@{@"api_key":apiKey}];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request,
                                                                                                  NSHTTPURLResponse *responseObject,
                                                                                                  id JSON) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Success", nil)
                                message:NSLocalizedString(@"AlertMessagePaperSentPerMail", nil)
                          dismissButton:NSLocalizedString(@"OK", nil)];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *responseObject,
                NSError *error,
                id JSON) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                message:error.localizedDescription
                          dismissButton:NSLocalizedString(@"OK", nil)];
    }];
    
    [operation start];
}

@end
