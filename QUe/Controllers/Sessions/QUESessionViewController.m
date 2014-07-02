//
//  QUESessionViewController.m
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


#import "QUESessionViewController.h"
#import <EventKit/EventKit.h>

#import "QUEPaperViewController.h"
#import "QUEPaperCell.h"

static const CGFloat QUESessionViewControllerCellTitleFontSize = 15.0;
static const CGFloat QUESessionViewControllerCellDetailTitleFontSize = 12.0;
static const CGFloat QUESessionViewControllerCellContentMargin = 10.0;

@interface QUESessionViewController ()

@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) NSArray *sortedPapers;

@end

@implementation QUESessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sortedPapers = [[self.session.papers allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"presentationStart"
                                                                                                                 ascending:YES]]];
    self.eventStore = [[EKEventStore alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.topicLabel.text = self.session.title;
    self.roomLabel.text = self.session.room;
    self.typeLabel.text = self.session.typeName;
    
    if (self.session.chair) {
        NSString *chair = [NSString stringWithFormat:@"Chair: %@", self.session.chair];
        
        if (self.session.coChair) {
            chair = [chair stringByAppendingFormat:@", %@",self.session.coChair];
        }
        self.chairLabel.text = chair;
    } else {
        self.chairLabel.hidden = YES;
    }
    
    self.favoriteImageView.hidden = !self.session.favorite;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    NSString *start = [dateFormatter stringFromDate:self.session.start];
    NSString *end = [dateFormatter stringFromDate:self.session.end];
    
    self.timeLabel.text = [NSString stringWithFormat:@"%@ - %@",start,end];
    
    if ([[[NSLocale currentLocale] localeIdentifier] isEqualToString:@"de_DE"]) {
        self.timeLabel.text = [self.timeLabel.text stringByAppendingString:@" Uhr"];
    }

    
    self.tableView.hidden = YES;
    
    [self.tableView reloadData];
    
    [self update];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)update {
    NSString *path = [NSString stringWithFormat:@"sessions/%@",self.session.sessionId];
    [[RKObjectManager sharedManager] getObjectsAtPath:path
                                           parameters:nil
                                              success:^(RKObjectRequestOperation *operation,
                                                        RKMappingResult *mappingResult) {
                                                  self.sortedPapers = [[self.session.papers allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor
                                                                                                                                  sortDescriptorWithKey:@"presentationStart"
                                                                                                                                  ascending:YES]]];
                                                  
                                                  [self.tableView reloadData];
                                              } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                  RKLogError(@"Failed to load sessions: %@",error.localizedDescription);
                                              }];
}


#pragma mark - UITableView Data Source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Papers", nil);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger paperCount = [self.session.papers count];
    
    self.tableView.hidden = paperCount == 0;

    return paperCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Paper";
    QUEPaperCell *cell = (QUEPaperCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                                              forIndexPath:indexPath];
    
    Paper *paper = [self.sortedPapers objectAtIndex:indexPath.row];
    
    cell.paperNameLabel.text = paper.title;
    
    NSMutableString *authorList = [NSMutableString string];
    [paper.authors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx > 0 && idx < [paper.authors count]) {
            [authorList appendString:@", "];
        }
        
        [authorList appendFormat:@"%@ %@",((Author *)obj).firstName, ((Author *)obj).lastName];
    }];

    cell.paperAuthorLabel.text = authorList;
    
    NSDictionary *papersAddedToCalendar = [[NSUserDefaults standardUserDefaults] objectForKey:QUEPapersAddedToCalendar];
    BOOL isAddedToCalendar = NO;
    if (papersAddedToCalendar) {
        isAddedToCalendar = ([papersAddedToCalendar objectForKey:[NSString stringWithFormat:@"%@",paper.paperId]] != nil);
    }
    
    cell.favoriteImageView.hidden = !isAddedToCalendar;
        
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Paper *paper = [self.sortedPapers objectAtIndex:indexPath.row];
    
    CGFloat width = CGRectGetWidth(self.tableView.frame) - QUESessionViewControllerCellContentMargin*2;
    
    CGSize textSize = [paper.title sizeWithFont:[UIFont boldSystemFontOfSize:QUESessionViewControllerCellTitleFontSize]
                                constrainedToSize:CGSizeMake(width, FLT_MAX)];
    CGFloat height = textSize.height;
    
    NSMutableString *authorList = [NSMutableString string];
    [paper.authors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx > 0 && idx < [paper.authors count]) {
            [authorList appendString:@", "];
        }
        
        [authorList appendFormat:@"%@ %@",((Author *)obj).firstName, ((Author *)obj).lastName];
    }];
    
    CGSize detailSize = [authorList sizeWithFont:[UIFont systemFontOfSize:QUESessionViewControllerCellDetailTitleFontSize]
                               constrainedToSize:CGSizeMake(width, FLT_MAX)];
    CGFloat subTitleHeight = detailSize.height;
    
    return height + subTitleHeight + QUESessionViewControllerCellContentMargin*2;
}

