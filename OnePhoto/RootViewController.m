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
#import "iCloudAccessor.h"
#import "MultiPhotoViewer.h"
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
    
    MultiPhotoViewer *_multiPhotoView;
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
    
    if (IDIOM != IPAD) {
        _calendarContentView.backgroundView = nil;
        _calendarContentView.backgroundColor = UIColorFromRGBA(0xeeeeeecf);
    }
    
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
                                             selector:@selector(coreDataStoreUpdated:)
                                                 name:OPCoreDataStoreUpdatedNotification
                                               object:nil];
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
    if (_isFirstAppear) {
        _isFirstAppear = NO;
        [_calendarContentView scrollToCurrentMonth:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_hud hide:YES];
}

- (void)coreDataStoreUpdated:(NSNotification *)notification {
    DHLogDebug(@"OPCoreDataStoreUpdatedNotification");
    [self.calendarContentView reloadData];
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
    [self buildFastImageCache];
}

#pragma mark - Actions
- (IBAction)setting:(id)sender {
}

- (IBAction)takePhoto:(id)sender {
    _selectedDate = [NSDate date];
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
    
    BOOL success = YES;
    
    // Handle a still image capture
    if (CFStringCompare((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        
        editedImage = (UIImage *) [info objectForKey: UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
        
        if (editedImage) {
            imageToSave = editedImage;
        } else {
            imageToSave = originalImage;
        }
        
        success = [self saveImage:imageToSave shouldSaveToLibrary:NO];
    }
    
    _specifiedDate = nil;
    [self dismissViewControllerAnimated:YES completion:^(){
        if (!success) {
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {}];
            [GlobalUtils presentAlertFrom:self title:@"发生错误" message:@"该设备没有设置iCloud账户，无法保存图片，请在登录iCloud后重试" actions:[NSArray arrayWithObject:cancelAction]];
        }
    }];
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

    BOOL success = [self saveImage:image shouldSaveToLibrary:YES];
    [cameraViewController restoreFullScreenMode];
    _specifiedDate = nil;
    [self.presentedViewController dismissViewControllerAnimated:YES completion:^(){
        if (!success) {
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {}];
            [GlobalUtils presentAlertFrom:self title:@"发生错误" message:@"该设备没有设置iCloud账户，无法保存图片，请在登录iCloud后重试" actions:[NSArray arrayWithObject:cancelAction]];
        }
    }];
}

- (BOOL)saveImage:(UIImage *)image shouldSaveToLibrary:(BOOL)saveToLibrary {
    NSString *dateString = [GlobalUtils stringFromDate:_specifiedDate ? _specifiedDate : [NSDate date]];
    NSString *photoPath = [@"photos" stringByAppendingPathComponent:[[dateString stringByAppendingString:[[[NSUUID UUID] UUIDString] substringToIndex:8]] stringByAppendingPathExtension:@"jpg"]];
    
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    NSURL *ubiquitousURL = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:photoPath];
    
    if (ubiquitousURL == nil) {
        return NO;
    }
    
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
                id reminderTime = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_REMINDER_TIME];
                if ([reminderTime isKindOfClass:[NSDate class]]) {
                    NSDate *fireDate = [GlobalUtils addToDate:[GlobalUtils HHmmToday:[[GlobalUtils HHmmFormatter] stringFromDate:reminderTime]] days:1];
                    [GlobalUtils setDailyNotification:fireDate];
                }
            }
            [GlobalUtils renewPhotoCounts];
            DHLogDebug(@"document saved successfully");
        } else {
            [GlobalUtils alertMessage:@"保存图片失败，请检查iCloud账户设置后重试"];
        }
        [photoCloud closeWithCompletionHandler:^(BOOL success) {
            if (success) {
                DHLogDebug(@"iCloud document closed");
            } else {
                DHLogDebug(@"failed closing document from iCloud");
            }
        }];
    }];
    
    return YES;
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
    dayView.layer.borderColor = [[UIColor clearColor] CGColor];
    dayView.layer.borderWidth = 0;
    ((OPCalendarDayView *)dayView).dayLabelBG.backgroundColor = [[GlobalUtils appBaseColor] colorWithAlphaComponent:0.75];

    if ([dayView isFromAnotherMonth]) {
        dayView.hidden = YES;
    } else if ([dayView.date compare:[NSDate date]] == NSOrderedDescending) {
        dayView.hidden = YES;
    }
    // Selected
    else if(_selectedDate && [_calendarManager.dateHelper date:_selectedDate isTheSameDayThan:dayView.date]){
        dayView.layer.borderColor = [[GlobalUtils daySelectionColor] CGColor];
        dayView.layer.borderWidth = 1;
        ((OPCalendarDayView *)dayView).dayLabelBG.backgroundColor = [[GlobalUtils daySelectionColor] colorWithAlphaComponent:0.75];
    }
    // Today
    else if([_calendarManager.dateHelper date:[NSDate date] isTheSameDayThan:dayView.date]){

    } else {
    
    }
}

- (void)calendar:(JTCalendarManager *)calendar didTouchDayView:(UIView<JTCalendarDay> *)dayView {
    OPCalendarDayView *lOPDayView = (OPCalendarDayView *)dayView;
    
    if (_selectedDate == nil || ![_calendarManager.dateHelper date:_selectedDate isTheSameDayThan:dayView.date]) {
        _selectedDate = dayView.date;
        [self.calendarContentView reloadData];
    }
    
    OPPhoto *photo = [lOPDayView photo];
    
    switch (lOPDayView.touchEvent) {
        case OP_DAY_TOUCH_UP: {
            if (!lOPDayView.markerView.hidden) {
                NSString *dateString = [[GlobalUtils dateFormatter] stringFromDate:lOPDayView.date];
                _multiPhotoView = [[MultiPhotoViewer alloc] initWithHost:self
                                                                    date:dateString
                                                                selected:photo.source_image_url
                                                                coreData:[[CoreDataHelper sharedHelper] getPhotosAt:dateString]
                                                                  iCloud:[[iCloudAccessor shareAccessor] urlsAt:dateString]];
                MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:_multiPhotoView];
                browser.displayActionButton = YES;
                browser.displayNavArrows = YES;
                browser.alwaysShowControls = YES;
                browser.zoomPhotosToFill = YES;
                
                [browser showNextPhotoAnimated:YES];
                [browser showPreviousPhotoAnimated:YES];
                [browser setCurrentPhotoIndex:0];

                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
                nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                [self presentViewController:nc animated:YES completion:nil];

                break;
            }
            
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
                [GlobalUtils deletePhotoActionFrom:self anchor:lOPDayView photo:photo completion:^(){
                    [lOPDayView setPhoto:nil];
                    [self.calendarContentView reloadData];
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
    [GlobalUtils deletePhotoActionFrom:photoBrowser anchor:trashButton photo:[_photos objectAtIndex:index] completion:^(){
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
    [GlobalUtils sharePhotoAction:photoBrowser anchor:anchor photo:photo];
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
