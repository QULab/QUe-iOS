//
//  QUEPaperViewController.h
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


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, QUETaskInterruptedByAuthentication) {
    QUETaskInterruptedByAuthenticationAddToCalendar,
    QUETaskInterruptedByAuthenticationRemoveFromCalendar,
    QUETaskInterruptedByAuthenticationDisplayPDF
};

@interface QUEPaperViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *paperTitle;
@property (weak, nonatomic) IBOutlet UILabel *author;
@property (weak, nonatomic) IBOutlet UITextView *paperAbstract;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomLabel;
@property (weak, nonatomic) IBOutlet UIImageView *favoriteImageView;

@property (strong, nonatomic) Paper *paper;
@property (nonatomic, assign) BOOL presentedModally;
@property (weak, nonatomic) NSNumber *recommendationId;

- (IBAction)didSelectActionButton:(id)sender;

@end