#pragma mark - UITableView delegate


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPaperDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        Paper *paper = [self.sortedPapers objectAtIndex:indexPath.row];
        QUEPaperViewController *paperViewController = segue.destinationViewController;
        paperViewController.paper = paper;
    }
}

#pragma mark - Attributed String Helper

- (NSAttributedString *)attributedAuthorList:(NSString *)authors withMainAuthor:(NSString *)mainAuthor {
    UIFont *regularFont = [UIFont boldSystemFontOfSize:12.0];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           regularFont, NSFontAttributeName, nil];
    const NSRange range = [authors rangeOfString:mainAuthor];
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:authors];
    [attributedText setAttributes:attrs range:range];
    
    return attributedText;
}


#pragma mark - Calendar integration

- (IBAction)didSelectActionButton:(id)sender {
    
    NSMutableArray *actions = [NSMutableArray array];
    NSMutableArray *selectors = [NSMutableArray array];
    
    // calendar
    NSString *calendarAddRemove;
    if (!self.session.favorite) {
        calendarAddRemove = [NSString stringWithFormat:@"\U00002B50 %@", NSLocalizedString(@"AddToFavorites", nil)];
    }
    else {
        calendarAddRemove = [NSString stringWithFormat:@"\U00002B50 %@", NSLocalizedString(@"RemoveFromFavorites", nil)];
    }
    [actions addObject:calendarAddRemove];
    [selectors addObject:@"addRemoveFavorite"];
    
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

- (void)addRemoveFavorite {
    self.session.favorite = !self.session.favorite;
    self.favoriteImageView.hidden = !self.session.favorite;
    
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
    
    if([self.eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    else { // we're on iOS 5 or older
        accessGranted = YES;
    }
    
    return accessGranted;
}

- (void)addRemoveCalendarEvent {
    BOOL accessToEventStoreGranted = [self accessToEventStoreGranted];
    
    if (accessToEventStoreGranted) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *sessionsAddedToCalendar;
        if (![defaults objectForKey:QUESessionsAddedToCalendar]) {
            sessionsAddedToCalendar = [[NSMutableDictionary alloc] init];
        }
        else {
            sessionsAddedToCalendar = [[defaults objectForKey:QUESessionsAddedToCalendar] mutableCopy];
        }
        
        if (![sessionsAddedToCalendar objectForKey:[NSString stringWithFormat:@"%@",self.session.sessionId]]) {
            // save to calendar
            
            EKEvent *event = [EKEvent eventWithEventStore:self.eventStore];
            
            event.title = self.session.title;
            event.location = self.session.room;
            [event setCalendar:[self.eventStore defaultCalendarForNewEvents]];
            
            event.startDate = self.session.start;
            event.endDate = self.session.end;
            
            NSError *error;
            
            if (![self.eventStore saveEvent:event span:EKSpanThisEvent error:&error]) {
                [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                        message:[error localizedDescription]
                                  dismissButton:NSLocalizedString(@"OK", nil)];
            }
            else {
                [sessionsAddedToCalendar setObject:[event eventIdentifier]
                                            forKey:[NSString stringWithFormat:@"%@",self.session.sessionId]];
                [defaults setObject:sessionsAddedToCalendar
                             forKey:QUESessionsAddedToCalendar];
            }
            
        }
        else {
            // remove from calendar
            NSString *eventIdentifier = [sessionsAddedToCalendar objectForKey:[NSString stringWithFormat:@"%@",self.session.sessionId]];
            
            EKEvent *event = [self.eventStore eventWithIdentifier:eventIdentifier];
            
            if (!event) {
                [sessionsAddedToCalendar removeObjectForKey:[NSString stringWithFormat:@"%@",self.session.sessionId]];
                [defaults setObject:sessionsAddedToCalendar
                             forKey:QUESessionsAddedToCalendar];
            }
            else {
                NSError *error;
                if (![self.eventStore removeEvent:event span:EKSpanThisEvent error:&error]) {
                    [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                            message:[error localizedDescription]
                                      dismissButton:NSLocalizedString(@"OK", nil)];
                }
                else {
                    [sessionsAddedToCalendar removeObjectForKey:[NSString stringWithFormat:@"%@",self.session.sessionId]];
                    [defaults setObject:sessionsAddedToCalendar
                                 forKey:QUESessionsAddedToCalendar];
                }
            }
        }
        [defaults synchronize];
    }
}

@end
