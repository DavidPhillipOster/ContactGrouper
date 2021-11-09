//  RootView.h
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/7/21.
//

#import <UIKit/UIKit.h>

/// This exists as a simple way to layout the views.
@interface RootView : UIView
@property(nonatomic) UITableView *contactTableView;
@property(nonatomic) UILabel *contactLabel;
@property(nonatomic) UITableView *groupTableView;
@end
