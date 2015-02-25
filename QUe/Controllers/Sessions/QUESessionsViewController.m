//
//  QUESessionsViewController.m
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


#import "QUESessionsViewController.h"

#import "QUESessionViewController.h"
#import "QUEPaperViewController.h"
#import "QUESessionCell.h"

static const CGFloat QUESessionsViewControllerCellTitleFontSize = 15.0;
static const CGFloat QUESessionsViewControllerCellDetailTitleFontSize = 12.0;
static const CGFloat QUESessionsViewControllerCellContentMargin = 10.0;

#pragma mark - NSDate Addition

@implementation NSDate (SectionDateAdditions)

- (NSString *)stringContainingTimeOnly {
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"HH:mm";
    
    return [df stringFromDate:self];
}

@end

#pragma mark - QUESessionsViewController

@interface QUESessionsViewController () <NSFetchedResultsControllerDelegate> {
    NSMutableArray *weekdays;
    NSUInteger selectedDay;
    NSArray *searchResults;
    UITableView *activeTableView;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation QUESessionsViewController

- (void)setupBasicFetchedResultsController {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Session class])];
    
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"start"
                                                                   ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                   ascending:YES]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@",@"day",@0];
    
    self.fetchedResultsController = nil;
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext
                                                                          sectionNameKeyPath:@"start.stringContainingTimeOnly"
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self;
    activeTableView = self.tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setup];
    
    [self update];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSIndexPath *selection = [self.tableView indexPathForSelectedRow];
    if (selection) {
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
    }
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                message:[error localizedDescription]
                          dismissButton:NSLocalizedString(@"OK", nil)];
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)setup {
    [self setupBasicFetchedResultsController];
    
    self.nextDayButton.enabled = NO;
    self.previousDayButton.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Session class])];
    
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.propertiesToFetch = @[@"start"];
    fetchRequest.returnsDistinctResults = YES;
    NSArray *dictionaries = [[RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    if ([[[NSLocale currentLocale] localeIdentifier] isEqualToString:@"de_DE"]) {
        // use German format
        df.locale = [NSLocale currentLocale];
        df.dateFormat = @"EEEE, dd. MMMM";
    }
    else {
        // use en_US format
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        df.dateFormat = @"EEEE, MMMM dd";
    }
    
    self.currentDayLabel.text = [df stringFromDate:[NSDate date]];
    
    // get only yyyy-MM-dd
    unsigned int flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [calendar components:flags fromDate:[NSDate date]];
    NSDate *today = [calendar dateFromComponents:todayComponents];
    
    // get distinct weekdays and set selected day (if possible)
    weekdays = [NSMutableArray array];
    
    for (NSDictionary *dict in dictionaries) {
        if (![dict count]) {
            break;
        }
        
        NSDate *other = [dict objectForKey:@"start"];
        NSString *weekday = [df stringFromDate:other];
        if (![weekdays containsObject:weekday]) {
            [weekdays addObject:weekday];
        }
    }
    
    // sort by date ascending
    weekdays = [[weekdays sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *date1 = [df dateFromString:obj1];
        NSDate *date2 = [df dateFromString:obj2];
        return [date1 compare:date2];
    }] mutableCopy];
    
    // find selected index
    for (NSString *dateString in weekdays) {
        NSDate *date = [df dateFromString:dateString];
        if ([today isEqualToDate:date])
            selectedDay = [weekdays indexOfObject:dateString];
    }

    if ([weekdays count] > 0) {
        [self updateDayNavigator];
    }
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.fetchedResultsController sectionForSectionIndexTitle:title
                                                              atIndex:index];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id  sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    
    return [sectionInfo name];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    
    if (tableView == activeTableView) {
        numberOfSections = [[self.fetchedResultsController sections] count];
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    if (tableView == activeTableView) {
        id sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    
    return numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView &&
        self.searchDisplayController.searchBar.selectedScopeButtonIndex == QUESearchScopePapers) {
        Paper *paper = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        CGFloat width = self.searchDisplayController.searchResultsTableView.frame.size.width - QUESessionsViewControllerCellContentMargin*2 - 20;
        
        CGSize textSize = [paper.title sizeWithFont:[UIFont boldSystemFontOfSize:QUESessionsViewControllerCellTitleFontSize]
                                  constrainedToSize:CGSizeMake(width, FLT_MAX)];
        CGFloat height = textSize.height;
        
        NSMutableString *authorList = [NSMutableString string];
        [paper.authors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (idx > 0 && idx < [paper.authors count]) {
                [authorList appendString:@", "];
            }
            
            [authorList appendFormat:@"%@ %@",((Author *)obj).firstName, ((Author *)obj).lastName];
        }];
        
        CGSize detailSize = [authorList sizeWithFont:[UIFont systemFontOfSize:QUESessionsViewControllerCellDetailTitleFontSize]
                                   constrainedToSize:CGSizeMake(width, FLT_MAX)];
        CGFloat subTitleHeight = detailSize.height;
        
        return height + subTitleHeight + QUESessionsViewControllerCellContentMargin*2;
    } else {
        Session *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        CGFloat width = self.tableView.frame.size.width - QUESessionsViewControllerCellContentMargin*2 - 20;
        
        CGSize textSize = [session.title sizeWithFont:[UIFont boldSystemFontOfSize:QUESessionsViewControllerCellTitleFontSize]
                                    constrainedToSize:CGSizeMake(width, FLT_MAX)];
        CGFloat height = textSize.height;
        
        CGFloat subTitleHeight = QUESessionsViewControllerCellDetailTitleFontSize + QUESessionsViewControllerCellContentMargin;
        
        return height + subTitleHeight + QUESessionsViewControllerCellContentMargin*2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        switch (self.searchDisplayController.searchBar.selectedScopeButtonIndex) {
            case QUESearchScopeSessions: {
                Session *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
                
                static NSString *CellIdentifier = @"Session";
                QUESessionCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                cell.textLabel.text = [NSString stringWithFormat:@"%@", session.title];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", session.typeName, session.room];
                cell.favoriteImageView.hidden = !session.favorite;
                
                return cell;
                
                break;
            }
            case QUESearchScopePapers: {
                Paper *paper = [self.fetchedResultsController objectAtIndexPath:indexPath];
                
                static NSString *CellIdentifier = @"Session";
                QUESessionCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                
                cell.textLabel.text = [NSString stringWithFormat: @"%@", paper.title];
                
                NSMutableString *authorList = [NSMutableString string];
                [paper.authors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if (idx > 0 && idx < [paper.authors count]) {
                        [authorList appendString:@", "];
                    }
                    
                    [authorList appendFormat:@"%@ %@",((Author *)obj).firstName, ((Author *)obj).lastName];
                }];
                
                cell.detailTextLabel.text = authorList;
                cell.favoriteImageView.hidden = !paper.favorite;
                
                return cell;
                
                break;
            }
        }
    } else {
        static NSString *CellIdentifier = @"Session";
        QUESessionCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                                    forIndexPath:indexPath];
        Session *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", session.title];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", session.typeName, session.room];
        cell.favoriteImageView.hidden = !session.favorite;
        
        return cell;
    }
    
    return nil;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView reloadData];
}

