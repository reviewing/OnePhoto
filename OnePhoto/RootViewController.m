//
//  ViewController.m
//  OnePhoto
//
//  Created by Hong Duan on 8/27/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "RootViewController.h"
#import "OPCalendarWeekDayView.h"
#import "OPCalendarDayView.h"
#import "AppDelegate.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface RootViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    CGFloat _calendarContentViewMaxHeight;
}

@property (weak, nonatomic) IBOutlet JTCalendarMenuView *calendarMenuView;
@property (weak, nonatomic) IBOutlet OPCalendarWeekDayView *weekDayView;
@property (weak, nonatomic) IBOutlet JTVerticalCalendarView *calendarContentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calendarContentViewAspectRatio;

@property (strong, nonatomic) JTCalendarManager *calendarManager;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _calendarManager = [JTCalendarManager new];
    _calendarManager.delegate = self;
    
    _calendarManager.settings.pageViewHaveWeekDaysView = NO;
    _calendarManager.settings.pageViewNumberOfWeeks = 0;
    _calendarManager.settings.pageViewHideWhenPossible = YES;

    _weekDayView.manager = _calendarManager;
    [_weekDayView reload];
    
    [_calendarManager setMenuView:_calendarMenuView];
    [_calendarManager setContentView:_calendarContentView];
    [_calendarManager setDate:[NSDate date]];
    
    _calendarMenuView.scrollView.scrollEnabled = NO;

//    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
//    NSManagedObjectContext *context = [appDelegate managedObjectContext];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    // resize before scroll
    _calendarContentViewMaxHeight = self.calendarContentView.frame.size.height;
    if ([_calendarManager.dateHelper numberOfWeeks:_calendarContentView.date] != 6) {
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.calendarContentViewAspectRatio.firstItem
                                                                      attribute:self.calendarContentViewAspectRatio.firstAttribute
                                                                      relatedBy:self.calendarContentViewAspectRatio.relation
                                                                         toItem:self.calendarContentViewAspectRatio.secondItem
                                                                      attribute:self.calendarContentViewAspectRatio.secondAttribute
                                                                     multiplier:7.f / [_calendarManager.dateHelper numberOfWeeks:_calendarContentView.date]
                                                                       constant:self.calendarContentViewAspectRatio.constant];
        [self.calendarContentView removeConstraint: self.calendarContentViewAspectRatio];
        self.calendarContentViewAspectRatio = constraint;
        [self.calendarContentView addConstraint: self.calendarContentViewAspectRatio];
    }
}

- (void)viewDidAppear:(BOOL)animated {
}

#pragma mark - Actions
- (IBAction)setting:(id)sender {

}

- (IBAction)takePhoto:(id)sender {
    [self startCameraControllerFromViewController:self usingDelegate:self];
}

- (BOOL) startCameraControllerFromViewController:(UIViewController*) controller
                                   usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
//    cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypeCamera];
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *) kUTTypeImage, nil];
    
    cameraUI.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    cameraUI.allowsEditing = YES;
    cameraUI.delegate = delegate;
    
    [controller presentViewController:cameraUI animated:YES completion:nil];
    return YES;
}

#pragma mark - UIImagePickerController delegate

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *) picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController:(UIImagePickerController *) picker didFinishPickingMediaWithInfo:(NSDictionary *) info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToSave;
    
    // Handle a still image capture
    if (CFStringCompare((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        
        editedImage = (UIImage *) [info objectForKey: UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
        
        if (editedImage) {
            imageToSave = editedImage;
        } else {
            imageToSave = originalImage;
        }
        
        // Save the new image (original or edited) to the Camera Roll
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil , nil);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CalendarManager delegate

- (UIView *)calendarBuildMenuItemView:(JTCalendarManager *)calendar {
    UILabel *label = [UILabel new];
    label.textColor = [GlobalUtils appBaseColor];
    label.textAlignment = NSTextAlignmentCenter;
    
    return label;
}

- (BOOL)calendar:(JTCalendarManager *)calendar canDisplayPageWithDate:(NSDate *)date {
    if ([calendar.dateHelper date:date isEqualOrAfter:[NSDate date]]) {
        return NO;
    }
    return YES;
}

- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(UIView<JTCalendarDay> *)dayView
{
    // Today
    if([_calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:dayView.date]){
        dayView.backgroundColor = [GlobalUtils appBaseColor];
        if ([dayView isKindOfClass:[OPCalendarDayView class]]) {
            ((OPCalendarDayView *)dayView).textLabel.textColor = [UIColor whiteColor];
        }
    } else {
        dayView.backgroundColor = [UIColor clearColor];
        if ([dayView isKindOfClass:[OPCalendarDayView class]]) {
            ((OPCalendarDayView *)dayView).textLabel.textColor = [GlobalUtils appBaseColor];
        }
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(UIView<JTCalendarDay> *)dayView {

}

- (UIView<JTCalendarDay> *)calendarBuildDayView:(JTCalendarManager *)calendar {
    return [OPCalendarDayView new];
}

@end
