//
//  TodayViewController.m
//  OnePhotoSummary
//
//  Created by Hong Duan on 11/3/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

#define PHOTO_COUNT_KEY @"kOPPhotoCount"
#define CONSECUTIVE_DAYS_KEY @"kOPConsecutiveDays"

@interface TodayViewController () <NCWidgetProviding>
@property (weak, nonatomic) IBOutlet UILabel *photoCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *consecutiveDaysLabel;

@property (nonatomic) NSInteger photoCount;
@property (nonatomic) NSInteger consecutiveDays;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateInterface];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
    NSUserDefaults * defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.top.defaults.onephoto"];

    NSInteger currentPhotoCount = [[defaults valueForKey:PHOTO_COUNT_KEY] integerValue];
    NSInteger currentConsecutiveDays = [[defaults valueForKey:CONSECUTIVE_DAYS_KEY] integerValue];
    
    if (currentPhotoCount != self.photoCount || currentConsecutiveDays != self.consecutiveDays) {
        self.photoCount = currentPhotoCount;
        self.consecutiveDays = currentConsecutiveDays;
        [self updateInterface];
        completionHandler(NCUpdateResultNewData);
    } else {
        completionHandler(NCUpdateResultNoData);
    }
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsMake(0, 48, 0, 0);
}

- (IBAction)add:(id)sender {
    NSURL *url = [NSURL URLWithString:@"open1photo://top.defaults.onephoto/todayext?action=add"];
    [self.extensionContext openURL:url completionHandler:nil];
}

- (NSInteger)photoCount {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:PHOTO_COUNT_KEY] integerValue];
}

- (void)setPhotoCount:(NSInteger)photoCount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:photoCount] forKey:PHOTO_COUNT_KEY];
}

- (NSInteger)consecutiveDays {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:CONSECUTIVE_DAYS_KEY] integerValue];
}

- (void)setConsecutiveDays:(NSInteger)consecutiveDays {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:consecutiveDays] forKey:CONSECUTIVE_DAYS_KEY];
}

- (void)updateInterface {
    NSInteger photoCount = self.photoCount;
    self.photoCountLabel.text = [NSString stringWithFormat:@"%ld", (long)photoCount];
    [self.photoCountLabel sizeToFit];
    NSInteger consecutiveDays = self.consecutiveDays;
    self.consecutiveDaysLabel.text = [NSString stringWithFormat:@"%ld", (long)consecutiveDays];
    [self.consecutiveDaysLabel sizeToFit];
}

@end
