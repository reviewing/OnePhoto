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
#define TODAY_PHOTO_NAME @"kOPTodayPhotoName"
#define TODAT_IMAGE_DATA @"kOPTodayImageData"

@interface TodayViewController () <NCWidgetProviding>
@property (weak, nonatomic) IBOutlet UIImageView *todayImageView;
@property (weak, nonatomic) IBOutlet UIButton *addPhotoButton;
@property (weak, nonatomic) IBOutlet UILabel *photoCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *consecutiveDaysLabel;

@property (weak, nonatomic) NSString *todayPhotoName;
@property (weak, nonatomic) NSData *todayImageData;
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

    NSString *currentTodayPhotoName = [defaults stringForKey:TODAY_PHOTO_NAME];
    NSInteger currentPhotoCount = [[defaults objectForKey:PHOTO_COUNT_KEY] integerValue];
    NSInteger currentConsecutiveDays = [[defaults objectForKey:CONSECUTIVE_DAYS_KEY] integerValue];
    
    if (![currentTodayPhotoName isEqualToString:self.todayPhotoName] || currentPhotoCount != self.photoCount || currentConsecutiveDays != self.consecutiveDays) {
        self.todayPhotoName = currentTodayPhotoName;
        self.todayImageData = [defaults objectForKey:TODAT_IMAGE_DATA];
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

- (IBAction)open:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:@"open1photo://top.defaults.onephoto/todayext?action=open"];
    [self.extensionContext openURL:url completionHandler:nil];
}

- (IBAction)add:(id)sender {
    NSURL *url = [NSURL URLWithString:@"open1photo://top.defaults.onephoto/todayext?action=add"];
    [self.extensionContext openURL:url completionHandler:nil];
}

- (NSString *)todayImageName {
    return [[NSUserDefaults standardUserDefaults] stringForKey:TODAY_PHOTO_NAME];
}

- (void)setTodayPhotoName:(NSString *)todayPhotoName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:todayPhotoName forKey:TODAY_PHOTO_NAME];
}

- (NSData *)todayImageData {
    return [[NSUserDefaults standardUserDefaults] objectForKey:TODAT_IMAGE_DATA];
}

- (void)setTodayImageData:(NSData *)todayImageData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:todayImageData forKey:TODAT_IMAGE_DATA];
}

- (NSInteger)photoCount {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:PHOTO_COUNT_KEY] integerValue];
}

- (void)setPhotoCount:(NSInteger)photoCount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:photoCount] forKey:PHOTO_COUNT_KEY];
}

- (NSInteger)consecutiveDays {
    return [[[NSUserDefaults standardUserDefaults] objectForKey:CONSECUTIVE_DAYS_KEY] integerValue];
}

- (void)setConsecutiveDays:(NSInteger)consecutiveDays {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:consecutiveDays] forKey:CONSECUTIVE_DAYS_KEY];
}

- (void)updateInterface {
    UIImage *todayPhoto = [UIImage imageWithData:self.todayImageData];
    [self.todayImageView setImage:todayPhoto];
    self.todayImageView.hidden = !todayPhoto;
    self.addPhotoButton.hidden = todayPhoto;
    NSInteger photoCount = self.photoCount;
    self.photoCountLabel.text = [NSString stringWithFormat:@"%ld", (long)photoCount];
    [self.photoCountLabel sizeToFit];
    NSInteger consecutiveDays = self.consecutiveDays;
    self.consecutiveDaysLabel.text = [NSString stringWithFormat:@"%ld", (long)consecutiveDays];
    [self.consecutiveDaysLabel sizeToFit];
}

@end
