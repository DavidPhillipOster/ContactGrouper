//  CNContactStore+Additions.m
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/6/21.
//

#import "CNContactStore+Additions.h"

@implementation CNContactStore(ContactGrouper)

// note To fetch all contacts use enumerateContactsWithFetchRequest:error:usingBlock:.
- (nullable NSArray<CNContact*> *)cg_discreteContactsMatchingPredicate:(NSPredicate *)predicate keysToFetch:(NSArray<id<CNKeyDescriptor>> *)keys error:(NSError **)error {
  NSMutableArray<CNContact*> *result = [NSMutableArray array];
  CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
  request.predicate = predicate;
  request.unifyResults = NO;
  request.sortOrder = CNContactSortOrderUserDefault;
  request.mutableObjects = YES; // doesn't change the error.
  [self enumerateContactsWithFetchRequest:request error:error usingBlock:^(CNContact *contact, BOOL *stop) {
    [result addObject:contact];
  }];
  return result;
}


@end
