#import "UIViewController+VENTouchLock.h"

#define UIColorFromRGB(rgbValue) \
    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                    green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
                     blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
                    alpha:1.0]

@implementation UIViewController (VENTouchLock)

- (UINavigationController *)ventouchlock_embeddedInNavigationControllerWithNavigationBarClass:(Class)navigationBarClass
{
    UINavigationController *navigationController = [[UINavigationController alloc] initWithNavigationBarClass:navigationBarClass toolbarClass:nil];
    navigationController.navigationBar.barStyle = UIBarStyleBlack;
    navigationController.navigationBar.barTintColor = UIColorFromRGB(0x1A1E21);
    navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [navigationController pushViewController:self animated:NO];
    return navigationController;
}

+ (UIViewController*)ventouchlock_topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}

@end