#pragma mark - Search
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [activeTableView setContentOffset:activeTableView.contentOffset animated:NO];
    activeTableView = self.searchDisplayController.searchResultsTableView;
    self.searchDisplayController.searchBar.selectedScopeButtonIndex = QUESearchScopeSessions;
    [self searchBar:self.searchDisplayController.searchBar selectedScopeButtonIndexDidChange:QUESearchScopeSessions];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    activeTableView = self.tableView;
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    NSFetchRequest *fetchRequest;
    switch (selectedScope) {
        case QUESearchScopeSessions: {
            fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Session class])];
            
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"start" ascending:YES]];
            break;
        }
        case QUESearchScopePapers: {
            fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Paper class])];
            
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
            break;
        }
    }
    
    self.fetchedResultsController = nil;
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSPredicate *predicate;
    switch (searchBar.selectedScopeButtonIndex) {
        case QUESearchScopeSessions: {
            predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[c] %@ OR typeName CONTAINS[cd] %@",
                         self.searchDisplayController.searchBar.text, self.searchDisplayController.searchBar.text];
            
            break;
        }
        case QUESearchScopePapers: {
            predicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@",
                         @"title", self.searchDisplayController.searchBar.text, @"abstract", self.searchDisplayController.searchBar.text, @"code", self.searchDisplayController.searchBar.text];
            break;
        }
    }
    
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                message:[error localizedDescription]
                          dismissButton:NSLocalizedString(@"OK", nil)];
    }
    else {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self setupBasicFetchedResultsController];
    [self.searchDisplayController.searchResultsTableView reloadData];
    [self.tableView reloadData];
    [self updateDayNavigator];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchDisplayController.active &&
        self.searchDisplayController.searchBar.selectedScopeButtonIndex == QUESearchScopePapers) {
        [self performSegueWithIdentifier:@"showPaperDetail" sender:nil];
    } else {
        [self performSegueWithIdentifier:@"showSessionDetail" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showSessionDetail"]) {
        NSIndexPath *indexPath;
        if (self.searchDisplayController.active) {
            indexPath = self.searchDisplayController.searchResultsTableView.indexPathForSelectedRow;
        } else {
            indexPath = self.tableView.indexPathForSelectedRow;
        }
        
        Session *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
        QUESessionViewController *sessionViewController = segue.destinationViewController;
        sessionViewController.session = session;
    } else if ([segue.identifier isEqualToString:@"showPaperDetail"]) {
        NSIndexPath *indexPath = self.searchDisplayController.searchResultsTableView.indexPathForSelectedRow;
        
        Paper *paper = [self.fetchedResultsController objectAtIndexPath:indexPath];
        QUEPaperViewController *paperViewController = segue.destinationViewController;
        paperViewController.paper = paper;
    }
    
    if (self.searchDisplayController.active) {
        [self.searchDisplayController setActive:NO];
        [self setupBasicFetchedResultsController];
        [self.tableView reloadData];
        [self updateDayNavigator];
    }
}

