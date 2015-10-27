//
//  EditTextViewController.m
//  VoiceDemo
//
//  Created by Hong Duan on 7/16/15.
//  Copyright (c) 2015 1 Photo. All rights reserved.
//

#import "EditTextViewController.h"

@interface EditTextViewController () {
    UITextField *_textField;
}

@end

@implementation EditTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self.setting objectForKey:@"name"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([_textField.text length] > 0) {
        if ([[self.setting objectForKey:@"type"] isEqualToString:@"String"]) {
            [[NSUserDefaults standardUserDefaults] setObject:_textField.text forKey:[self.setting objectForKey:@"key"]];
        } else if ([[self.setting objectForKey:@"type"] isEqualToString:@"Number"]) {
            NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
            nf.numberStyle = NSNumberFormatterDecimalStyle;
            NSNumber *number = [nf numberFromString:_textField.text];
            if (number) {
                [[NSUserDefaults standardUserDefaults] setObject:number forKey:[self.setting objectForKey:@"key"]];
            }
        }
    }
}

- (IBAction)setDefault:(id)sender {
    _textField.text = [NSString stringWithFormat:@"%@", [self.setting objectForKey:@"default"]];
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
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EditTextCell" forIndexPath:indexPath];
    _textField = (UITextField *)[cell.contentView viewWithTag:1];
    _textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:[self.setting objectForKey:@"key"]];
    if ([[self.setting objectForKey:@"type"] isEqualToString:@"Number"]) {
        [_textField setKeyboardType:UIKeyboardTypeNumberPad];
    }
    return cell;
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
