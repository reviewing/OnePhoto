//
//  AppDelegate.m
//  OnePhoto
//
//  Created by Hong Duan on 8/27/15.
//  Copyright (c) 2015 Hong D. Empire. All rights reserved.
//

#import "AppDelegate.h"
#import <FastImageCache/FICImageCache.h>
#import <VENTouchLock/VENTouchLock.h>
#import "OPPhoto.h"
#import "CoreDataHelper.h"
#import "RootViewController.h"
#import "SettingsViewController.h"
#import "LockSplashViewController.h"

@interface AppDelegate () <FICImageCacheDelegate>

@property (strong, nonatomic) UIView *snapshotView;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[VENTouchLock sharedInstance] setKeychainService:@"OnePhoto"
                                      keychainAccount:@"OnePhoto"
                                        touchIDReason:@"解锁1 Photo"
                                 passcodeAttemptLimit:5
                            splashViewControllerClass:[LockSplashViewController class]];
    
    [GlobalUtils setupNotificationSettings];
    
    [VENTouchLock sharedInstance].appearance.passcodeViewControllerTitleColor = [UIColor lightTextColor];
    [VENTouchLock sharedInstance].appearance.passcodeViewControllerCharacterColor = [UIColor whiteColor];
    [VENTouchLock sharedInstance].appearance.passcodeViewControllerBackgroundColor = [UIColor darkGrayColor];
    [VENTouchLock sharedInstance].appearance.cancelBarButtonItemTitle = @"取消";
    [VENTouchLock sharedInstance].appearance.createPasscodeInitialLabelText = @"请输入密码";
    [VENTouchLock sharedInstance].appearance.createPasscodeConfirmLabelText = @"请重复输入一次密码";
    [VENTouchLock sharedInstance].appearance.createPasscodeMismatchedLabelText = @"两次密码输入不一致，请重新设置";
    [VENTouchLock sharedInstance].appearance.createPasscodeViewControllerTitle = @"设置密码";
    [VENTouchLock sharedInstance].appearance.enterPasscodeInitialLabelText = @"请输入密码";
    [VENTouchLock sharedInstance].appearance.enterPasscodeIncorrectLabelText = @"密码错误，请重试";
    [VENTouchLock sharedInstance].appearance.enterPasscodeViewControllerTitle = @"输入密码";
    [VENTouchLock sharedInstance].appearance.touchIDCancelPresentsPasscodeViewController = YES;

    [DHLogger setLogLevel:DH_LOG_DEBUG];

    if ((DHLogLevel)[[NSUserDefaults standardUserDefaults] integerForKey:@"debug.level"] == DH_LOG_VERBOSE) {
        [MobClick setLogEnabled:YES];
    } else {
        [MobClick setLogEnabled:NO];
    }
    [MobClick startWithAppkey:@"5628a669e0f55a25c5000386" reportPolicy:BATCH channelId:@"iOS"];
    
    OPPhotoSquareImageSize = CGSizeMake([UIScreen mainScreen].bounds.size.width / 7.f, [UIScreen mainScreen].bounds.size.width / 7.f);
    
    NSMutableArray *mutableImageFormats = [NSMutableArray array];
    
    // Square image formats...
    NSInteger squareImageFormatMaximumCount = 400;
    FICImageFormatDevices squareImageFormatDevices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    
    // ...32-bit BGR
    FICImageFormat *squareImageFormat32BitBGR = [FICImageFormat formatWithName:OPPhotoSquareImage32BitBGRFormatName family:OPPhotoImageFormatFamily imageSize:OPPhotoSquareImageSize style:FICImageFormatStyle32BitBGR maximumCount:squareImageFormatMaximumCount devices:squareImageFormatDevices protectionMode:FICImageFormatProtectionModeNone];
    
    [mutableImageFormats addObject:squareImageFormat32BitBGR];
    
    if ([UIViewController instancesRespondToSelector:@selector(preferredStatusBarStyle)]) {
        // Pixel image format
        NSInteger pixelImageFormatMaximumCount = 1000;
        FICImageFormatDevices pixelImageFormatDevices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
        
        FICImageFormat *pixelImageFormat = [FICImageFormat formatWithName:OPPhotoPixelImageFormatName family:OPPhotoImageFormatFamily imageSize:OPPhotoPixelImageSize style:FICImageFormatStyle32BitBGR maximumCount:pixelImageFormatMaximumCount devices:pixelImageFormatDevices protectionMode:FICImageFormatProtectionModeNone];
        
        [mutableImageFormats addObject:pixelImageFormat];
    }
    
    // Configure the image cache
    FICImageCache *sharedImageCache = [FICImageCache sharedImageCache];
    [sharedImageCache setDelegate:self];
    [sharedImageCache setFormats:mutableImageFormats];
    
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if (ubiq) {
        DHLogDebug(@"iCloud access at %@", ubiq);
        NSURL *photoFolder = [[ubiq URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:@"photos"];
        
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtURL:photoFolder withIntermediateDirectories:YES attributes:nil error:&error];
        if(error) {
            DHLogError(@"Error createDirectoryAtURL");
        } else {
            DHLogDebug(@"createDirectoryAtURL succeed");
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"photos.dir.created"];
        }
    }
    
    // 初始化默认设置
    NSString *settingsPlist = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    for (NSDictionary *section in [NSArray arrayWithContentsOfFile:settingsPlist]) {
        for (NSDictionary *dic in [section objectForKey:@"items"]) {
            if ([dic objectForKey:@"default"]) {
                [defaults setObject:[dic objectForKey:@"default"] forKey:[dic objectForKey:@"key"]];
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[[VENTouchLock sharedInstance] isPasscodeSet]] forKey:@"enable.passcode"];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    
    UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (notification) {
        application.applicationIconBadgeNumber = 0;
        [self application:application didReceiveLocalNotification:notification];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                                      object:self.managedObjectContext.persistentStoreCoordinator
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      DHLogDebug(@"NSPersistentStoreCoordinatorStoresWillChangeNotification");
                                                      [self.managedObjectContext performBlock:^{
                                                          if ([self.managedObjectContext hasChanges]) {
                                                              NSError *saveError;
                                                              if (![self.managedObjectContext save:&saveError]) {
                                                                  NSLog(@"Save error: %@", saveError);
                                                              }
                                                          } else {
                                                              // drop any managed object references
                                                              [self.managedObjectContext reset];
                                                          }
                                                      }];
                                                      // drop any managed object references
                                                      // disable user interface with setEnabled: or an overlay
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                                      object:self.managedObjectContext.persistentStoreCoordinator
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      DHLogDebug(@"NSPersistentStoreCoordinatorStoresDidChangeNotification: %@", [note.userInfo objectForKey:NSAddedPersistentStoresKey]);
                                                      [self.managedObjectContext performBlock:^{
                                                          [self.managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                                                          dispatch_async(dispatch_get_main_queue(), ^(){
                                                              [[NSNotificationCenter defaultCenter] postNotificationName:OPCoreDataStoreMerged object:nil];
                                                              [[CoreDataHelper sharedHelper] cacheNewDataForAppGroup];
                                                          });
                                                      }];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                      object:self.managedObjectContext.persistentStoreCoordinator
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      DHLogDebug(@"NSPersistentStoreDidImportUbiquitousContentChangesNotification");
                                                      [self.managedObjectContext performBlock:^{
                                                          [self.managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                                                          dispatch_async(dispatch_get_main_queue(), ^(){
                                                              [[NSNotificationCenter defaultCenter] postNotificationName:OPCoreDataStoreMerged object:nil];
                                                              [[CoreDataHelper sharedHelper] cacheNewDataForAppGroup];
                                                          });
                                                      }];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationSignificantTimeChange:)
                                                 name:UIApplicationSignificantTimeChangeNotification
                                               object:nil];
    [[CoreDataHelper sharedHelper] cacheNewDataForAppGroup];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (BOOL_FOR_KEY(DEFAULTS_KEY_ENABLE_PASSCODE)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        VENTouchLockSplashViewController *snapshotSplashViewController = [[LockSplashViewController alloc] init];
        [snapshotSplashViewController setIsSnapshotViewController:YES];
        UIViewController *snapshotDisplayController;
        snapshotDisplayController = snapshotSplashViewController;
        [snapshotDisplayController loadView];
        [snapshotDisplayController viewDidLoad];
        UIWindow *mainWindow = [[UIApplication sharedApplication].windows firstObject];
        snapshotDisplayController.view.frame = mainWindow.bounds;
        self.snapshotView = snapshotDisplayController.view;
        [mainWindow addSubview:self.snapshotView];

        if (INTEGER_FOR_KEY(DEFAULTS_KEY_PASSCODE_TIME) == 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[VENTouchLock sharedInstance] lock];
            });
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:DEFAULTS_KEY_LAST_BACKGROUND_TIME];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.snapshotView removeFromSuperview];
        self.snapshotView = nil;
    });
    
    if (BOOL_FOR_KEY(DEFAULTS_KEY_ENABLE_PASSCODE)) {
        if (!OBJECT_FOR_KEY(DEFAULTS_KEY_LAST_BACKGROUND_TIME)) {
            [[VENTouchLock sharedInstance] lock];
        } else if (INTEGER_FOR_KEY(DEFAULTS_KEY_PASSCODE_TIME) != 0) {
            NSDate *lastBackgroundTime = OBJECT_FOR_KEY(DEFAULTS_KEY_LAST_BACKGROUND_TIME);
            if ([[NSDate date] timeIntervalSinceDate:lastBackgroundTime] >= INTEGER_FOR_KEY(DEFAULTS_KEY_PASSCODE_TIME) * 60) {
                [[VENTouchLock sharedInstance] lock];
            }
        }
    }
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:DEFAULTS_KEY_LAST_BACKGROUND_TIME];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSURL *ubiq = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
    if (!ubiq) {
        DHLogError(@"No iCloud access");
        [GlobalUtils alertMessage:@"该设备没有设置iCloud账户，无法正常使用1 Photo，请在登录iCloud后重试"];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
    [[CoreDataHelper sharedHelper] cacheNewDataForAppGroup];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notif {
    application.applicationIconBadgeNumber = 0;
    if ([[notif.userInfo objectForKey:OPNotificationType] isEqualToString:OPNotificationTypeDailyReminder]) {
        if (application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground) {
            [self redirectBasedOnAction:@"add"];
        } else {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"每日提醒"
                                                                           message:@"现在拍下今天的1 Photo？"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* cameraAction = [UIAlertAction actionWithTitle:@"现在就去" style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * action) {
                                                                     [self redirectBasedOnAction:@"add"];
                                                                 }];
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"不用了" style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {}];
            
            [alert addAction:cameraAction];
            [alert addAction:cancelAction];
            
            [[GlobalUtils topMostController] presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {
    if ([identifier isEqualToString:@"ignore.1photo"]) {
        application.applicationIconBadgeNumber = 0;
    } else if ([identifier isEqualToString:@"add.1photo"]) {
        [self redirectBasedOnAction:@"add"];
    }
    
    completionHandler();
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    DHLogDebug(@"url recieved: %@", url);
    NSString *action = [[self parseQueryString:[url query]] objectForKey:@"action"];
    [self redirectBasedOnAction:action];
    return YES;
}

- (void)redirectBasedOnAction:(NSString *)action {
    if (![[VENTouchLock sharedInstance] isPasscodeSet]) {
        if ([action isEqualToString:@"add"]) {
            UIViewController *topController = [GlobalUtils topMostController];
            if ([topController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)topController).visibleViewController isKindOfClass:[RootViewController class]]) {
                [((RootViewController *)((UINavigationController *)topController).visibleViewController) performSelector:@selector(newPhotoAction)];
            } else {
                SET_JUMPING(@"NewPhotoAction", @"");
                [GlobalUtils popToRootOrAfterPop:[SettingBaseViewController class]];
            }
        } else if ([action isEqualToString:@"open"]) {
            UIViewController *topController = [GlobalUtils topMostController];
            if ([topController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)topController).visibleViewController isKindOfClass:[RootViewController class]]) {
                
            } else {
                SET_JUMPING(@"RootViewController", @"");
                [GlobalUtils popToRootOrAfterPop:[SettingBaseViewController class]];
            }
        }
    } else {
        if ([action isEqualToString:@"add"]) {
            SET_JUMPING(@"NewPhotoAction", @"");
        } else if ([action isEqualToString:@"open"]) {
            SET_JUMPING(@"RootViewController", @"");
        }
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            [GlobalUtils popToRootOrAfterPop:[SettingBaseViewController class]];
            UIViewController *topController = [GlobalUtils topMostController];
            if ([topController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)topController).visibleViewController isKindOfClass:[RootViewController class]]) {
                [((RootViewController *)((UINavigationController *)topController).visibleViewController) performSelector:@selector(newPhotoAction)];
                SET_JUMPING(nil, nil);
            }
        }
    }
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "top.defaults.OnePhoto" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"OnePhoto" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OnePhoto.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, @"OnePhotoCloudStore", NSPersistentStoreUbiquitousContentNameKey, nil];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"OPPHOTO_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        DHLogError(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            DHLogError(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - FICImageCacheDelegate

- (void)imageCache:(FICImageCache *)imageCache wantsSourceImageForEntity:(id<FICEntity>)entity withFormatName:(NSString *)formatName completionBlock:(FICImageRequestCompletionBlock)completionBlock {
    // Images typically come from the Internet rather than from the app bundle directly, so this would be the place to fire off a network request to download the image.
    // For the purposes of this demo app, we'll just access images stored locally on disk.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *sourceImage = [(OPPhoto *)entity sourceImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(sourceImage);
        });
    });
}

- (BOOL)imageCache:(FICImageCache *)imageCache shouldProcessAllFormatsInFamily:(NSString *)formatFamily forEntity:(id<FICEntity>)entity {
    return NO;
}

- (void)imageCache:(FICImageCache *)imageCache errorDidOccurWithMessage:(NSString *)errorMessage {
    DHLogError(@"%@", errorMessage);
}

@end
