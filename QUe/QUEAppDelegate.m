//
//  QUEAppDelegate.m
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

#import "QUEAppDelegate.h"

#import <RestKit/Network/RKPathMatcher.h>

@implementation QUEAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self setupRestKit];
    
    return YES;
}

- (BOOL)applicationDidUpdate {
    
    static NSString * const QUEAppVersion = @"QUEAppVersion";
    BOOL didUpdate = NO;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *currentAppVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *previousVersion = [defaults objectForKey:QUEAppVersion];
    if (!previousVersion) {
        didUpdate = YES;
    }
    else if ([previousVersion isEqualToString:currentAppVersion]) {
        didUpdate = NO;
    }
    else {
        didUpdate = YES;
    }
    
    if (didUpdate) {
        [defaults setObject:currentAppVersion forKey:QUEAppVersion];
        [defaults synchronize];
    }
    
    return didUpdate;
}

#pragma mark - RestKit & Core Data

- (void)setupRestKit {
    
    NSString *remoteURL = QUEServerURL ? QUEServerURL : @"localhost";
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:remoteURL]];
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    manager.managedObjectStore = managedObjectStore;
    
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addPropertyMapping: [RKAttributeMapping attributeMappingFromKeyPath:nil
                                                                            toKeyPath:@"errorMessage"]];
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping
                                                                                         method:RKRequestMethodAny
                                                                                    pathPattern:nil
                                                                                        keyPath:@"error"
                                                                                    statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
    [manager addResponseDescriptor:errorDescriptor];
    
    NSDictionary *authorObjectMapping = @{
                                          @"id"             : @"authorId",
                                          @"first_name"     : @"firstName",
                                          @"last_name"      : @"lastName",
                                          @"affiliation"    : @"affiliation"
                                          };
    
    NSDictionary *sessionObjectMapping = @{
                                           @"id"        : @"sessionId",
                                           @"day"       : @"day",
                                           @"start"     : @"start",
                                           @"end"       : @"end",
                                           @"title"     : @"title",
                                           @"type"      : @"type",
                                           @"type_name" : @"typeName",
                                           @"code"      : @"code",
                                           @"room"      : @"room",
                                           @"chair"     : @"chair",
                                           @"co_chair"  : @"coChair"
                                           };
    
    NSDictionary *paperObjectMapping = @{
                                         @"id"            : @"paperId",
                                         @"title"         : @"title",
                                         @"abstract"      : @"abstract",
                                         @"paper_code"    : @"code",
                                         @"file"          : @"file",
                                         @"datetime"      : @"presentationStart",
                                         @"datetime_end"  : @"presentationEnd",
                                         };
    
    // Authors Mapping
    RKEntityMapping *authorMapping = [RKEntityMapping mappingForEntityForName:NSStringFromClass([Author class])
                                                         inManagedObjectStore:managedObjectStore];
    authorMapping.identificationAttributes = @[@"authorId"];
    [authorMapping addAttributeMappingsFromDictionary:authorObjectMapping];
    
    // Sessions Mapping
    RKEntityMapping *sessionMapping = [RKEntityMapping mappingForEntityForName:NSStringFromClass([Session class])
                                                          inManagedObjectStore:managedObjectStore];
    sessionMapping.identificationAttributes = @[@"sessionId"];
    [sessionMapping addAttributeMappingsFromDictionary:sessionObjectMapping];
    
    // Paper Mapping
    RKEntityMapping *paperMapping = [RKEntityMapping mappingForEntityForName:NSStringFromClass([Paper class])
                                                        inManagedObjectStore:managedObjectStore];
    paperMapping.identificationAttributes = @[@"paperId"];
    [paperMapping addAttributeMappingsFromDictionary:paperObjectMapping];
    
    
    // Author Relationships
    [authorMapping addRelationshipMappingWithSourceKeyPath:@"papers"
                                                   mapping:paperMapping];
    
    // Session Relationships
    [sessionMapping addRelationshipMappingWithSourceKeyPath:@"papers"
                                                    mapping:paperMapping];
    
    // Paper Relationships
    [paperMapping addRelationshipMappingWithSourceKeyPath:@"authors"
                                                  mapping:authorMapping];
    [paperMapping addRelationshipMappingWithSourceKeyPath:@"session"
                                                  mapping:sessionMapping];
    
    // Authors Descriptor
    [manager addResponseDescriptorsFromArray:@[
                                               [RKResponseDescriptor responseDescriptorWithMapping:authorMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"authors"
                                                                                           keyPath:@"authors"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]]];
    
    [manager addResponseDescriptorsFromArray:@[
                                               [RKResponseDescriptor responseDescriptorWithMapping:authorMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"batch"
                                                                                           keyPath:@"batch_download.authors"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]]];
    
    // Sessions Descriptor
    [manager addResponseDescriptorsFromArray:@[
                                               [RKResponseDescriptor responseDescriptorWithMapping:sessionMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"sessions"
                                                                                           keyPath:@"sessions"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]]];
    
    [manager addResponseDescriptorsFromArray:@[
                                               [RKResponseDescriptor responseDescriptorWithMapping:sessionMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"batch"
                                                                                           keyPath:@"batch_download.sessions"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]]];
    
    [manager addResponseDescriptorsFromArray:@[
                                               [RKResponseDescriptor responseDescriptorWithMapping:sessionMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"sessions/:sessionId"
                                                                                           keyPath:@"session"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]]];
    
    // Paper Descriptor
    [manager addResponseDescriptorsFromArray:@[
                                               [RKResponseDescriptor responseDescriptorWithMapping:paperMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"papers"
                                                                                           keyPath:@"papers"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]]];
    
    [manager addResponseDescriptorsFromArray:@[
                                               [RKResponseDescriptor responseDescriptorWithMapping:paperMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"papers/:paperId"
                                                                                           keyPath:@"paper"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]]];
    
    [manager addResponseDescriptorsFromArray:@[
                                               [RKResponseDescriptor responseDescriptorWithMapping:paperMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"batch"
                                                                                           keyPath:@"batch_download.papers"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]]];
    
    
    
    
