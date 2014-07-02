//
//  QUEPaperViewController.m
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


#import "QUEPaperViewController.h"

#import <EventKit/EventKit.h>
#import "QUEPDFViewController.h"

#pragma mark - NSString Addition

@interface NSString (NSStringAdditionsHTML)

- (NSString *)stringByDecodingXMLEntities;

@end

@implementation NSString (NSStringAdditionsHTML)

- (NSString *)stringByDecodingXMLEntities {
    NSUInteger myLength = [self length];
    NSUInteger ampIndex = [self rangeOfString:@"&" options:NSLiteralSearch].location;
    
    // Short-circuit if there are no ampersands.
    if (ampIndex == NSNotFound) {
        return self;
    }
    // Make result string with some extra capacity.
    NSMutableString *result = [NSMutableString stringWithCapacity:(myLength * 1.25)];
    
    // First iteration doesn't need to scan to & since we did that already, but for code simplicity's sake we'll do it again with the scanner.
    NSScanner *scanner = [NSScanner scannerWithString:self];
    
    [scanner setCharactersToBeSkipped:nil];
    
    NSCharacterSet *boundaryCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r;"];
    
    do {
        // Scan up to the next entity or the end of the string.
        NSString *nonEntityString;
        if ([scanner scanUpToString:@"&" intoString:&nonEntityString]) {
            [result appendString:nonEntityString];
        }
        if ([scanner isAtEnd]) {
            goto finish;
        }
        // Scan either a HTML or numeric character entity reference.
        if ([scanner scanString:@"&amp;" intoString:NULL])
            [result appendString:@"&"];
        else if ([scanner scanString:@"&apos;" intoString:NULL])
            [result appendString:@"'"];
        else if ([scanner scanString:@"&quot;" intoString:NULL])
            [result appendString:@"\""];
        else if ([scanner scanString:@"&lt;" intoString:NULL])
            [result appendString:@"<"];
        else if ([scanner scanString:@"&gt;" intoString:NULL])
            [result appendString:@">"];
        else if ([scanner scanString:@"&#" intoString:NULL]) {
            BOOL gotNumber;
            unsigned charCode;
            NSString *xForHex = @"";
            
            // Is it hex or decimal?
            if ([scanner scanString:@"x" intoString:&xForHex]) {
                gotNumber = [scanner scanHexInt:&charCode];
            }
            else {
                gotNumber = [scanner scanInt:(int*)&charCode];
            }
            
            if (gotNumber) {
                [result appendFormat:@"%C", (unichar)charCode];
                
                [scanner scanString:@";" intoString:NULL];
            }
            else {
                NSString *unknownEntity = @"";
                
                [scanner scanUpToCharactersFromSet:boundaryCharacterSet intoString:&unknownEntity];
                
                
                [result appendFormat:@"&#%@%@", xForHex, unknownEntity];
                
                //[scanner scanUpToString:@";" intoString:&unknownEntity];
                //[result appendFormat:@"&#%@%@;", xForHex, unknownEntity];
                NSLog(@"Expected numeric character entity but got &#%@%@;", xForHex, unknownEntity);
                
            }
            
        }
        else {
            NSString *amp;
            
            [scanner scanString:@"&" intoString:&amp];  //an isolated & symbol
            [result appendString:amp];
            
            /*
             NSString *unknownEntity = @"";
             [scanner scanUpToString:@";" intoString:&unknownEntity];
             NSString *semicolon = @"";
             [scanner scanString:@";" intoString:&semicolon];
             [result appendFormat:@"%@%@", unknownEntity, semicolon];
             NSLog(@"Unsupported XML character entity %@%@", unknownEntity, semicolon);
             */
        }
        
    }
    while (![scanner isAtEnd]);
    
finish:
    return result;
}

@end

#pragma mark - QUEPaperViewController

@interface QUEPaperViewController () <AVSpeechSynthesizerDelegate> {
    NSDictionary *abstractTextAttributes;
}

@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) AVSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, assign) NSInteger taskInterruptedByAuthentication;

@end

