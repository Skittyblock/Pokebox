// UINavigationController+StatusBar.m
// Make preferredStatusBarStyle work on view controllers

@implementation UINavigationController (StatusBar)

- (UIStatusBarStyle)preferredStatusBarStyle {
	if (self.childViewControllers.count > 1) {
		if ([self.childViewControllers.lastObject.childViewControllers.lastObject respondsToSelector:@selector(preferredStatusBarStyle)]) {
			return [self.childViewControllers.lastObject.childViewControllers.lastObject preferredStatusBarStyle];
		}
	}
	return UIStatusBarStyleDefault;
}

@end