#ifdef RESTKIT_GENERATE_SEED_DB
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelInfo);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelTrace);
    
    NSError *error = nil;
    BOOL success = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
    if (!success) {
        RKLogError(@"Failed to create Application Data Directory at path '%@': %@", RKApplicationDataDirectory(), error);
    }
    NSString *seedStorePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"SeedDatabase.sqlite"];
    RKManagedObjectImporter *importer = [[RKManagedObjectImporter alloc] initWithManagedObjectModel:managedObjectModel storePath:seedStorePath];
    [importer importObjectsFromItemAtPath:[[NSBundle mainBundle] pathForResource:@"sessions" ofType:@"json"]
                              withMapping:sessionMapping
                                  keyPath:@"sessions"
                                    error:&error];
    [importer importObjectsFromItemAtPath:[[NSBundle mainBundle] pathForResource:@"authors" ofType:@"json"]
                              withMapping:authorMapping
                                  keyPath:@"authors"
                                    error:&error];
    
    [importer importObjectsFromItemAtPath:[[NSBundle mainBundle] pathForResource:@"papers" ofType:@"json"]
                              withMapping:paperMapping
                                  keyPath:@"papers"
                                    error:&error];
    success = [importer finishImporting:&error];
    if (success) {
        [importer logSeedingInfo];
    } else {
        RKLogError(@"Failed to finish import and save seed database due to error: %@", error);
    }
    
    [self.window setRootViewController:[UIViewController new]];
#else
    [managedObjectStore createPersistentStoreCoordinator];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"ConferenceData.sqlite"];
    NSString *seedPath = [[NSBundle mainBundle] pathForResource:@"SeedDatabase" ofType:@"sqlite"];
    NSError *error;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath
                                                                     fromSeedDatabaseAtPath:seedPath
                                                                          withConfiguration:nil
                                                                                    options:nil
                                                                                      error:&error];
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    [managedObjectStore createManagedObjectContexts];
    
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
#endif
}

@end