@implementation QUEPaperViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    abstractTextAttributes = [[NSDictionary alloc] initWithObjects:@[[UIFont fontWithName:@"Helvetica Neue"
                                                                                     size:13.0f],
                                                                     [UIColor darkGrayColor]]
                                                           forKeys:@[NSFontAttributeName,
                                                                     NSForegroundColorAttributeName]];
    
    self.taskInterruptedByAuthentication = -1;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self setup];
    
    [self update];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.speechSynthesizer) {
        [self.speechSynthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"displayPDF"]) {
        QUEPDFViewController *pdfViewController = segue.destinationViewController;
        pdfViewController.paper = self.paper;
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"displayPDF"]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        NSDate *conferenceStart = [dateFormatter dateFromString:QUEPaperDownloadAvailableDate];
        
        if ([conferenceStart compare:[NSDate date]] == NSOrderedDescending) {
            [OHAlertView showAlertWithTitle:NSLocalizedString(@"AlertTitlePaperDownloadNotAvailableYet", nil)
                                    message:NSLocalizedString(@"AlertMessagePaperDownloadNotAvailableYet", nil)
                              dismissButton:NSLocalizedString(@"OK", nil)];
            
            return NO;
        }
    }
    
    return YES;
}

- (void)update {
    NSString *path = [NSString stringWithFormat:@"papers/%@",self.paper.paperId];
    [[RKObjectManager sharedManager] getObjectsAtPath:path
                                           parameters:nil
                                              success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                  [self setup];
                                              } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                  RKLogError(@"Failed to load sessions: %@",error.localizedDescription);
                                              }];
}

- (void)setup {
    // paper title
    self.paperTitle.text = self.paper.title;
    
    // authors
    NSMutableString *authorList = [NSMutableString string];
    [self.paper.authors enumerateObjectsUsingBlock:^(Author *author, NSUInteger idx, BOOL *stop) {
        if (idx > 0)
            [authorList appendString:@", "];
        
        [authorList appendFormat:@"%@ %@", author.firstName, author.lastName];
        
    }];
    self.author.text = authorList;

    // abstract
    if (self.paper.abstract) {
        self.paperAbstract.attributedText = [[NSAttributedString alloc] initWithString:[self.paper.abstract stringByDecodingXMLEntities]
                                                                            attributes:abstractTextAttributes];
        
    }
    
    // time
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if ([[[NSLocale currentLocale] localeIdentifier] isEqualToString:@"de_DE"]) {
        // use German format
        dateFormatter.locale = [NSLocale currentLocale];
        dateFormatter.dateFormat = @"HH:mm";
    }
    else {
        // use en_US format
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        dateFormatter.dateFormat = @"h:mm a";
    }
    
    NSString *start = [dateFormatter stringFromDate:self.paper.presentationStart];
    NSString *end = [dateFormatter stringFromDate:self.paper.presentationEnd];
    
    dateFormatter.dateFormat = @"EEEE";
    NSString *day = [dateFormatter stringFromDate:self.paper.presentationStart];
    
    self.timeLabel.text = [NSString stringWithFormat:@"%@, %@ - %@",day,start,end];
    
    if ([[[NSLocale currentLocale] localeIdentifier] isEqualToString:@"de_DE"]) {
        self.timeLabel.text = [self.timeLabel.text stringByAppendingString:@" Uhr"];
    }
    
    // room
    self.roomLabel.text = self.paper.session.room;
    
    // favorite
    self.favoriteImageView.hidden = !self.paper.favorite;
}

#pragma mark - Actions

