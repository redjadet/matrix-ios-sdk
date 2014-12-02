/*
 Copyright 2014 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "AppDelegate.h"
#import "AppSettings.h"
#import "RoomViewController.h"
#import "MatrixHandler.h"
#import "MediaManager.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate

#pragma mark -

+ (AppDelegate*)theDelegate {
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}
#pragma mark -

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    if ([self.window.rootViewController isKindOfClass:[MasterTabBarController class]])
    {
        self.masterTabBarController = (MasterTabBarController*)self.window.rootViewController;
        self.masterTabBarController.delegate = self;
        
        // By default the "Home" tab is focussed
        [self.masterTabBarController setSelectedIndex:TABBAR_HOME_INDEX];
        
        UIViewController* recents = [self.masterTabBarController.viewControllers objectAtIndex:TABBAR_RECENTS_INDEX];
        if ([recents isKindOfClass:[UISplitViewController class]]) {
            UISplitViewController *splitViewController = (UISplitViewController *)recents;
            UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
            navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
            splitViewController.delegate = self;
        } else {
            // Patch missing image in tabBarItem for iOS < 8.0
            recents.tabBarItem.image = [[UIImage imageNamed:@"tab_recents"] imageWithRenderingMode:UIImageRenderingModeAutomatic];
        }
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if (self.errorNotification) {
        [self.errorNotification dismiss:NO];
        self.errorNotification = nil;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -

- (void)logout {
    // Clear cache
    [MediaManager clearCache];
    // Logout Matrix
    [[MatrixHandler sharedHandler] logout];
    [self.masterTabBarController showLoginScreen];
    // Reset App settings
    [[AppSettings sharedSettings] reset];
    // By default the "Home" tab is focussed
    [self.masterTabBarController setSelectedIndex:TABBAR_HOME_INDEX];
}

- (CustomAlert*)showErrorAsAlert:(NSError*)error {
    if (self.errorNotification) {
        [self.errorNotification dismiss:NO];
    }
    
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    if (!title)
    {
        title = @"Error";
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    self.errorNotification = [[CustomAlert alloc] initWithTitle:title message:msg style:CustomAlertStyleAlert];
    self.errorNotification.cancelButtonIndex = [self.errorNotification addActionWithTitle:@"OK" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
        [AppDelegate theDelegate].errorNotification = nil;
    }];
    [self.errorNotification showInViewController:[self.masterTabBarController selectedViewController]];
    
    return self.errorNotification;
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[RoomViewController class]] && ([(RoomViewController *)[(UINavigationController *)secondaryViewController topViewController] roomId] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

@end