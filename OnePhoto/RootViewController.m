//
//  ViewController.m
//  OnePhoto
//
//  Created by Hong Duan on 8/27/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "RootViewController.h"
#import "OPVerticalCalendarView.h"
#import "OPCalendarPageView.h"
#import "OPCalendarWeekDayView.h"
#import "OPCalendarWeekView.h"
#import "OPCalendarDayView.h"
#import "OPPhoto.h"
#import "OPPhotoCloud.h"
#import "CoreDataHelper.h"
#import <FastImageCache/FICImageCache.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <MWPhotoBrowser/MWPhoto.h>

#import <MobileCoreServices/MobileCoreServices.h>

@interface RootViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MWPhotoBrowserDelegate> {
    NSInteger _callbackCount;
    
    BOOL _isFirstAppear;
    NSArray *_photos;
    
    NSDate *_specifiedDate;
}

@property (weak, nonatomic) IBOutlet OPCalendarWeekDayView *weekDayView;
@property (weak, nonatomic) IBOutlet OPVerticalCalendarView *calendarContentView;

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
    
    [_calendarManager setContentView:_calendarContentView];
    [_calendarManager setDate:[NSDate date]];
    
    _isFirstAppear = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserverForName:OPCoreDataStoreMerged
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.calendarContentView reloadData];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationSignificantTimeChange:)
                                                 name:UIApplicationSignificantTimeChangeNotification
                                               object:nil];
    [self.calendarContentView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.calendarContentView reloadData];
}

- (void)applicationWillResignActive:(NSNotification *)notification {

}

- (void)applicationSignificantTimeChange:(NSNotification *)notification {
    [self.calendarContentView reloadData];
}


- (void)viewDidAppear:(BOOL)animated {
    if (_isFirstAppear) {
        _isFirstAppear = NO;
        [_calendarContentView scrollToCurrentMonth:NO];
    } else {
        [_calendarContentView scrollToCurrentMonth:YES];
    }
    [self buildFastImageCache];
}

#pragma mark - Actions
- (IBAction)setting:(id)sender {
}

- (IBAction)takePhoto:(id)sender {
    [self startCameraControllerFromViewController:self usingDelegate:self];
}

- (BOOL)startCameraControllerFromViewController:(UIViewController*) controller
                                   usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] == NO) || (delegate == nil) || (controller == nil)) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *) kUTTypeImage, nil];
    cameraUI.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    cameraUI.allowsEditing = YES;
    cameraUI.delegate = delegate;
    
    [controller presentViewController:cameraUI animated:YES completion:nil];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    return YES;
}

#pragma mark - UIImagePickerController delegate

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *) picker {
    _specifiedDate = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

// For responding to the user accepting a newly-captured picture or movie
- (void)imagePickerController:(UIImagePickerController *) picker didFinishPickingMediaWithInfo:(NSDictionary *) info {
    
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
        
        NSString *dateString = [GlobalUtils stringFromDate:_specifiedDate ? _specifiedDate : [NSDate date]];
        NSString *photoPath = [@"photos" stringByAppendingPathComponent:[dateString stringByAppendingPathExtension:@"jpg"]];
        
        NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:photoPath];

        [[CoreDataHelper sharedHelper] insertPhoto:photoPath];
        
        OPPhotoCloud *photoCloud = [[OPPhotoCloud alloc] initWithFileURL:ubiquitousURL];
        photoCloud.imageData = UIImageJPEGRepresentation(imageToSave, 0.8);
        [photoCloud saveToURL:[photoCloud fileURL] forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                DHLogDebug(@"document saved successfully");
            }
        }];
    }
    
    _specifiedDate = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CalendarManager delegate

- (UIView *)calendarBuildMenuItemView:(JTCalendarManager *)calendar {
    UILabel *label = [UILabel new];
    label.textColor = [GlobalUtils appBaseColor];
    label.textAlignment = NSTextAlignmentCenter;
    
    return label;
}

- (UIView<JTCalendarPage> *)calendarBuildPageView:(JTCalendarManager *)calendar {
    return [OPCalendarPageView new];
}

- (UIView<JTCalendarWeek> *)calendarBuildWeekView:(JTCalendarManager *)calendar {
    return [OPCalendarWeekView new];
}

- (void)calendar:(JTCalendarManager *)calendar prepareDayView:(UIView<JTCalendarDay> *)dayView {
    dayView.hidden = NO;

    if ([dayView isFromAnotherMonth]) {
        dayView.hidden = YES;
    } else if ([dayView.date compare:[NSDate date]] == NSOrderedDescending) {
        dayView.hidden = YES;
    }
    // Today
    else if([_calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:dayView.date]){
        dayView.layer.borderColor = [[GlobalUtils appBaseColor] CGColor];
        dayView.layer.borderWidth = 1;
    } else {
        dayView.layer.borderColor = [[UIColor clearColor] CGColor];
        dayView.layer.borderWidth = 0;
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(UIView<JTCalendarDay> *)dayView {
    OPCalendarDayView *lOPDayView = (OPCalendarDayView *)dayView;
    OPPhoto *photo = [[CoreDataHelper sharedHelper] getPhotoAt:[GlobalUtils stringFromDate:lOPDayView.date]];
    if (photo) {
        _photos = [[CoreDataHelper sharedHelper] allPhotosSorted];
        
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        browser.displayActionButton = YES;
        browser.alwaysShowControls = YES;
        browser.zoomPhotosToFill = YES;

        [browser showNextPhotoAnimated:YES];
        [browser showPreviousPhotoAnimated:YES];
        [browser setCurrentPhotoIndex:[_photos indexOfObject:photo]];
        
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
        nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:nc animated:YES completion:nil];
    } else {
        if ([calendar.dateHelper date:lOPDayView.date isTheSameDayThan:[NSDate date]]) {
            [self startCameraControllerFromViewController:self usingDelegate:self];
        } else {
//            _specifiedDate = lOPDayView.date;
//            [self startCameraControllerFromViewController:self usingDelegate:self];
        }
    }
}

- (UIView<JTCalendarDay> *)calendarBuildDayView:(JTCalendarManager *)calendar {
    return [OPCalendarDayView new];
}

#pragma mark - Fast Image Cache

- (void)buildFastImageCache {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^() {
        _callbackCount = 0;
        FICImageCache *sharedImageCache = [FICImageCache sharedImageCache];
        for (OPPhoto *photo in [[CoreDataHelper sharedHelper] allPhotos]) {
            if (![sharedImageCache imageExistsForEntity:photo withFormatName:OPPhotoSquareImage32BitBGRFormatName]) {
                _callbackCount++;
                [sharedImageCache asynchronouslyRetrieveImageForEntity:photo withFormatName:OPPhotoSquareImage32BitBGRFormatName completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
                    _callbackCount--;
                    if (_callbackCount == 0) {
                        DHLogDebug(@"Fast Image Cache build finished.");
                        dispatch_async(dispatch_get_main_queue(), ^(){
                            [self.calendarContentView reloadData];
                        });
                    }
                }];
            }
        }
    });
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count) {
        OPPhoto *photo = [_photos objectAtIndex:index];
        NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:photo.source_image_url];
        return [MWPhoto photoWithURL:ubiquitousURL];
    }
    return nil;
}

- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
    if (index < _photos.count) {
        OPPhoto *photo = [_photos objectAtIndex:index];
        return [[GlobalUtils chineseFormatter] stringFromDate:[[GlobalUtils dateFormatter] dateFromString:photo.dateString]];
    }
    return @"";
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {

}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
