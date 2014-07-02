//
//  Paper.h
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

@class Author, Session;

@interface Paper : NSManagedObject

@property (nonatomic, retain) NSNumber *paperId;
@property (nonatomic, retain) NSString *code;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *abstract;
@property (nonatomic, retain) NSString *file;
@property (nonatomic, retain) NSDate *presentationStart;
@property (nonatomic, retain) NSDate *presentationEnd;
@property (nonatomic) BOOL favorite;
@property (nonatomic, retain) NSString *calendarEventId;

@property (nonatomic, retain) NSOrderedSet *authors;
@property (nonatomic, retain) Session *session;

@end

@interface Paper (CoreDataGeneratedAccessors)

- (void)addAuthorsObject:(Author *)value;
- (void)removeAuthorsObject:(Author *)value;
- (void)addAuthors:(NSOrderedSet *)values;
- (void)removeAuthors:(NSOrderedSet *)values;

@end
