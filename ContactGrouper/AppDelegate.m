//  AppDelegate.m
//
//  by David Phillip Oster © 2021 All Rights Reserved on 11/5/21.
//

#import "AppDelegate.h"
#import "ContactGroupViewController.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  self.window.rootViewController  = [[ContactGroupViewController alloc] init];
  [self.window makeKeyAndVisible];
  return YES;
}

@end
