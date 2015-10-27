//
//  ValueSelectorViewController.m
//  VoiceDemo
//
//  Created by Hong Duan on 7/17/15.
//  Copyright (c) 2015 1 Photo. All rights reserved.
//

#import "ValueSelectorViewController.h"

@interface ValueSelectorViewController ()

@end

@implementation ValueSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self.setting objectForKey:@"name"];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.setting objectForKey:@"values"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];
    NSString *description = [[self.setting objectForKey:@"values.description"] objectAtIndex:indexPath.row];
    if ([description length] > 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", description];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [[self.setting objectForKey:@"values"] objectAtIndex:indexPath.row]];
    }
    
    NSString *type = [self.setting objectForKey:@"value.type"];
    BOOL selected = NO;
    if ([type isEqualToString:@"Number"]) {
        NSInteger rowValue = [[[self.setting objectForKey:@"values"] objectAtIndex:indexPath.row] integerValue];
        selected = (rowValue == [[NSUserDefaults standardUserDefaults] integerForKey:[self.setting objectForKey:@"key"]]);
    } else {
        NSString *rowValue = [NSString stringWithFormat:@"%@", [[self.setting objectForKey:@"values"] objectAtIndex:indexPath.row]];
        selected = [rowValue isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:[self.setting objectForKey:@"key"]]];
    }
    
    if (selected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id selectedValue = [[self.setting objectForKey:@"values"] objectAtIndex:indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:selectedValue forKey:[self.setting objectForKey:@"key"]];
    if ([[self.setting objectForKey:@"key"] isEqualToString:@"debug.level"] && [selectedValue isKindOfClass:[NSNumber class]]) {
        [DHLogger setLogLevel:(DHLogLevel)[selectedValue integerValue]];
        if ((DHLogLevel)[selectedValue integerValue] == DH_LOG_VERBOSE) {
            [MobClick setLogEnabled:YES];
        } else {
            [MobClick setLogEnabled:NO];
        }
    }
    for (NSIndexPath *indexPath in [tableView indexPathsForVisibleRows]) {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
    }
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
