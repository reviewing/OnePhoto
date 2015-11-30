//
//  AddNoteViewController.m
//  OnePhoto
//
//  Created by Hong Duan on 11/28/15.
//  Copyright © 2015 Hong D. Empire. All rights reserved.
//

#import "AddNoteViewController.h"
#import "iCloudAccessor.h"
#import <UITextView+Placeholder.h>

@interface AddNoteViewController ()
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@end

@implementation AddNoteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [UIImage imageWithData:[[iCloudAccessor shareAccessor] photoDataOfRelativelyPath:self.photoRelativelyPath]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.photoImageView setImage:image];
        });
    });
    self.noteTextView.placeholder = @"写点什么...";
    [self.noteTextView becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)viewDidAppear:(BOOL)animated {
    self.contentViewHeightConstraint.constant = self.noteTextView.frame.size.height + self.photoImageView.frame.size.height + 8;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.noteTextView resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)changeSuffix:(NSString *)oldPath {
    NSString *newPath = nil;
    if ([oldPath hasSuffix:@".jpg"]) {
        oldPath = [oldPath substringToIndex:[oldPath length] - 4];
    }
    newPath = [oldPath stringByAppendingString:ONE_PHOTO_EXTENSION];
    return newPath;
}

- (IBAction)add:(id)sender {
    NSURL *photoURL = [GlobalUtils ubiqURLforPath:self.photoRelativelyPath];
    if ([[photoURL path] hasSuffix:@".jpg"]) {
        photoURL = [GlobalUtils ubiqURLforPath:[self changeSuffix:self.photoRelativelyPath]];

        OPPhotoCloud *photoCloud = [[OPPhotoCloud alloc] initWithFileURL:photoURL];
        photoCloud.imageData = UIImageJPEGRepresentation(self.photoImageView.image, 0.8);
        if ([self.noteTextView.text length] > 0) {
            NSDictionary *metaData = [NSDictionary dictionaryWithObject:self.noteTextView.text forKey:ONE_PHOTO_KEY_NOTE];
            photoCloud.metaData = [NSKeyedArchiver archivedDataWithRootObject:metaData];
        }
        
        [photoCloud saveToURL:[photoCloud fileURL] forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                DHLogDebug(@"document saved successfully");
                [[iCloudAccessor shareAccessor] deleteFileWithRelativelyPath:self.photoRelativelyPath];
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            } else {
                [GlobalUtils alertMessage:@"保存修改失败，请检查iCloud账户设置后重试"];
            }
            [photoCloud closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    DHLogDebug(@"iCloud document closed");
                } else {
                    DHLogDebug(@"failed closing document from iCloud");
                }
            }];
        }];
    } else {
        OPPhotoCloud *photoCloud = [[OPPhotoCloud alloc] initWithFileURL:photoURL];
        [photoCloud openWithCompletionHandler:^(BOOL success) {
            if (success) {
                DHLogDebug(@"iCloud document opened");
                if ([self.noteTextView.text length] > 0) {
                    NSDictionary *metaData = [NSDictionary dictionaryWithObject:self.noteTextView.text forKey:ONE_PHOTO_KEY_NOTE];
                    photoCloud.metaData = [NSKeyedArchiver archivedDataWithRootObject:metaData];
                }
                [photoCloud saveToURL:[photoCloud fileURL] forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                    if (success) {
                        DHLogDebug(@"document saved successfully");
                        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        [GlobalUtils alertMessage:@"保存修改失败，请检查iCloud账户设置后重试"];
                    }
                    [photoCloud closeWithCompletionHandler:^(BOOL success) {
                        if (success) {
                            DHLogDebug(@"iCloud document closed");
                        } else {
                            DHLogDebug(@"failed closing document from iCloud");
                        }
                    }];
                }];
            } else {
                [GlobalUtils alertMessage:@"保存修改失败，请检查iCloud账户设置后重试"];
                DHLogDebug(@"failed opening document from iCloud");
                [photoCloud closeWithCompletionHandler:^(BOOL success) {
                    if (success) {
                        DHLogDebug(@"iCloud document closed");
                    } else {
                        DHLogDebug(@"failed closing document from iCloud");
                    }
                }];
            }
        }];
    }
}

@end
