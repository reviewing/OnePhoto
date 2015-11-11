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
#import <DBCamera/DBCameraViewController.h>
#import <DBCamera/DBCameraContainerViewController.h>

#import <MobileCoreServices/MobileCoreServices.h>

#import "WXApi.h"

#define MAIN_TITLE @"1 Photo"

@interface RootViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MWPhotoBrowserDelegate, DBCameraViewControllerDelegate> {
    MBProgressHUD *_hud;
    NSInteger _callbackCount;
    BOOL _isFirstAppear;
    NSArray *_photos;
    NSDate *_specifiedDate;
    NSDate *_selectedDate;
}

@property (weak, nonatomic) IBOutlet OPCalendarWeekDayView *weekDayView;
@property (weak, nonatomic) IBOutlet OPVerticalCalendarView *calendarContentView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addPhotoItem;

@property (strong, nonatomic) JTCalendarManager *calendarManager;

@property (nonatomic, strong) UIPopoverController *photoPickerPopOver;

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
    if ([IM_JUMPING_TO isEqualToString:@"NewPhotoAction"]) {
        [self newPhotoAction];
        SET_JUMPING(nil, nil);
    } else if ([IM_JUMPING_TO isEqualToString:@"RootViewController"]) {
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
    if ([IM_JUMPING_TO isEqualToString:@"NewPhotoAction"]) {
        [self newPhotoAction];
        SET_JUMPING(nil, nil);
    } else if ([IM_JUMPING_TO isEqualToString:@"RootViewController"]) {
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

- (void)startDBCamera {
    DBCameraViewController *cameraController = [DBCameraViewController initWithDelegate:self];
    [cameraController setForceQuadCrop:YES];
    
    DBCameraContainerViewController *container = [[DBCameraContainerViewController alloc] initWithDelegate:self];
    [container setCameraViewController:cameraController];
    [container setFullScreenMode];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:container];
    [nav setNavigationBarHidden:YES];
    [self presentViewController:nav animated:YES completion:nil];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
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

- (BOOL)popPhotoPickerFromView:(UIView *)view sourceType:(UIImagePickerControllerSourceType) sourceType
                 usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>) delegate {
    if (([UIImagePickerController isSourceTypeAvailable: sourceType] == NO) || (delegate == nil)) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = sourceType;
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *) kUTTypeImage, nil];
    cameraUI.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    cameraUI.allowsEditing = YES;
    cameraUI.delegate = delegate;
    
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:cameraUI];
    if (view) {
        [popover presentPopoverFromRect:view.bounds inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [popover presentPopoverFromBarButtonItem:self.addPhotoItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    self.photoPickerPopOver = popover;
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    return YES;
}


#pragma mark - UIImagePickerController delegate

// For responding to the user tapping Cancel.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *) picker {
    _specifiedDate = nil;
    if ([IM_JUMPING_TO isEqualToString:@"NewPhotoAction"]) {
        SET_JUMPING(nil, nil);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

// For responding to the user accepting a newly-captured picture or movie
- (void)imagePickerController:(UIImagePickerController *) picker didFinishPickingMediaWithInfo:(NSDictionary *) info {
    if ([IM_JUMPING_TO isEqualToString:@"NewPhotoAction"]) {
        SET_JUMPING(nil, nil);
    }

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
        
        [self saveImage:imageToSave shouldSaveToLibrary:NO];
    }
    
    _specifiedDate = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - DBCameraViewControllerDelegate

- (void)dismissCamera:(id)cameraViewController{
    _specifiedDate = nil;
    if ([IM_JUMPING_TO isEqualToString:@"NewPhotoAction"]) {
        SET_JUMPING(nil, nil);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [cameraViewController restoreFullScreenMode];
}

- (void)camera:(id)cameraViewController didFinishWithImage:(UIImage *)image withMetadata:(NSDictionary *)metadata
{
    if ([IM_JUMPING_TO isEqualToString:@"NewPhotoAction"]) {
        SET_JUMPING(nil, nil);
    }

    [self saveImage:image shouldSaveToLibrary:YES];
    [cameraViewController restoreFullScreenMode];
    _specifiedDate = nil;
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveImage:(UIImage *)image shouldSaveToLibrary:(BOOL)saveToLibrary {
    NSString *dateString = [GlobalUtils stringFromDate:_specifiedDate ? _specifiedDate : [NSDate date]];
    NSString *photoPath = [@"photos" stringByAppendingPathComponent:[[dateString stringByAppendingString:[[[NSUUID UUID] UUIDString] substringToIndex:8]] stringByAppendingPathExtension:@"jpg"]];
    
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:photoPath];
    
    OPPhotoCloud *photoCloud = [[OPPhotoCloud alloc] initWithFileURL:ubiquitousURL];
    photoCloud.imageData = UIImageJPEGRepresentation(image, 0.8);
    
    if (saveToLibrary && BOOL_FOR_KEY(DEFAULTS_KEY_SAVE_TO_LIBRARY)) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    
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

- (void)renewPhotoCounts {
    NSInteger count = [[CoreDataHelper sharedHelper] countOfPhotos];
    if (count < 0) {
        count = (NSInteger)[[NSUbiquitousKeyValueStore defaultStore] longLongForKey:OPUbiquitousKeyValueStoreHasPhotoKey] + 1;
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
    // Selected
    else if(_selectedDate && [_calendarManager.dateHelper date:_selectedDate isTheSameDayThan:dayView.date]){
        dayView.layer.borderColor = [[GlobalUtils daySelectionColor] CGColor];
        dayView.layer.borderWidth = 2;
    }
    // Today
    else if([_calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:dayView.date]){
        dayView.layer.borderColor = [[GlobalUtils appBaseColor] CGColor];
        dayView.layer.borderWidth = 2;
    } else {
        dayView.layer.borderColor = [[UIColor clearColor] CGColor];
        dayView.layer.borderWidth = 0;
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(UIView<JTCalendarDay> *)dayView {
    OPCalendarDayView *lOPDayView = (OPCalendarDayView *)dayView;
    
    if (_selectedDate == nil || ![_calendarManager.dateHelper date:_selectedDate isTheSameDayThan:dayView.date]) {
        _selectedDate = dayView.date;
        [self.calendarContentView reloadData];
    }
    
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
                    [self newPhotoAction:lOPDayView];
                } else {
#ifdef TEST_VERSION
                    _specifiedDate = lOPDayView.date;
                    [self newPhotoAction:lOPDayView];
#endif
                }
            }
            break;
        }
        case OP_DAY_TOUCH_DELETE: {
            if (photo) {
                [self deletePhotoActionFrom:self anchor:lOPDayView photo:photo completion:^(){
                    [lOPDayView setPhoto:nil];
                }];
            }
            break;
        }
        default: {
            break;
        }
    }
}

- (void)newPhotoAction {
    [self newPhotoAction:nil];
}

- (void)newPhotoAction:(OPCalendarDayView *)dayView {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"添加新的照片"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* libraryAction = [UIAlertAction actionWithTitle:@"从“照片”中选取" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                                                                  [self popPhotoPickerFromView:dayView sourceType:UIImagePickerControllerSourceTypePhotoLibrary usingDelegate:self];
                                                              } else {
                                                                  [self startCameraControllerFromViewController:self sourceType:UIImagePickerControllerSourceTypePhotoLibrary usingDelegate:self];
                                                              }
                                                          }];
    UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:@"拍摄一张照片" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [self startDBCamera];
                                                         }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:libraryAction];
    [alert addAction:cameraAction];
    [alert addAction:cancelAction];
    if([alert respondsToSelector:@selector(popoverPresentationController)]) {
        // iOS8
        if (dayView) {
            alert.popoverPresentationController.sourceView = dayView;
        } else {
            alert.popoverPresentationController.barButtonItem = self.addPhotoItem;
        }
    }
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deletePhotoActionFrom:(UIViewController *)viewController anchor:(NSObject *)anchor photo:(OPPhoto *)photo completion:(void (^)(void))completion {
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * action) {
                                                             [[CoreDataHelper sharedHelper] deletePhoto:photo];
                                                             id reminderTime = [[NSUserDefaults standardUserDefaults] objectForKey:REMINDER_TIME_KEY];
                                                             if ([reminderTime isKindOfClass:[NSDate class]]) {
                                                                 NSDate *fireDate = [GlobalUtils HHmmToday:[[GlobalUtils HHmmFormatter] stringFromDate:reminderTime]];
                                                                 [GlobalUtils setDailyNotification:fireDate];
                                                             }
                                                             [self renewPhotoCounts];
                                                             completion();
                                                         }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];
    
    [self presentActionSheetFrom:viewController title:@"删除照片" message:@"警告：删除后不可恢复" actions:[NSArray arrayWithObjects:deleteAction, cancelAction, nil] anchor:anchor];
}

