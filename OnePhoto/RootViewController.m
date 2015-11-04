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
#import <MBProgressHUD/MBProgressHUD.h>

#import <MobileCoreServices/MobileCoreServices.h>

#define MAIN_TITLE @"1 Photo"

@interface RootViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MWPhotoBrowserDelegate> {
    MBProgressHUD *_hud;
    
    NSInteger _callbackCount;
    
    BOOL _isFirstAppear;
    NSArray *_photos;
    
    NSDate *_specifiedDate;
}

@property (weak, nonatomic) IBOutlet OPCalendarWeekDayView *weekDayView;
@property (weak, nonatomic) IBOutlet OPVerticalCalendarView *calendarContentView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addPhotoItem;

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
    
    _hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_hud];
    
    CGRect headerTitleSubtitleFrame = CGRectMake(0, 0, 200, 44);
    UIView* _headerTitleSubtitleView = [[UILabel alloc] initWithFrame:headerTitleSubtitleFrame];
    _headerTitleSubtitleView.backgroundColor = [UIColor clearColor];
    _headerTitleSubtitleView.autoresizesSubviews = YES;
    
    CGRect titleFrame = CGRectMake(0, 2, 200, 24);
    UILabel *titleView = [[UILabel alloc] initWithFrame:titleFrame];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.font = [UIFont boldSystemFontOfSize:17];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.textColor = [UIColor whiteColor];
    titleView.text = @"";
    titleView.adjustsFontSizeToFitWidth = YES;
    [_headerTitleSubtitleView addSubview:titleView];
    
    CGRect subtitleFrame = CGRectMake(0, 24, 200, 44-24);
    UILabel *subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
    subtitleView.backgroundColor = [UIColor clearColor];
    subtitleView.font = [UIFont boldSystemFontOfSize:12];
    subtitleView.textAlignment = NSTextAlignmentCenter;
    subtitleView.textColor = [UIColor whiteColor];
    subtitleView.text = @"";
    subtitleView.adjustsFontSizeToFitWidth = YES;
    [_headerTitleSubtitleView addSubview:subtitleView];
    
    _headerTitleSubtitleView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                                 UIViewAutoresizingFlexibleRightMargin |
                                                 UIViewAutoresizingFlexibleTopMargin |
                                                 UIViewAutoresizingFlexibleBottomMargin);
    
    self.navigationItem.titleView = _headerTitleSubtitleView;
    [self setHeaderTitle:MAIN_TITLE andSubtitle:nil];
}

- (void)setHeaderTitle:(NSString *)headerTitle andSubtitle:(NSString *)headerSubtitle {
    assert(self.navigationItem.titleView != nil);
    UIView* headerTitleSubtitleView = self.navigationItem.titleView;
    UILabel* titleView = [headerTitleSubtitleView.subviews objectAtIndex:0];
    UILabel* subtitleView = [headerTitleSubtitleView.subviews objectAtIndex:1];
    assert((titleView != nil) && (subtitleView != nil) && ([titleView isKindOfClass:[UILabel class]]) && ([subtitleView isKindOfClass:[UILabel class]]));
    titleView.text = headerTitle;
    subtitleView.text = headerSubtitle;
    
    if ([headerSubtitle length] == 0) {
        subtitleView.hidden = YES;
        titleView.frame = CGRectMake(0, 10, 200, 24);
    } else {
        subtitleView.hidden = NO;
        titleView.frame = CGRectMake(0, 2, 200, 24);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([IM_JUMPING_TO isEqualToString:@"UIImagePickerController"]) {
        [self newPhotoAction];
        SET_JUMPING(nil, nil);
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storeDidChange:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:[NSUbiquitousKeyValueStore defaultStore]];
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:OPCoreDataStoreMerged
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      DHLogDebug(@"OPCoreDataStoreMergedNotification");
                                                      [self.calendarContentView reloadData];
                                                      [self setHeaderTitle:MAIN_TITLE andSubtitle:nil];
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
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_hud hide:YES];
}

- (void)storeDidChange:(NSNotification *)notification {
    DHLogDebug(@"storeDidChange");
    long long countOfPhotos = [[NSUbiquitousKeyValueStore defaultStore] longLongForKey:OPUbiquitousKeyValueStoreHasPhotoKey];
    DHLogDebug(@"countOfPhotos: %lld", countOfPhotos);
    [self setHeaderTitle:MAIN_TITLE andSubtitle:@"正在同步..."];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if ([IM_JUMPING_TO isEqualToString:@"UIImagePickerController"]) {
        [self newPhotoAction];
        SET_JUMPING(nil, nil);
    }
    [self.calendarContentView reloadData];
}

