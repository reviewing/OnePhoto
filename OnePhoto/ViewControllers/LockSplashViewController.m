//
//  LockSplashViewController.m
//  OnePhoto
//
//  Created by Hong Duan on 11/5/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "LockSplashViewController.h"

@interface LockSplashViewController ()

@end

@implementation LockSplashViewController

- (instancetype)init {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self = [storyboard instantiateViewControllerWithIdentifier:@"LockSplashViewController"];
    DHLogDebug(@"----init");
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    DHLogDebug(@"----init");
    self.view.backgroundColor = [GlobalUtils appBaseColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
