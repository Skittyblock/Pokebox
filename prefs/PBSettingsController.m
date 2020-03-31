// PBSettingsController.m

#import "PBSettingsController.h"

@implementation PBSettingsController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Pikachu image
	self.pikaView = [[UIImageView alloc] initWithFrame:CGRectMake(self.headerView.bounds.size.height - 25, self.headerView.bounds.size.width - 120, 48, 31)];
	self.pikaView.image = [UIImage imageWithContentsOfFile:[[self resourceBundle] pathForResource:@"pikachu" ofType:@"png"]];
	[self.headerView addSubview:self.pikaView];

	// Setup notifications
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;

	// Not sure if this is needed, but better leave it to be safe.
	[[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
	}];
}

- (void)layoutHeader {
	[super layoutHeader];
	self.pikaView.frame = CGRectMake(300, self.headerView.bounds.size.height - 25, 48, 31);
}

// "Hack" to allow notifications in the foreground
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
	completionHandler(UNNotificationPresentationOptionAlert);
}

// Send a notification without any libraries!
// Unfortunately this has a 1 second delay idk how to get rid of it
- (void)testNotification {
	UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
	content.title = @"Pokebox";
	content.body = @"Testing your notifications!";
	content.badge = 0;

	UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];

	UNNotificationRequest *requesta = [UNNotificationRequest requestWithIdentifier:@"xyz.skitty.pokebox.notify" content:content trigger:trigger];

	[UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:requesta withCompletionHandler:nil];
}

- (NSBundle *)resourceBundle {
	return [NSBundle bundleWithPath:@"/Library/PreferenceBundles/Pokebox.bundle"];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	if (@available(iOS 13.0, *)) {
		if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
			return UIStatusBarStyleDarkContent;
		} else {
			return UIStatusBarStyleLightContent;
		}
	}
	return UIStatusBarStyleLightContent;
}

@end
