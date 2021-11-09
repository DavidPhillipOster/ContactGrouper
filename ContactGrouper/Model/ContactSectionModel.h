//  ContactSectionModel.h
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/7/21.
//

#import <UIKit/UIKit.h>

/// The UITableView Contacts model is an array of these.
@interface ContactSectionModel : NSObject
@property(nonatomic) NSString *title;
@property(nonatomic) NSArray *contacts;
@end
