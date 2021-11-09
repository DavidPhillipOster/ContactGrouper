//  GroupCell.m
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/5/21.
//

#import "GroupCell.h"

@implementation GroupCell

- (IBAction)membershipDidChange:(id)sender {
  [self.delegate cellDidChange:self];
}

@end
