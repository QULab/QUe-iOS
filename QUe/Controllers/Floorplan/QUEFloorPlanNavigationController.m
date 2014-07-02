//
//  QUEFloorPlanNavigationController.m
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


#import "QUEFloorPlanNavigationController.h"

#import "FloorPlanViewController.h"
#import "ImageScrollView.h"

@implementation QUEFloorPlanNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    FloorPlanViewController *pageZero = [FloorPlanViewController floorPlanViewControllerForPageIndex:0];
    if (pageZero != nil)
    {
        UIPageViewController *pageViewController = (UIPageViewController *)self.topViewController;
        pageViewController.dataSource = self;
        pageViewController.delegate = self;
        pageViewController.navigationItem.title = [ImageScrollView imageTitleAtIndex:0];
        
        [pageViewController setViewControllers:@[pageZero]
                                     direction:UIPageViewControllerNavigationDirectionForward
                                      animated:NO
                                    completion:NULL];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

# pragma mark - UIPageViewController Datasource

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerBeforeViewController:(FloorPlanViewController *)vc
{
    NSUInteger index = vc.pageIndex;
    return [FloorPlanViewController floorPlanViewControllerForPageIndex:(index - 1)];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc viewControllerAfterViewController:(FloorPlanViewController *)vc
{
    NSUInteger index = vc.pageIndex;
    return [FloorPlanViewController floorPlanViewControllerForPageIndex:(index + 1)];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return [ImageScrollView imageCount];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pvc {
    FloorPlanViewController *vc = (FloorPlanViewController *)pvc.presentedViewController;
    
    return vc.pageIndex;
}

#pragma mark - UIPageViewController Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    FloorPlanViewController *vc = [pendingViewControllers objectAtIndex:0];
    
    self.topViewController.navigationItem.title = [ImageScrollView imageTitleAtIndex:vc.pageIndex];;
}

@end
