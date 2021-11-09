//  GroupCell.h
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/5/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SwitchDelegate;

/// A cell holding a group name and an on/off switch.
@interface GroupCell : UITableViewCell
@property(nonatomic, weak) id<SwitchDelegate> delegate;
@property(nonatomic) IBOutlet UILabel *title;
@property(nonatomic) IBOutlet UISwitch *isMember;
@property(nonatomic) NSInteger groupIndex;
@end

@protocol SwitchDelegate <NSObject>
- (void)cellDidChange:(GroupCell *)cell;
@end

NS_ASSUME_NONNULL_END