- (void)applicationWillResignActive:(NSNotification *)notification {

}

- (void)applicationSignificantTimeChange:(NSNotification *)notification {
    [self.calendarContentView reloadData];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    [self newPhotoAction];
}

- (BOOL)startCameraControllerFromViewController:(UIViewController*) controller sourceType:(UIImagePickerControllerSourceType) sourceType
                                   usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable: sourceType] == NO) || (delegate == nil) || (controller == nil)) {
        return NO;
    }
    
    [_hud show:YES];

    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = sourceType;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
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
        NSString *photoPath = [@"photos" stringByAppendingPathComponent:[[dateString stringByAppendingString:[[[NSUUID UUID] UUIDString] substringToIndex:8]] stringByAppendingPathExtension:@"jpg"]];
        
        NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:photoPath];
        
        OPPhotoCloud *photoCloud = [[OPPhotoCloud alloc] initWithFileURL:ubiquitousURL];
        photoCloud.imageData = UIImageJPEGRepresentation(imageToSave, 0.8);
        
        __block BOOL isToday = !_specifiedDate;
        [photoCloud saveToURL:[photoCloud fileURL] forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                [[CoreDataHelper sharedHelper] insertPhoto:photoPath];
                if (isToday) {
                    id reminderTime = [[NSUserDefaults standardUserDefaults] objectForKey:REMINDER_TIME_KEY];
                    if ([reminderTime isKindOfClass:[NSDate class]]) {
                        NSDate *fireDate = [GlobalUtils addToDate:[GlobalUtils HHmmToday:[[GlobalUtils HHmmFormatter] stringFromDate:reminderTime]] days:1];
                        [GlobalUtils setDailyNotification:fireDate];
                    }
                }
                [self renewPhotoCounts];
                DHLogDebug(@"document saved successfully");
            } else {
                [GlobalUtils alertMessage:@"保存图片失败，请检查iCloud账户设置后重试"];
            }
        }];
    }
    
    _specifiedDate = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)renewPhotoCounts {
    NSInteger count = [[CoreDataHelper sharedHelper] countOfPhotos];
    if (count < 0) {
        count = [[NSUbiquitousKeyValueStore defaultStore] longLongForKey:OPUbiquitousKeyValueStoreHasPhotoKey] + 1;
    }
    DHLogDebug(@"renewPhotoCounts: %ld", (long)count);
    [[NSUbiquitousKeyValueStore defaultStore] setLongLong:count forKey:OPUbiquitousKeyValueStoreHasPhotoKey];
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
    
    switch (lOPDayView.touchEvent) {
        case OP_DAY_TOUCH_UP: {
            if (photo) {
                _photos = [[CoreDataHelper sharedHelper] allPhotosSorted];
                
                MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
                browser.displayActionButton = YES;
                browser.displayNavArrows = YES;
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
                    [self newPhotoAction];
                } else {
#ifdef TEST_VERSION
                    _specifiedDate = lOPDayView.date;
                    [self newPhotoAction];
#endif
                }
            }
            break;
        }
        case OP_DAY_TOUCH_DELETE: {
            if (photo) {
                [[CoreDataHelper sharedHelper] deletePhoto:photo];
                id reminderTime = [[NSUserDefaults standardUserDefaults] objectForKey:REMINDER_TIME_KEY];
                if ([reminderTime isKindOfClass:[NSDate class]]) {
                    NSDate *fireDate = [GlobalUtils HHmmToday:[[GlobalUtils HHmmFormatter] stringFromDate:reminderTime]];
                    [GlobalUtils setDailyNotification:fireDate];
                }
                [self renewPhotoCounts];
                [lOPDayView setPhoto:nil];
            }
            break;
        }
        default: {
            break;
        }
    }
}

- (void)newPhotoAction {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"添加新的照片"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* libraryAction = [UIAlertAction actionWithTitle:@"从“照片”中选取" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self startCameraControllerFromViewController:self sourceType:UIImagePickerControllerSourceTypePhotoLibrary usingDelegate:self];
                                                          }];
    UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:@"拍摄一张照片" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self startCameraControllerFromViewController:self sourceType:UIImagePickerControllerSourceTypeCamera usingDelegate:self];
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:libraryAction];
    [alert addAction:cameraAction];
    [alert addAction:cancelAction];
    if([alert respondsToSelector:@selector(popoverPresentationController)]) {
        // iOS8
        alert.popoverPresentationController.barButtonItem = self.addPhotoItem;
    }
    [self presentViewController:alert animated:YES completion:nil];
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
        MWPhoto *mwPhoto = [MWPhoto photoWithURL:ubiquitousURL];
        return mwPhoto;
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
