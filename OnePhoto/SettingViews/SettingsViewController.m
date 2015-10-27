//
//  SettingsViewController.m
//  VoiceDemo
//
//  Created by Hong Duan on 7/15/15.
//  Copyright (c) 2015 1 Photo. All rights reserved.
//

#import "SettingsViewController.h"
#import "EditTextViewController.h"
#import "ValueSelectorViewController.h"

@interface SettingsViewController () {
    NSArray *_settingsDefaultArray;
    NSArray *_settings;
    
    UIActionSheet *_signOutAction;
}

@end

@implementation SettingsViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    NSString *settingsPlist = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
    _settingsDefaultArray = [NSArray arrayWithContentsOfFile:settingsPlist];
    _settings = [self stretchSettings:_settingsDefaultArray];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    
}

#pragma mark - Navigation

- (IBAction)back:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SetText"]) {
        UITableViewCell *cell = (UITableViewCell *)sender;
        EditTextViewController *etvc = (EditTextViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        etvc.setting = [[[_settings objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];

        NSString *key = [self objectForKey:@"key" atIndexPath:indexPath];
        [GlobalUtils newEvent:@"setting_set_text" type:key];
    } else if ([segue.identifier isEqualToString:@"SelectValue"]) {
        UITableViewCell *cell = (UITableViewCell *)sender;
        ValueSelectorViewController *vsvc = (ValueSelectorViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        vsvc.setting = [[[_settings objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
        
        NSString *key = [self objectForKey:@"key" atIndexPath:indexPath];
        [GlobalUtils newEvent:@"setting_select_value" type:key];
    }
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_settings count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[_settings objectAtIndex:section] objectForKey:@"items"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_settings objectAtIndex:section] objectForKey:@"groupname"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *boolCellIdentifier = @"BOOLCell";
    static NSString *constantCellIdentifier = @"ConstantCell";
    static NSString *textCellIdentifier = @"TextCell";
    static NSString *arrayCellIdentifier = @"ArrayCell";
    static NSString *userCellIdentifier = @"UserCell";
    static NSString *actionCellIdentifier = @"ActionCell";
    static NSString *rightDetailCellIdentifier = @"RightDetailCell";

    NSString *type = [self objectForKey:@"type" atIndexPath:indexPath];
    NSString *cellIdentifier = @"DefaultCell";
    if ([type isEqualToString:@"BOOL"]) {
        cellIdentifier = boolCellIdentifier;
    } else if ([type isEqualToString:@"Constant"]) {
        cellIdentifier = constantCellIdentifier;
    } else if ([type isEqualToString:@"String"] || [type isEqualToString:@"Number"]) {
        cellIdentifier = textCellIdentifier;
    } else if ([type isEqualToString:@"Array"]) {
        cellIdentifier = arrayCellIdentifier;
    } else if ([type isEqualToString:@"User"]) {
        cellIdentifier = userCellIdentifier;
    } else if ([type isEqualToString:@"Action"]) {
        cellIdentifier = actionCellIdentifier;
    } else if ([type isEqualToString:@"SubPage"]) {
        cellIdentifier = rightDetailCellIdentifier;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    if ([type isEqualToString:@"BOOL"]) {
        UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchView.on = [[NSUserDefaults standardUserDefaults] boolForKey:[self objectForKey:@"key" atIndexPath:indexPath]];
        [switchView addTarget:self action:@selector(switchP:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = switchView;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if ([type isEqualToString:@"Constant"]) {
        SuppressPerformSelectorLeakWarning(
            cell.detailTextLabel.text = [self performSelector:NSSelectorFromString([self objectForKey:@"selector" atIndexPath:indexPath])];
        );
    } else if ([type isEqualToString:@"String"] || [type isEqualToString:@"Number"]) {
        cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] stringForKey:[self objectForKey:@"key" atIndexPath:indexPath]];
    } else if ([type isEqualToString:@"Array"]) {
        NSArray *values = [self objectForKey:@"values" atIndexPath:indexPath];
        NSArray *valuesDescription = [self objectForKey:@"values.description" atIndexPath:indexPath];
        NSInteger index = [values indexOfObject:[[NSUserDefaults standardUserDefaults] objectForKey:[self objectForKey:@"key" atIndexPath:indexPath]]];
        if ([[valuesDescription objectAtIndex:index] length] > 0) {
            cell.detailTextLabel.text = [valuesDescription objectAtIndex:index];
        } else {
            cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] stringForKey:[self objectForKey:@"key" atIndexPath:indexPath]];
        }
    } else if ([type isEqualToString:@"User"]) {
        NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:[self objectForKey:@"key" atIndexPath:indexPath]];
        if (!user) {
            user = @"*!点击登录";
        }
        cell.detailTextLabel.text = user;
    } else if ([type isEqualToString:@"Action"]) {
        // NOTHING
    } else if ([type isEqualToString:@"SubPage"]) {
        cell.detailTextLabel.text = [self getDetailForSubPage:[self objectForKey:@"key" atIndexPath:indexPath]];
    }
    
    cell.textLabel.text = [self objectForKey:@"name" atIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *type = [self objectForKey:@"type" atIndexPath:indexPath];
    NSString *key = [self objectForKey:@"key" atIndexPath:indexPath];
    if ([type isEqualToString:@"User"]) {
        NSString *user = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        if (!user) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            [self signOutAction];
        }
    } else if ([type isEqualToString:@"Action"]) {
        [self signOutAction];
    } else if ([type isEqualToString:@"SubPage"]) {
        if ([key isEqualToString:REMINDER_TIME_KEY]) {
            if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
                [self performSegueWithIdentifier:@"ReminderSegue" sender:nil];
            } else {
                [GlobalUtils alertMessage:@"1 Photo的通知已被禁用，请于iOS设置中打开"];
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)signOutAction {
    _signOutAction = [[UIActionSheet alloc] initWithTitle:@"注销当前用户" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"退出登录" otherButtonTitles: nil];
    [_signOutAction showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [GlobalUtils newEvent:@"user_sign_out"];

        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"usrid"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (NSString *)getDetailForSubPage:(NSString *)key {
    if ([key isEqualToString:REMINDER_TIME_KEY]) {
        if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:key]) {
                return [[GlobalUtils HHmmFormatter] stringFromDate:[[NSUserDefaults standardUserDefaults] objectForKey:key]];
            } else {
                return @"未设置";
            }
        } else {
            return @"未设置";
        }
    }
    return key;
}

#pragma mark - Access Defaults

- (void)switchP:(UISwitch *)sender {
    UITableViewCell *cell = (UITableViewCell *) sender.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSString *key = [self objectForKey:@"key" atIndexPath:indexPath];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:sender.on] forKey:key];
    
    NSDictionary *dict = @{@"type" : key, @"value" : sender.on ? @"YES" : @"NO"};
    [GlobalUtils newEvent:@"setting_switch" attributes:dict];
    
    if ([key isEqualToString:@"write.data.to.file"]) {
        [DHLogger setWriteDataToFile:sender.on];
    }
    BOOL isDepended = [[self objectForKey:@"depended" atIndexPath:indexPath] boolValue];
    if (isDepended) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _settings = [self stretchSettings:_settingsDefaultArray];
            [self.tableView reloadData];
        });
    }
}

- (NSArray *)stretchSettings:(NSArray *)settings {
    return settings;
}

- (id)objectForKey:(NSString *)key atIndexPath:(NSIndexPath *)indexPath {
    return [[[[_settings objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row] objectForKey:key];
}

#pragma mark - Other Info

- (NSString *)bundleVersion {
    NSString *shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *versionCode = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *bundleVersion = [NSString stringWithFormat:@"%@(%@)", shortVersion, versionCode];
    return bundleVersion;
}

@end
