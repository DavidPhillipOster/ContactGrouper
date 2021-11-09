//  RootView.m
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/7/21.
//
#import "RootView.h"

@implementation RootView

- (void)layoutSubviews {
  [super layoutSubviews];
  CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, self.safeAreaInsets);
  CGRect contactR, groupR;
  CGRectDivide(bounds, &contactR, &groupR, bounds.size.width/2, CGRectMinXEdge);
  self.contactTableView.frame = contactR;
  CGRect labelR;
  CGRectDivide(groupR, &labelR, &groupR, 80, CGRectMinYEdge);
  labelR = UIEdgeInsetsInsetRect(labelR, UIEdgeInsetsMake(20, 5, 2, 5));
  self.contactLabel.frame = labelR;
  self.groupTableView.frame = groupR;
}

@end