- (void)sharePhotoAction:(UIViewController *)viewController anchor:(NSObject *)anchor photo:(OPPhoto *)photo {
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:photo.source_image_url];

    UIAlertAction* weixinAction = [UIAlertAction actionWithTitle:@"分享给微信朋友" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             if ([WXApi isWXAppInstalled]) {
                                                                 [self sendImageData:[NSData dataWithContentsOfURL:ubiquitousURL]
                                                                             TagName:@"WECHAT_TAG_JUMP_APP"
                                                                          MessageExt:@"1 Photo"
                                                                              Action:@"<action>open</action>"
                                                                          ThumbImage:[GlobalUtils squareAndSmall:[UIImage imageWithContentsOfFile:ubiquitousURL.path]]
                                                                             InScene:WXSceneSession];
                                                             } else {
                                                                 UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel
                                                                                                                      handler:^(UIAlertAction * action) {}];
                                                                 [self presentAlertFrom:viewController title:@"无法打开微信" message:@"未检测到微信，请确认是否安装了微信" actions:[NSArray arrayWithObject:cancelAction]];
                                                             }
                                                        }];
    UIAlertAction* weixinFCAction = [UIAlertAction actionWithTitle:@"分享到微信朋友圈" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             if ([WXApi isWXAppInstalled]) {
                                                                 [self sendImageData:[NSData dataWithContentsOfURL:ubiquitousURL]
                                                                             TagName:@"WECHAT_TAG_JUMP_APP"
                                                                          MessageExt:@"1 Photo"
                                                                              Action:@"<action>open</action>"
                                                                          ThumbImage:[GlobalUtils squareAndSmall:[UIImage imageWithContentsOfFile:ubiquitousURL.path]]
                                                                             InScene:WXSceneTimeline];
                                                             } else {
                                                                 UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel
                                                                                                                      handler:^(UIAlertAction * action) {}];
                                                                 [self presentAlertFrom:viewController title:@"无法打开微信" message:@"未检测到微信，请确认是否安装了微信" actions:[NSArray arrayWithObject:cancelAction]];
                                                             }
                                                         }];
    UIAlertAction* systemAction = [UIAlertAction actionWithTitle:@"其它操作" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             if ([viewController respondsToSelector:@selector(showProgressHUDWithMessage:)]) {
                                                                 [viewController performSelector:@selector(showProgressHUDWithMessage:) withObject:nil];
                                                             }
                                                             NSMutableArray *items = [NSMutableArray arrayWithObject:[UIImage imageWithContentsOfFile:ubiquitousURL.path]];
                                                             __block UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
                                                             
                                                             activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                                                                 activityViewController = nil;
                                                             };
                                                             if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
                                                                 if ([anchor isKindOfClass:[UIView class]]) {
                                                                     activityViewController.popoverPresentationController.sourceView = (UIView *)anchor;
                                                                 } else if ([anchor isKindOfClass:[UIBarButtonItem class]]) {
                                                                     activityViewController.popoverPresentationController.barButtonItem = (UIBarButtonItem *)anchor;
                                                                 }
                                                             }
                                                             [viewController presentViewController:activityViewController animated:YES completion:^(){
                                                                 if ([viewController respondsToSelector:@selector(hideProgressHUD:)]) {
                                                                     [viewController performSelector:@selector(hideProgressHUD:) withObject:@YES];
                                                                 }
                                                             }];

                                                         }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {}];

    [self presentActionSheetFrom:viewController title:@"分享照片" message:@"" actions:[NSArray arrayWithObjects:weixinAction, weixinFCAction, systemAction, cancelAction, nil] anchor:anchor];
}