- (IBAction)didSelectActionButton:(id)sender {
    
    NSMutableArray *actions = [NSMutableArray array];
    NSMutableArray *selectors = [NSMutableArray array];

    // calendar
    NSString *calendarAddRemove = [NSString stringWithFormat:@"\U00002B50 %@", self.paper.favorite ? NSLocalizedString(@"RemoveFromFavorites", nil) : NSLocalizedString(@"AddToFavorites", nil)];
    [actions addObject:calendarAddRemove];
    [selectors addObject:@"addRemoveFavorite"];
        
    // read abstract
    if (([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)) {
        NSString *startPauseContinue = @"\U0001F509 ";
        if (self.speechSynthesizer) {
            BOOL isPaused = [self.speechSynthesizer isPaused];
            if (isPaused) {
                startPauseContinue = [startPauseContinue stringByAppendingString:NSLocalizedString(@"ContinueReadingAbstract", nil)];
            }
            else {
                startPauseContinue = [startPauseContinue stringByAppendingString:NSLocalizedString(@"PauseReadingAbstract", nil)];
            }
        }
        else {
            startPauseContinue = [startPauseContinue stringByAppendingString:NSLocalizedString(@"StartReadingAbstract", nil)];
        }
        
        [actions addObject:startPauseContinue];
        [selectors addObject:@"startPauseContinueReadingAbstract"];
    }
    
    // pdf
    if (self.paper.file) {
        [actions addObject:[NSString stringWithFormat:@"\U0001F50E %@",NSLocalizedString(@"ViewPDF", nil)]];
        [selectors addObject:@"downloadPDF"];
    }
    
    [OHActionSheet showSheetInView:self.tabBarController.view
                             title:nil
                 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
            destructiveButtonTitle:nil
                 otherButtonTitles:actions
                        completion:^(OHActionSheet *sheet, NSInteger buttonIndex)
     {
         if (buttonIndex != sheet.cancelButtonIndex) {
             // workaround for a compiler warning when calling [self performSelector:selector] with unkown selector
             // see: http://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
             SEL selector = NSSelectorFromString([selectors objectAtIndex:buttonIndex]);
             IMP imp = [self methodForSelector:selector];
             void (*func)(id, SEL) = (void *)imp;
             func(self, selector);
         }
     }];
}

- (void)downloadPDF {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"apiKey"] != nil) {
        if ([self shouldPerformSegueWithIdentifier:@"displayPDF" sender:self])
            [self performSegueWithIdentifier:@"displayPDF" sender:self];
    }
    else {
        self.taskInterruptedByAuthentication = QUETaskInterruptedByAuthenticationDisplayPDF;
        [self chooseAuthorization];
    }
}

- (void)startPauseContinueReadingAbstract {
    // only availabe on iOS7+
    if ([AVSpeechUtterance class]) {
        if (self.speechSynthesizer) {
            if (![self.speechSynthesizer isPaused]) {
                [self.speechSynthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            }
            else {
                [self.speechSynthesizer continueSpeaking];
            }
        }
        else {
            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:self.paper.abstract];
            utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"];
            utterance.rate = 0.2;
            
            self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
            self.speechSynthesizer.delegate = self;
            [self.speechSynthesizer speakUtterance:utterance];
        }
    }
}

#pragma mark - Authorization

- (void)chooseAuthorization {
    [OHAlertView showAlertWithTitle:NSLocalizedString(@"AlertTitleChooseAuthenticationMethod", nil)
                            message:NSLocalizedString(@"AlertMessageChooseAuthenticationMethod", nil)
                       cancelButton:NSLocalizedString(@"Cancel", nil)
                       otherButtons:@[NSLocalizedString(@"AlertOptionAuthenticationRegisteredAttendee", nil),
                                      NSLocalizedString(@"AlertOptionAuthenticationPaperPassword", nil)]
                      buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                          if (buttonIndex == alert.cancelButtonIndex) {
                              return;
                          }
                          else if (buttonIndex == 1) {
                              [self requestPaswordForEmail];
                          } else if (buttonIndex == 2) {
                              [self authorizeWithPaperPassword];
                          }
                      }];
}

- (void)authorizeWithPaperPassword {
    [OHAlertView showEmailAndPasswordAlertWithTitle:NSLocalizedString(@"AlertTitleAuthenticationPaperPassword", nil)
                                            message:NSLocalizedString(@"AlertMessageAuthenticationPaperPassword", nil)
                                       cancelButton:NSLocalizedString(@"Cancel", nil)
                                       otherButtons:@[NSLocalizedString(@"Submit", nil)]
                                      buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                                          if (buttonIndex == alert.cancelButtonIndex) {
                                              return;
                                          }
                                          else {
                                              UITextField *emailField = [alert textFieldAtIndex:0];
                                              UITextField *passwordField = [alert textFieldAtIndex:1];
                                              
                                              [self checkPaperPassword:passwordField.text
                                                             withEmail:emailField.text];
                                          }
                                      }];
}

