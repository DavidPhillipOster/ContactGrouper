//  CNContactStore+Additions.h
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/6/21.
//
#import <Contacts/Contacts.h>

NS_ASSUME_NONNULL_BEGIN

@interface CNContactStore(ContactGrouper)

/*!
 * @abstract Fetch all non-unified contacts matching a given predicate.
 *
 * @discussion Use only predicates from CNContact+Predicates.h. Compound predicates are not supported. Due to unification the returned contacts may have a different identifier.
 *
 * @param predicate The predicate to match against.
 * @param keys The properties to fetch into the returned CNContact objects. Should only fetch the properties that will be used. Can combine contact keys and contact key descriptors.
 * @param error If an error occurs, contains error information.
 * @return An array of CNContact objects matching the predicate. If no matches are found, an empty array is returned. If an error occurs, nil is returned.
 */
- (nullable NSArray<CNContact*> *)cg_discreteContactsMatchingPredicate:(NSPredicate *)predicate keysToFetch:(NSArray<id<CNKeyDescriptor>> *)keys error:(NSError **)error;


@end

NS_ASSUME_NONNULL_END