-(IBAction)changeDay:(id)sender {
    NSUInteger currentIndex = [weekdays indexOfObject:self.currentDayLabel.text];    
    selectedDay = (sender == self.previousDayButton) ? currentIndex-1 : currentIndex+1;
    
    [self updateDayNavigator];
}

- (void)updateDayNavigator {
    self.nextDayButton.enabled = (selectedDay+1 < [weekdays count]);
    self.previousDayButton.enabled = (selectedDay > 0);
    
    self.currentDayLabel.text = [weekdays objectAtIndex:selectedDay];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@",@"day", @(selectedDay)];
    self.fetchedResultsController.fetchRequest.predicate = predicate;
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error", nil)
                                message:[error localizedDescription]
                          dismissButton:NSLocalizedString(@"OK", nil)];
    }
    else {
        [self.tableView reloadData];
    }
}

- (IBAction)scrollToCurrentTimeSlot:(id)sender {
    NSDateFormatter *df1 = [[NSDateFormatter alloc] init];
    if ([[[NSLocale currentLocale] localeIdentifier] isEqualToString:@"de_DE"]) {
        // use German format
        df1.locale = [NSLocale currentLocale];
        df1.dateFormat = @"EEEE, dd. MMMM";
    }
    else {
        // use en_US format
        df1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        df1.dateFormat = @"EEEE, MMMM dd";
    }
    NSString *currentDay = [df1 stringFromDate:[NSDate date]];
    if ([weekdays containsObject:currentDay]) {
        selectedDay = [weekdays indexOfObject:currentDay];
        [self updateDayNavigator];
    }
    
    NSMutableArray *sectionDates = [NSMutableArray array];
    for (id sectionInfo in [self.fetchedResultsController sections]) {
        [sectionDates addObject:[sectionInfo name]];
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"HH:mm";
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                               fromDate:[NSDate date]];
    
    NSArray *sortedSectionDates = [sectionDates sortedArrayUsingComparator:^(id obj1, id obj2) {
        NSArray *obj1Components = [obj1 componentsSeparatedByString:@":"];
        [components setHour:[[obj1Components objectAtIndex:0] intValue]];
        [components setMinute:[[obj1Components objectAtIndex:1] intValue]];
        NSDate *date1 = [calendar dateFromComponents:components];
        
        NSArray *obj2Components = [obj2 componentsSeparatedByString:@":"];
        [components setHour:[[obj2Components objectAtIndex:0] intValue]];
        [components setMinute:[[obj2Components objectAtIndex:1] intValue]];
        NSDate *date2 = [calendar dateFromComponents:components];
        
        NSNumber *interval1 = [NSNumber numberWithDouble:abs([date1 timeIntervalSinceNow])];
        NSNumber *interval2 = [NSNumber numberWithDouble:abs([date2 timeIntervalSinceNow])];
        
        return [interval1 compare:interval2];
    }];
    
    NSString *closestDateString = [sortedSectionDates firstObject];
    NSUInteger section = [sectionDates indexOfObject:closestDateString];
    NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:0
                                                      inSection:section];
    
    [self.tableView scrollToRowAtIndexPath:scrollIndexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
}

- (void)update {
    
    if (!QUEServerURL) {
        // no remote url given -> no update
        return;
    }
    
    [[RKObjectManager sharedManager] getObjectsAtPath:@"sessions"
                                           parameters:nil
                                              success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                  [self setup];
                                                  [self.tableView reloadData];
                                              } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                  RKLogError(@"Failed to load sessions: %@",error.localizedDescription);
                                              }];
}


@end