- (void)authorizeAsRegisteredUser:(NSString *)email  {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userMail = email;
    [defaults setObject:userMail forKey:@"userMail"];
    [defaults synchronize];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:QUEServerURL]];
    [httpClient setParameterEncoding:AFFormURLParameterEncoding];
    
    NSString *systemVersion = [NSString stringWithFormat: @"iOS%@", [[UIDevice currentDevice] systemVersion]];
    NSString *phoneModel = [[UIDevice currentDevice] model];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                                            path:@"register/user"
                                                      parameters:@{@"email":email,
                                                                   @"os":systemVersion,
                                                                   @"device":phoneModel}];
    
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request,
                                                                                                  NSHTTPURLResponse *responseObject,
                                                                                                  id JSON) {
        NSUInteger userId = [[JSON objectForKey:@"user_id"] integerValue];
        NSUInteger keyId = [[JSON objectForKey:@"key_id"] integerValue];
        
        [defaults setInteger:userId forKey:@"userId"];
        [defaults setInteger:keyId forKey:@"keyId"];
        [defaults synchronize];
        
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"AlertTitleAuthenticationMailedPassword", nil)
                                message:NSLocalizedString(@"AlertMessageAuthenticationMailedPassword", nil)
                             alertStyle:UIAlertViewStyleSecureTextInput
                           cancelButton:NSLocalizedString(@"Cancel", nil)
                           otherButtons:@[NSLocalizedString(@"OK", nil)]
                          buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                              if (buttonIndex == alert.cancelButtonIndex) {
                                  return;
                              }
                              else {
                                  UITextField *passwordField = [alert textFieldAtIndex:0];
                                  [self checkMailPassword:passwordField.text];
                              }
                          }];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *responseObject, NSError *error, id JSON) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                message:error.localizedDescription
                           cancelButton:NSLocalizedString(@"OK", nil)
                           otherButtons:nil
                          buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                              [self requestPaswordForEmail];
                          }];
    }];
    [operation start];
    
}


- (void)requestPaswordForEmail {
    OHAlertView *alertView = [[OHAlertView alloc] initWithTitle:NSLocalizedString(@"AlertTitleAuthenticationEmail", nil)
                                                        message:NSLocalizedString(@"AlertMessageAuthenticationEmail", nil)
                                                   cancelButton:NSLocalizedString(@"Cancel", nil)
                                                   otherButtons:@[NSLocalizedString(@"Submit", nil)]
                                                  buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                                                      if (buttonIndex == alert.cancelButtonIndex) {
                                                          return;
                                                      }
                                                      else {
                                                          UITextField *emailField = [alert textFieldAtIndex:0];
                                                          
                                                          [self authorizeAsRegisteredUser:emailField.text];
                                                      }
                                                  }];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alertView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeEmailAddress];
    
    [alertView show];
}

- (void)checkMailPassword:(NSString *)password {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger keyID = [defaults integerForKey:@"keyId"];
    NSString *path = [NSString stringWithFormat:@"unlock/key/%ld", (long)keyID];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:QUEServerURL]];
    [httpClient setParameterEncoding:AFFormURLParameterEncoding];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                                            path:path
                                                      parameters:@{@"password":password}];
    
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *responseObject, id JSON) {
        NSString *apiKey = [JSON objectForKey:@"api_key"];
        
        [defaults setObject:apiKey forKey:@"apiKey"];
        [defaults synchronize];
        
        [self proceedInterruptedTask];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *responseObject, NSError *error, id JSON) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                message:error.localizedDescription
                           cancelButton:NSLocalizedString(@"OK", nil)
                           otherButtons:nil
                          buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                              NSString *userMail = [defaults objectForKey:@"userMail"];
                              [self authorizeAsRegisteredUser:userMail];
                          }];
    }];
    [operation start];

}

