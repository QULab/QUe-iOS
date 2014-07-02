//
//  QUESearchViewController.m
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


#import "QUESearchViewController.h"

#import "QUESessionViewController.h"
#import "QUEAuthorViewController.h"
#import "QUEPaperViewController.h"

@interface QUESearchViewController ()

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation QUESearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fetchedResultsController.fetchedObjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    switch (self.searchBar.selectedScopeButtonIndex) {
        case QUESearchScopeSessions: {
            Session *session = [self.fetchedResultsController objectAtIndexPath:indexPath];
            
            static NSString *cellIdentifier = @"Session";
            cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            
            cell.textLabel.text = [NSString stringWithFormat: @"%@", session.title];
            cell.detailTextLabel.text = [NSString stringWithFormat: @"%@ - %@", session.code, session.typeName];
            
            break;
        }
        case QUESearchScopeAuthors: {
            Author *author = [self.fetchedResultsController objectAtIndexPath:indexPath];
            
            NSString *name = [NSString stringWithFormat: @"%@ %@", author.firstName, author.lastName];
            
            UIFont *regularFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   regularFont, NSFontAttributeName, nil];
            const NSRange range = [name rangeOfString:author.firstName];
            
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:name];
            [attributedText setAttributes:attrs range:range];
            
            static NSString *cellIdentifier = @"Author";
            cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
            
            cell.textLabel.attributedText = attributedText;
            cell.detailTextLabel.text = author.affiliation;

            break;
        }
        case QUESearchScopePapers: {
            Paper *paper = [self.fetchedResultsController objectAtIndexPath:indexPath];
            Session *session = paper.session;
            
            static NSString *cellIdentifier = @"Paper";
            cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];            
            
            cell.textLabel.text = [NSString stringWithFormat: @"%@", paper.title];
            cell.detailTextLabel.text = [NSString stringWithFormat: @"%@", session.title];

            break;
        }
        default:
            cell = nil;
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (self.searchBar.selectedScopeButtonIndex) {
        case QUESearchScopeSessions: {
            [self performSegueWithIdentifier:@"showSessionDetail" sender:self];
            break;
        }
        case QUESearchScopeAuthors: {
            [self performSegueWithIdentifier:@"showAuthorDetail" sender:self];
            break;
        }
        case QUESearchScopePapers: {
            [self performSegueWithIdentifier:@"showPaperDetail" sender:self];
            break;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
    id object = [[self.fetchedResultsController fetchedObjects] objectAtIndex:indexPath.row];
    
    if ([segue.identifier isEqualToString:@"showSessionDetail"]) {
        QUESessionViewController *destViewController = segue.destinationViewController;
        destViewController.session = (Session*)object;
    }
    else if ([segue.identifier isEqualToString:@"showAuthorDetail"]) {
        QUEAuthorViewController *destViewController = segue.destinationViewController;
        destViewController.author = (Author *)object;
    }
    else if ([segue.identifier isEqualToString:@"showPaperDetail"]) {
        QUEPaperViewController *destViewController = segue.destinationViewController;
        destViewController.paper = (Paper *)object;
    }
}


#pragma mark - Search

- (void)searchForResults {
    NSFetchRequest *fetchRequest = nil;
    
    switch (self.searchBar.selectedScopeButtonIndex) {
        case QUESearchScopeSessions: {
            fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Session class])];
            
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"start" ascending:YES]];
            
            NSPredicate *SessionPredicate = [NSPredicate predicateWithFormat:@"title CONTAINS[c] %@ OR typeName CONTAINS[cd] %@",
                                             self.searchBar.text, self.searchBar.text];
            fetchRequest.predicate = SessionPredicate;
            break;
        }
        case QUESearchScopeAuthors: {
            fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Author class])];
            
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]];
            
            NSArray *words = [self.searchBar.text componentsSeparatedByString:@" "];
            NSMutableArray *predicateList = [NSMutableArray array];
            for (NSString *word in words) {
                if ([word length] > 0) {
                    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@", @"firstName", word, @"lastName", word, @"affiliation", word];
                    [predicateList addObject:pred];
                }
            }
            NSPredicate *authorPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicateList];

            fetchRequest.predicate = authorPredicate;
            break;
        }
        case QUESearchScopePapers: {
            fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Paper class])];
            
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
            
            NSPredicate *paperPredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@",
                                            @"title", self.searchBar.text, @"abstract", self.searchBar.text, @"code", self.searchBar.text];
            fetchRequest.predicate = paperPredicate;
            break;
        }
    }
    
    self.fetchedResultsController = nil;
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self;
    
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

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if (self.searchBar.text != nil) {
        [self searchForResults];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self searchForResults];
}

@end
