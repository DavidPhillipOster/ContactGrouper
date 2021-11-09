//  GroupModel.h
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/7/21.
//
#import <Contacts/Contacts.h>

/// a group, and the ids of all the contacts in the group.
@interface GroupModel : NSObject
@property(nonatomic) CNGroup *group;
@property(nonatomic) NSArray<NSString *> *contactIDs;
@end