- (void)checkPaperPassword:(NSString *)password withEmail:(NSString *)email {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:QUEServerURL]];
    httpClient.parameterEncoding = AFFormURLParameterEncoding;
    [httpClient registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    
    NSString *systemVersion = [NSString stringWithFormat:@"iOS%@", [[UIDevice currentDevice] systemVersion]];
    NSString *phoneModel = [[UIDevice currentDevice] model];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                                            path:@"register/attendee"
                                                      parameters:@{@"password":password,
                                                                   @"email":email,
                                                                   @"os":systemVersion,
                                                                   @"device":phoneModel}];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request,
                                                                                                  NSHTTPURLResponse *responseObject,
                                                                                                  id JSON) {
        NSString *apiKey = [JSON objectForKey:@"api_key"];
        NSUInteger userId = [[JSON objectForKey:@"user_id"] integerValue];
        
        [defaults setInteger:userId forKey:@"userId"];
        [defaults setObject:apiKey forKey:@"apiKey"];
        [defaults synchronize];
        
        [self proceedInterruptedTask];
    } failure:^(NSURLRequest *request,
                NSHTTPURLResponse *responseObject,
                NSError *error,
                id JSON) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                message:error.localizedDescription
                           cancelButton:NSLocalizedString(@"OK", nil)
                           otherButtons:nil
                          buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                              [self authorizeWithPaperPassword];
                          }];
    }];
    
    [operation start];
}

- (void)proceedInterruptedTask {
    if (self.taskInterruptedByAuthentication == -1) {
        return;
    }
    
    if (self.taskInterruptedByAuthentication == QUETaskInterruptedByAuthenticationDisplayPDF) {
        if ([self shouldPerformSegueWithIdentifier:@"displayPDF" sender:self]) {
            [self performSegueWithIdentifier:@"displayPDF" sender:self];
        }
    }
//    else if (self.taskInterruptedByAuthentication == QUETaskInterruptedByAuthenticationAddToCalendar) {
//        [self addToCalendar:nil];
//    }
    
    self.taskInterruptedByAuthentication = -1;
}

#pragma mark - EventKit

//- (BOOL)isSubscribedToCalendar {
//    
//    if ([self accessToEventStoreGranted]) {
//        for (EKSource *source in self.eventStore.sources) {
//            NSSet *calendars = [source calendarsForEntityType:EKEntityTypeEvent];
//            
//            if ([calendars count] > 0) {
//                NSArray *calendarArray = [calendars allObjects];
//                for (EKCalendar *calendar in calendarArray) {
//                    if ([calendar.title rangeOfString:[[NSURL URLWithString:kServerURL] path]].location != NSNotFound) {
//                        return YES;
//                    }
//                }
//            }
//        }
//    }
//    
//    return NO;
//}

- (void)addRemoveFavorite {
    self.paper.favorite = !self.paper.favorite;
    self.favoriteImageView.hidden = !self.paper.favorite;
    
    NSError *error;
    BOOL didSave = [[RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    if (!didSave) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                message:error.localizedDescription
                          dismissButton:NSLocalizedString(@"OK", nil)];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:QUEExportEventFavoritesToCalendar]) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"AlertTitleExportEventFavoritesToCalendar",nil)
                                message:NSLocalizedString(@"AlertMessageExportEventFavoritesToCalendar", nil)
                           cancelButton:NSLocalizedString(@"NO", nil)
                               okButton:NSLocalizedString(@"YES", nil)
                          buttonHandler:^(OHAlertView *alert, NSInteger buttonIndex) {
                              if (buttonIndex == alert.cancelButtonIndex) {
                                  [defaults setBool:NO forKey:QUEExportEventFavoritesToCalendar];
                              } else {
                                  [defaults setBool:YES forKey:QUEExportEventFavoritesToCalendar];
                                  [self addRemoveCalendarEvent];
                              }
                              [defaults synchronize];
                          }];
    }
    else if ([defaults boolForKey:QUEExportEventFavoritesToCalendar]) {
        [self addRemoveCalendarEvent];
    }
}