- (void)presentAlertFrom:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message actions:(NSArray *)actions {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    for (UIAlertAction *action in actions) {
        [alert addAction:action];
    }
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)presentActionSheetFrom:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message actions:(NSArray *)actions anchor:(NSObject *)anchor {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    for (UIAlertAction *action in actions) {
        [alert addAction:action];
    }
    
    if([alert respondsToSelector:@selector(popoverPresentationController)]) {
        if ([anchor isKindOfClass:[UIView class]]) {
            alert.popoverPresentationController.sourceView = (UIView *)anchor;
        } else if ([anchor isKindOfClass:[UIBarButtonItem class]]) {
            alert.popoverPresentationController.barButtonItem = (UIBarButtonItem *)anchor;
        }
    }
    
    [viewController presentViewController:alert animated:YES completion:nil];
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
    OPPhoto *displayedPhoto = [_photos objectAtIndex:index];
    _selectedDate = [[GlobalUtils dateFormatter] dateFromString:displayedPhoto.dateString];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser trashButtonPressedForPhotoAtIndex:(NSUInteger)index {
    UIBarButtonItem *trashButton = [photoBrowser valueForKey:@"_trashButton"];
    [self deletePhotoActionFrom:photoBrowser anchor:trashButton photo:[_photos objectAtIndex:index] completion:^(){
        _photos = [[CoreDataHelper sharedHelper] allPhotosSorted];
        if (index >= [_photos count]) {
            [photoBrowser setCurrentPhotoIndex:[_photos count] - 1];
        }
        [photoBrowser reloadData];
    }];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    OPPhoto *photo = [_photos objectAtIndex:index];
    NSObject *anchor;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
        anchor = [photoBrowser valueForKey:@"_actionButton"];
    }
    [self sharePhotoAction:photoBrowser anchor:anchor photo:photo];
}

- (BOOL)sendImageData:(NSData *)imageData
              TagName:(NSString *)tagName
           MessageExt:(NSString *)messageExt
               Action:(NSString *)action
           ThumbImage:(UIImage *)thumbImage
              InScene:(enum WXScene)scene {
    WXImageObject *ext = [WXImageObject object];
    ext.imageData = imageData;
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = nil;
    message.description = nil;
    message.mediaObject = ext;
    message.messageExt = messageExt;
    message.messageAction = action;
    message.mediaTagName = tagName;
    [message setThumbImage:thumbImage];
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.scene = scene;
    req.message = message;

    return [WXApi sendReq:req];
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
