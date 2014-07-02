//
//  QUEAuthorsViewController.m
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


#import "QUEAuthorsViewController.h"
#import "QUEAuthorViewController.h"

static const CGFloat QUEAuthorsViewControllerCellTitleFontSize = 15.0;
static const CGFloat QUEAuthorsViewControllerCellDetailTitleFontSize = 12.0;
static const CGFloat QUEAuthorsViewControllerCellContentMargin = 10.0;

#pragma mark - NSString Addition

@implementation NSString (FetchedGroupByString)

- (NSString *)stringGroupByFirstInitial {
    if (!self.length || self.length == 1) {
        return self;
    }
    
    return [[self substringToIndex:1] uppercaseString];
}

@end

#pragma mark - QUEAuthorsViewController

@interface QUEAuthorsViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation QUEAuthorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        [OHAlertView showAlertWithTitle:NSLocalizedString(@"Error",nil)
                                message:[error localizedDescription]
                          dismissButton:NSLocalizedString(@"OK", nil)];
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Author class])];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastName"
                                                                       ascending:YES
                                                                        selector:@selector(caseInsensitiveCompare:)]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                            managedObjectContext:[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext sectionNameKeyPath:@"lastName.stringGroupByFirstInitial" cacheName:nil];
        self.fetchedResultsController.delegate = self;
    }
    
    return _fetchedResultsController;
}



- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.fetchedResultsController sectionForSectionIndexTitle:title
                                                              atIndex:index];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.fetchedResultsController sectionIndexTitles] objectAtIndex:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
    
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Author *author = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *name = [NSString stringWithFormat: @"%@ %@", author.firstName, author.lastName];
    
    CGFloat width = self.tableView.frame.size.width - QUEAuthorsViewControllerCellContentMargin*2;
    
    CGSize textSize = [name sizeWithFont:[UIFont boldSystemFontOfSize:QUEAuthorsViewControllerCellTitleFontSize]
                       constrainedToSize:CGSizeMake(width, FLT_MAX)];
    CGFloat height = textSize.height;
    
    CGSize detailSize = [author.affiliation sizeWithFont:[UIFont systemFontOfSize:QUEAuthorsViewControllerCellDetailTitleFontSize]
                                       constrainedToSize:CGSizeMake(width, FLT_MAX)];
    CGFloat subTitleHeight = detailSize.height;
    
    return height + subTitleHeight + QUEAuthorsViewControllerCellContentMargin*2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Author";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                            forIndexPath:indexPath];
    
    Author *author = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString *name = [NSString stringWithFormat:@"%@ %@", author.firstName, author.lastName];
    
    UIFont *regularFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    NSDictionary *attributes = @{NSFontAttributeName: regularFont};
    NSRange range = [name rangeOfString:author.firstName];
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:name];
    [attributedText setAttributes:attributes
                            range:range];
    
    cell.textLabel.attributedText = attributedText;
    cell.detailTextLabel.text = author.affiliation;
    
    return cell;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showAuthorDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Author *author = [self.fetchedResultsController objectAtIndexPath:indexPath];
        QUEAuthorViewController *authorViewController = segue.destinationViewController;
        authorViewController.author = author;
    }
}

@end