- (BOOL)accessToEventStoreGranted {
    
    __block BOOL accessGranted = NO;
    
    self.eventStore = [[EKEventStore alloc] init];
    
    if([self.eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else {
        // we're on iOS 5 or older
        accessGranted = YES;
    }
    
    return accessGranted;
}

- (void)addRemoveCalendarEvent {
    BOOL accessToEventStoreGranted = [self accessToEventStoreGranted];
    
    if (accessToEventStoreGranted) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *papersAddedToCalendar;
        if (![defaults objectForKey:QUEPapersAddedToCalendar]) {
            papersAddedToCalendar = [[NSMutableDictionary alloc] init];
        }
        else {
            papersAddedToCalendar = [[defaults objectForKey:QUEPapersAddedToCalendar] mutableCopy];
        }
        
        if (![papersAddedToCalendar objectForKey:[NSString stringWithFormat:@"%@",self.paper.paperId]]) {
            EKEvent *event = [EKEvent eventWithEventStore:self.eventStore];
            
            event.calendar = [self.eventStore defaultCalendarForNewEvents];
            event.title = self.paper.title;
            event.location = self.paper.session.room;
            event.notes = self.paper.abstract;
            event.startDate = self.paper.presentationStart;
            event.endDate = self.paper.presentationEnd;
            
            NSError *error;
            if (![self.eventStore saveEvent:event span:EKSpanThisEvent error:&error]) {
                [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                        message:[error localizedDescription]
                                  dismissButton:NSLocalizedString(@"OK", nil)];
            }
            else {
                [papersAddedToCalendar setObject:[event eventIdentifier]
                                          forKey:[NSString stringWithFormat:@"%@",self.paper.paperId]];
                [defaults setObject:papersAddedToCalendar
                             forKey:QUEPapersAddedToCalendar];
            }
            
        }
        else {
            NSString *eventIdentifier = [papersAddedToCalendar objectForKey:[NSString stringWithFormat:@"%@",self.paper.paperId]];
            
            EKEvent *event = [self.eventStore eventWithIdentifier:eventIdentifier];
            
            if (!event) {
                // user removed it from the calendar manually
                [papersAddedToCalendar removeObjectForKey:[NSString stringWithFormat:@"%@",self.paper.paperId]];
                [defaults setObject:papersAddedToCalendar
                             forKey:QUEPapersAddedToCalendar];
            }
            else {
                NSError *error;
                if (![self.eventStore removeEvent:event span:EKSpanThisEvent error:&error]) {
                    [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                            message:[error localizedDescription]
                                      dismissButton:NSLocalizedString(@"OK", nil)];
                }
                else {
                    [papersAddedToCalendar removeObjectForKey:[NSString stringWithFormat:@"%@",self.paper.paperId]];
                    [defaults setObject:papersAddedToCalendar
                                 forKey:QUEPapersAddedToCalendar];
                }
            }
        }
        [defaults synchronize];
    }
}

#pragma mark - AVSpeechSynthesizerDelegate conformance

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
willSpeakRangeOfSpeechString:(NSRange)characterRange
                utterance:(AVSpeechUtterance *)utterance
{

    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:[self.paper.abstract stringByDecodingXMLEntities]
                                                          attributes:abstractTextAttributes];
    
    [mutableAttributedString addAttribute:NSForegroundColorAttributeName
                                    value:[UIColor blueColor]
                                    range:characterRange];
    self.paperAbstract.attributedText = mutableAttributedString;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
  didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
//    self.paperAbstract.attributedText = [[NSAttributedString alloc] initWithString:[self.paper.abstract stringByDecodingXMLEntities]];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
 didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    self.paperAbstract.attributedText = [[NSAttributedString alloc] initWithString:[self.paper.abstract stringByDecodingXMLEntities]
                                         attributes:abstractTextAttributes];
    self.speechSynthesizer = nil;
}


@end
