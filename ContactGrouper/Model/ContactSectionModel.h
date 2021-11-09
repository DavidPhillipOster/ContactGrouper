#import <UIKit/UIKit.h>

/// The UITableView Contacts model is an array of these.
@interface ContactSectionModel : NSObject
@property(nonatomic) NSString *title;
@property(nonatomic) NSArray *contacts;
@end
