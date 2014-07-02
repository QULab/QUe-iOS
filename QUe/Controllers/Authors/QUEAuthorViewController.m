//
//  QUEAuthorViewController.m
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


#import "QUEAuthorViewController.h"

#import "QUEPaperViewController.h"

static const CGFloat QUEAuthorViewControllerCellTitleFontSize = 15.0;
static const CGFloat QUEAuthorViewControllerCellDetailTitleFontSize = 12.0;
static const CGFloat QUEAuthorViewControllerCellContentMargin = 10.0;
static const CGFloat QUEAuthorViewControllerCellAccessorySize = 25.0;

@implementation QUEAuthorViewController


-(void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = [NSString stringWithFormat:@"%@ %@", self.author.firstName, self.author.lastName];
    self.name.text = [NSString stringWithFormat:@"%@ %@", self.author.firstName, self.author.lastName];
    self.work.text = self.author.affiliation;
    
    NSIndexPath *selection = [self.papersTableView indexPathForSelectedRow];
    if (selection) {
        [self.papersTableView deselectRowAtIndexPath:selection animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - UITableView Delegate Methods

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)papers {
    return NULL;
}

- (NSInteger)tableView:(UITableView *)papers sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return 1;
}

- (NSString *)tableView:(UITableView *)papers titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"Papers", nil);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)papers {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.author.papers count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Paper *paper = [[self.author.papers allObjects] objectAtIndex:indexPath.row];
    
    CGFloat width = tableView.frame.size.width - QUEAuthorViewControllerCellContentMargin*2 - QUEAuthorViewControllerCellAccessorySize;
    
    CGSize textSize = [paper.title sizeWithFont:[UIFont boldSystemFontOfSize:QUEAuthorViewControllerCellTitleFontSize]
                              constrainedToSize:CGSizeMake(width, FLT_MAX)];
    CGFloat height = textSize.height;
    
    Session *session = paper.session;
    CGSize detailSize = [session.title sizeWithFont:[UIFont systemFontOfSize:QUEAuthorViewControllerCellDetailTitleFontSize]
                                  constrainedToSize:CGSizeMake(width, FLT_MAX)];
    CGFloat subTitleHeight = detailSize.height;
    
    return height + subTitleHeight + QUEAuthorViewControllerCellContentMargin*2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Paper";
    UITableViewCell *cell = [self.papersTableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Paper *paper = [[self.author.papers allObjects] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat: @"%@", paper.title];
    Session *session = paper.session;
    cell.detailTextLabel.text = [NSString stringWithFormat: @"%@", session.title];
    
    return cell;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.papersTableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPaperDetail"]) {
        NSIndexPath *indexPath = [self.papersTableView indexPathForSelectedRow];
        Paper *paper = [[self.author.papers allObjects] objectAtIndex:indexPath.row];
        QUEPaperViewController *paperViewController = segue.destinationViewController;
        paperViewController.paper = paper;
    }
}

@end
