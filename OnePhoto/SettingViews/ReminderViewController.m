//
//  ReminderViewController.m
//  OnePhoto
//
//  Created by Hong Duan on 10/26/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "ReminderViewController.h"
#import "CoreDataHelper.h"

@interface ReminderViewController () {
    NSString* _reminderNow;
}
@property (weak, nonatomic) IBOutlet UIDatePicker *reminderTimePicker;

@end

@implementation ReminderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.reminderTimePicker addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventValueChanged];
    
    id reminderTime = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_REMINDER_TIME];
    if ([reminderTime isKindOfClass:[NSDate class]]) {
        NSDate *fireDate = [GlobalUtils HHmmToday:[[GlobalUtils HHmmFormatter] stringFromDate:reminderTime]];
        self.reminderTimePicker.date = fireDate;
        _reminderNow = [[GlobalUtils HHmmFormatter] stringFromDate:self.reminderTimePicker.date];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)timeChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:self.reminderTimePicker.date forKey:DEFAULTS_KEY_REMINDER_TIME];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_REMINDER_TIME] || [[[GlobalUtils HHmmFormatter] stringFromDate:self.reminderTimePicker.date] isEqualToString:_reminderNow]) {
        return;
    }
    
    BOOL isTodayPhotoTaked = [[CoreDataHelper sharedHelper] isPhotoOfDateExists:[[GlobalUtils dateFormatter] stringFromDate:[NSDate date]]];
    if (isTodayPhotoTaked) {
        [GlobalUtils setDailyNotification:[GlobalUtils addToDate:self.reminderTimePicker.date days:1]];
    } else {
        [GlobalUtils setDailyNotification:self.reminderTimePicker.date];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReminderCell" forIndexPath:indexPath];
    cell.textLabel.text = @"每天提醒";
    
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_REMINDER_TIME]) {
            cell.detailTextLabel.text = [[GlobalUtils HHmmFormatter] stringFromDate:[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_REMINDER_TIME]];
        } else {
            cell.detailTextLabel.text = @"点击设置";
        }
    } else {
        cell.detailTextLabel.text = @"已禁用";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
        self.reminderTimePicker.hidden = !self.reminderTimePicker.hidden;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
        self.reminderTimePicker.hidden = !self.reminderTimePicker.hidden;
    } else {
        [GlobalUtils alertMessage:@"1 Photo的通知已被关闭，请于iOS设置中打开"];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
