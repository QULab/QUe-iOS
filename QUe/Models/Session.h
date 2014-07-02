//
//  Session.h
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


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Paper;

@interface Session : NSManagedObject

@property (nonatomic, retain) NSNumber *sessionId;
@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSNumber *day;
@property (nonatomic, retain) NSDate *start;
@property (nonatomic, retain) NSDate *end;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *typeName;
@property (nonatomic, retain) NSString *room;
@property (nonatomic, retain) NSString *chair;
@property (nonatomic, retain) NSString *coChair;
@property (nonatomic) BOOL favorite;
@property (nonatomic, retain) NSString *calendarEventId;

@property (nonatomic, retain) NSSet *papers;

@end

@interface Session (CoreDataGeneratedAccessors)

- (void)addPapersObject:(Paper *)value;
- (void)removePapersObject:(Paper *)value;
- (void)addPapers:(NSSet *)values;
- (void)removePapers:(NSSet *)values;

@end
