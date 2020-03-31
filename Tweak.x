// Pokébox - Pokémon style notifications
// By Skitty

#import "Tweak.h"
@import CoreText;

static NSString *bundleIdentifier = @"xyz.skitty.pokebox";

static NSString *fontName;

static NSMutableDictionary *settings;
static BOOL previouslyEnabled;
static BOOL enabled;
static BOOL hideIcon;
static BOOL animateText;

static BOOL useCustomTitleSize;
static BOOL useCustomTextSize;

static int titleSize;
static int textSize;
static CGFloat animationSpeed;

static int location;
static int fontValue;
static int bannerAnimation;

static NSMutableArray *viewsToLayout;

// Refresh views instead of respringing
// If you have a better idea of how to do this, let me know. Please.
void refreshViews() {
	for (UIView *view in viewsToLayout) {
		if ([view isKindOfClass:%c(NCNotificationShortLookViewController)]) {
			if (enabled && (location == 0 || ([((NCNotificationShortLookViewController *)view).delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![((NCNotificationShortLookViewController *)view).delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2))) {
				((UIImageView *)[((NCNotificationShortLookViewController *)view).viewForPreview valueForKey:@"_shadowView"]).hidden = YES;
				((NCNotificationShortLookViewController *)view).viewForPreview.backgroundView.hidden = YES;
				((NCNotificationShortLookViewController *)view).backgroundImageView.hidden = NO;
			} else {
				((UIImageView *)[((NCNotificationShortLookViewController *)view).viewForPreview valueForKey:@"_shadowView"]).hidden = NO;
				((NCNotificationShortLookViewController *)view).viewForPreview.backgroundView.hidden = NO;
				((NCNotificationShortLookViewController *)view).backgroundImageView.hidden = YES;
			}
		} else if ([view isKindOfClass:%c(NCNotificationContentView)]) {
			NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[view _viewControllerForAncestor];
			if (fontValue && enabled && (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2))) {
				((NCNotificationContentView *)view).primaryLabel.font = [UIFont fontWithName:fontName size:textSize];
				((NCNotificationContentView *)view).primarySubtitleLabel.font = [UIFont fontWithName:fontName size:textSize];
				((NCNotificationContentView *)view).secondaryLabel.font = [UIFont fontWithName:fontName size:textSize];
				((NCNotificationContentView *)view).summaryLabel.font = [UIFont fontWithName:fontName size:13];
			} else {
				((NCNotificationContentView *)view).primaryLabel.font = [UIFont systemFontOfSize:textSize weight:UIFontWeightSemibold];
				((NCNotificationContentView *)view).primarySubtitleLabel.font = [UIFont systemFontOfSize:textSize weight:UIFontWeightSemibold];
				((NCNotificationContentView *)view).secondaryLabel.font = [UIFont systemFontOfSize:textSize];
				((NCNotificationContentView *)view).summaryLabel.font = [UIFont systemFontOfSize:13];
			}
		} else if ([view isKindOfClass:%c(PLPlatterHeaderContentView)]) {
			[((PLPlatterHeaderContentView *)view) _configureTitleLabel:[(PLPlatterHeaderContentView *)view _titleLabel]];
			[((PLPlatterHeaderContentView *)view) _recycleDateLabel];
			[((PLPlatterHeaderContentView *)view) _configureDateLabel];
			[view setNeedsLayout];
		}
	}
}

// Preference Updates
static void refreshPrefs() {
	CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if(keyList) {
		settings = (NSMutableDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		CFRelease(keyList);
	} else {
		settings = nil;
	}
	if (!settings) {
		settings = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", bundleIdentifier]];
	}

	previouslyEnabled = enabled;

	enabled = [([settings objectForKey:@"enabled"] ?: @(YES)) boolValue];
	hideIcon = [([settings objectForKey:@"hideIcon"] ?: @(NO)) boolValue];
	animateText = [([settings objectForKey:@"animateText"] ?: @(YES)) boolValue];
	location = [([settings objectForKey:@"location"] ?: @(0)) integerValue];
	fontValue = [([settings objectForKey:@"font"] ?: @(2)) integerValue];
	animationSpeed = [([settings objectForKey:@"animationSpeed"] ?: @(0.1)) floatValue];
	bannerAnimation = [([settings objectForKey:@"bannerAnimation"] ?: @(0)) integerValue];

	useCustomTitleSize = [([settings objectForKey:@"useCustomTitleSize"] ?: @(NO)) boolValue];
	useCustomTextSize = [([settings objectForKey:@"useCustomTextSize"] ?: @(NO)) boolValue];

	if (useCustomTitleSize) {
		titleSize = [([settings objectForKey:@"customTitleSize"] ?: @(13)) integerValue];
	} else {
		titleSize = 13;
	}
	if (useCustomTextSize) {
		textSize = [([settings objectForKey:@"customTextSize"] ?: @(15)) integerValue];
	} else {
		textSize = 15;
	}

	// Load font
	NSString *fontPath;
	if (fontValue == 1) {
		fontPath = @"/Library/Application Support/Pokebox/pokemon.ttf";
	} else if (fontValue == 2) {
		fontPath = @"/Library/Application Support/Pokebox/silkscreen.ttf";
	}

	if (fontPath) {
		CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename([fontPath UTF8String]);
		CGFontRef font = CGFontCreateWithDataProvider(dataProvider);
		CGDataProviderRelease(dataProvider);
		CTFontManagerRegisterGraphicsFont(font, nil);
		fontName = (NSString *)CFBridgingRelease(CGFontCopyPostScriptName(font));
		CGFontRelease(font);
	}

	refreshViews();
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  refreshPrefs();
}

@implementation PBHeaderView
@end

// Hooks
%hook NCNotificationShortLookViewController

%property (nonatomic, retain) UIImageView *backgroundImageView;

- (void)viewDidLoad {
	%orig;
	[viewsToLayout addObject:self];
	[viewsToLayout addObject:self.viewForPreview];
	
	PLPlatterHeaderContentView *headerView = [self.viewForPreview valueForKey:@"_headerContentView"];

	// Create an alternate header view
	self.viewForPreview.otherHeaderView = [[PBHeaderView alloc] initWithFrame:headerView.frame];
	self.viewForPreview.otherHeaderView.backgroundColor = [UIColor redColor];
	self.viewForPreview.otherHeaderView.hidden = YES;
	[self.viewForPreview addSubview:self.viewForPreview.otherHeaderView];

	self.viewForPreview.otherHeaderView.iconButton = [[UIButton alloc] initWithFrame:headerView.iconButtons[0].frame];
	[self.viewForPreview.otherHeaderView addSubview:self.viewForPreview.otherHeaderView.iconButton];

	self.viewForPreview.otherHeaderView.titleLabel = [[UILabel alloc] initWithFrame:headerView.titleLabel.frame];
	self.viewForPreview.otherHeaderView.titleLabel.attributedText = headerView.titleLabel.attributedText;
	[self.viewForPreview.otherHeaderView addSubview:self.viewForPreview.otherHeaderView.titleLabel];

	self.viewForPreview.otherHeaderView.dateLabel = [[UILabel alloc] initWithFrame:headerView.dateLabel.frame];
	self.viewForPreview.otherHeaderView.dateLabel.attributedText = headerView.dateLabel.attributedText;
	[self.viewForPreview.otherHeaderView addSubview:self.viewForPreview.otherHeaderView.dateLabel];

	if (hideIcon) {
		self.viewForPreview.otherHeaderView.iconButton.hidden = YES;
		CGRect frame = self.viewForPreview.otherHeaderView.titleLabel.frame;
		self.viewForPreview.otherHeaderView.titleLabel.frame = CGRectMake(-17, frame.origin.y, frame.size.width, frame.size.height);
	} else {
		self.viewForPreview.otherHeaderView.iconButton.hidden = NO;
		self.viewForPreview.otherHeaderView.titleLabel.frame = headerView.titleLabel.frame;
	}
}

- (void)viewDidLayoutSubviews {
	%orig;
	if (!self.backgroundImageView) {
		self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.viewForPreview.backgroundView.bounds];
		self.backgroundImageView.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Pokebox/Pokeballs.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(35, 100, 35, 100) resizingMode:UIImageResizingModeStretch];
		self.backgroundImageView.hidden = YES;
		if (@available(iOS 13, *)) {
			if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
				self.backgroundImageView.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Pokebox/Pokeballs-Dark.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(35, 100, 35, 100) resizingMode:UIImageResizingModeStretch];
			}
		}
		[self.viewForPreview insertSubview:self.backgroundImageView atIndex:0];
	}

	self.backgroundImageView.frame = self.viewForPreview.backgroundView.bounds;

	if (enabled && (location == 0 || ([self.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![self.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2))) {
  		if ([[[UIDevice currentDevice] systemVersion] floatValue] < 13.0) {
			((UIView *)[self.viewForPreview valueForKey:@ "_mainOverlayView"]).hidden = YES;
		}
		((UIView *)[self.viewForPreview valueForKey:@"_grabberView"]).hidden = YES;
		((UIImageView *)[self.viewForPreview valueForKey:@"_shadowView"]).hidden = YES;
		self.viewForPreview.backgroundView.hidden = YES;
		self.backgroundImageView.hidden = NO;
	} else { // This might mess up some tweaks if they also make these hidden
  		if ([[[UIDevice currentDevice] systemVersion] floatValue] < 13.0) {
			((UIView *)[self.viewForPreview valueForKey:@ "_mainOverlayView"]).hidden = NO;
		}
		((UIView *)[self.viewForPreview valueForKey:@"_grabberView"]).hidden = NO;
		((UIImageView *)[self.viewForPreview valueForKey:@"_shadowView"]).hidden = NO;
		self.viewForPreview.backgroundView.hidden = NO;
		self.backgroundImageView.hidden = YES;

		if (hideIcon) {
			self.viewForPreview.otherHeaderView.iconButton.hidden = YES;
			CGRect frame = self.viewForPreview.otherHeaderView.titleLabel.frame;
			self.viewForPreview.otherHeaderView.titleLabel.frame = CGRectMake(-17, frame.origin.y, frame.size.width, frame.size.height);
		} else {
			self.viewForPreview.otherHeaderView.iconButton.hidden = NO;
			PLPlatterHeaderContentView *headerView = [self.viewForPreview valueForKey:@"_headerContentView"];
			self.viewForPreview.otherHeaderView.titleLabel.frame = headerView.titleLabel.frame;
		}
	}
}

- (void)viewWillAppear:(BOOL)animated {
	if ([self.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location != 2) {
		// Hide notification text
		if (enabled && animateText) {
			self.viewForPreview.originalSecondaryText = self.viewForPreview.secondaryText;
			NSString *padText = @" ";
			for (int i = 1; i < self.viewForPreview.secondaryText.length; i++) {
				if (self.viewForPreview.secondaryText.UTF8String[i] == '\n') {
					padText = [NSString stringWithFormat:@"%@\n", padText];
				} else {
					padText = [NSString stringWithFormat:@"%@⠀", padText]; // this isn't a space, it's an invisible character. spaces don't work.
				}
			}
			self.viewForPreview.secondaryText = padText; // fixes label resizing
		}

		// Hide (default) animation
		if (enabled && bannerAnimation > 0) {
			self.viewForPreview.hidden = YES;
		}

		// Dont't hide status bar when on the bottom
		if (enabled && (bannerAnimation == 1 || bannerAnimation == 3)) {
			return;
		}
	}
	%orig;

}

- (void)viewDidAppear:(BOOL)animated {
	%orig;

	self.viewForPreview.hidden = NO;

	if ([self.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location != 2) {
		// Rotate views to put banner on bottom
		if (enabled && (bannerAnimation == 1 || bannerAnimation == 3)) {
			self.view.transform = CGAffineTransformMakeRotation(M_PI);
			self.viewForPreview.superview.transform = CGAffineTransformMakeRotation(M_PI);

			if (bannerAnimation == 1) {
				self.viewForPreview.superview.frame = CGRectMake(self.viewForPreview.superview.frame.origin.x, self.viewForPreview.superview.frame.origin.y - self.viewForPreview.superview.bounds.size.height*2, self.viewForPreview.superview.bounds.size.width, self.viewForPreview.superview.bounds.size.height);
				[UIView animateWithDuration:0.5 animations:^{
					self.viewForPreview.superview.frame = CGRectMake(self.viewForPreview.superview.frame.origin.x, self.viewForPreview.superview.frame.origin.y + self.viewForPreview.superview.bounds.size.height*2, self.viewForPreview.superview.bounds.size.width, self.viewForPreview.superview.bounds.size.height);
				} completion:nil];
			}
		}

		// Text animation
		if (enabled && animateText) {
			NSString *newText = self.viewForPreview.originalSecondaryText;
			self.viewForPreview.secondaryText = [NSString stringWithFormat:@"%C", [newText characterAtIndex:0]];

			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			[dict setObject:newText forKey:@"string"];
			[dict setObject:@0 forKey:@"currentCount"];
			NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:animationSpeed target:self selector:@selector(animateText:) userInfo:dict repeats:YES];
			[timer fire];
		}
	}
}

// Animate banner dismissal from bottom
// Still a little buggy because the view will disappear before the animation is complete
- (void)viewWillDisappear:(BOOL)animated {
	if ([self.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location != 2 && bannerAnimation == 3) {
		[UIView animateWithDuration:0.5 animations:^{
			self.viewForPreview.superview.frame = CGRectMake(self.viewForPreview.superview.frame.origin.x, self.viewForPreview.superview.frame.origin.y - self.viewForPreview.superview.bounds.size.height*2, self.viewForPreview.superview.bounds.size.width, self.viewForPreview.superview.bounds.size.height);
		} completion:nil];
	}
	%orig;
}

// Flip notification long looks
// A little buggy, but it works
- (void)_presentLongLookForScrollAnimated:(BOOL)animated completion:(id)completion {
	%orig;
	if (enabled && (bannerAnimation == 1 || bannerAnimation == 3)) {
		[self.presentedLongLookViewController _longLookViewIfLoaded].transform = CGAffineTransformMakeRotation(M_PI);
	}
}

// Apparently implementing this myself fixes a rotation bug with the long look presentation
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (enabled && (bannerAnimation == 1 || bannerAnimation == 3)) {
		if (scrollView.contentOffset.y < -40 && ![self _didScrollPresentLongLookViewController]) { // original is scrollView.contentOffset.y < -40
			if (!self.clickPresentationInteractionManager.hasCommittedToPresentation) {
				[self _presentLongLookForScrollAnimated:YES completion:nil];
			}
		}
	} else {
		%orig;
	}
}

// Dark mode support
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	%orig;
	if (self.backgroundImageView) {
		if (@available(iOS 13, *)) {
			if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
				self.backgroundImageView.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Pokebox/Pokeballs-Dark.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(35, 100, 35, 100) resizingMode:UIImageResizingModeStretch];
			} else {
				self.backgroundImageView.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Pokebox/Pokeballs.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(35, 100, 35, 100) resizingMode:UIImageResizingModeStretch];
			}
		}
	}
}

// Animate text like Pokémon
%new
- (void)animateText:(NSTimer *)timer {
	NSString *string = [timer.userInfo objectForKey:@"string"];
	if (enabled && animateText) {
		int currentCount = [[timer.userInfo objectForKey:@"currentCount"] intValue];
		currentCount++;
		[timer.userInfo setObject:[NSNumber numberWithInt:currentCount] forKey:@"currentCount"];

		if (currentCount >= string.length) {
			[timer invalidate];
		}
		self.viewForPreview.secondaryText = [string substringToIndex:currentCount];
	} else {
		self.viewForPreview.secondaryText = string;
	}
}

%end

// Disable(default) dismissal animation
%hook NCBannerPresentationTransitionDelegate

- (id)animationControllerForDismissedController:(id)controller {
	if (enabled && bannerAnimation > 0) {
		return nil;
	}
	return %orig;
}

%end

// Add properties
%hook NCNotificationShortLookView

%property (nonatomic, retain) UIView *otherHeaderView;
%property (nonatomic, assign) NSString *originalSecondaryText;

%end

// Notification header
%hook PLPlatterHeaderContentView

// Adjust the replacement header view frame/text
// I COULDN'T FIND ANY OTHER METHODS TO HOOK
- (void)layoutSubviews {
	%orig;
	if (![viewsToLayout containsObject:self] && ![self isKindOfClass:%c(WGPlatterHeaderContentView)]) {
		[viewsToLayout addObject:self];
	}

	if ([self.superview isKindOfClass:%c(NCNotificationShortLookView)]) {
		NCNotificationShortLookView *superview = (NCNotificationShortLookView *)self.superview;
		NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[superview _viewControllerForAncestor];
		if (enabled && (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2))) {
			superview.otherHeaderView.frame = CGRectMake(2, 4, self.frame.size.width - 4, self.frame.size.height);
			superview.otherHeaderView.backgroundColor = [UIColor clearColor];
			//superview.otherHeaderView.transform = CGAffineTransformMakeTranslation(0, 5);

			superview.otherHeaderView.iconButton.frame = self.iconButtons[0].frame;
			[superview.otherHeaderView.iconButton setImage:self.iconButtons[0].imageView.image forState:UIControlStateNormal];

			superview.otherHeaderView.titleLabel.frame = self.titleLabel.frame;
			if (hideIcon) {
				superview.otherHeaderView.iconButton.hidden = YES;
				superview.otherHeaderView.titleLabel.frame = CGRectMake(-17, self.titleLabel.frame.origin.y, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
			} else {
				superview.otherHeaderView.iconButton.hidden = NO;
			}
			superview.otherHeaderView.titleLabel.attributedText = self.titleLabel.attributedText;
			superview.otherHeaderView.titleLabel.font = [self _titleLabelPreferredFont];
			superview.otherHeaderView.titleLabel.layer.filters = self.titleLabel.layer.filters;

			superview.otherHeaderView.dateLabel.frame = self.dateLabel.frame;
			superview.otherHeaderView.dateLabel.attributedText = self.dateLabel.attributedText;
			superview.otherHeaderView.dateLabel.font = [self _dateLabelPreferredFont];
			superview.otherHeaderView.dateLabel.layer.filters = self.dateLabel.layer.filters;

			superview.otherHeaderView.hidden = NO;
			self.hidden = YES;
		} else {
			superview.otherHeaderView.hidden = YES;
			self.hidden = NO;
		}
	}
}

// Header fonts
- (UIFont *)_titleLabelFont {
	NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[self _viewControllerForAncestor];
	bool loc = (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2));
	if (enabled && fontValue && ![self isKindOfClass:%c(WGPlatterHeaderContentView)] && loc) {
		return [UIFont fontWithName:fontName size:titleSize];
	}
	return %orig;
}

- (UIFont *)_titleLabelPreferredFont {
	NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[self _viewControllerForAncestor];
	bool loc = (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2));
	if (enabled && fontValue && ![self isKindOfClass:%c(WGPlatterHeaderContentView)] && loc) {
		return [UIFont fontWithName:fontName size:titleSize];
	}
	return %orig;
}

- (UIFont *)_dateLabelFont {
	NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[self _viewControllerForAncestor];
	bool loc = (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2));
	if (enabled && fontValue && loc) {
		return [UIFont fontWithName:fontName size:titleSize];
	}
	return %orig;
}

- (UIFont *)_dateLabelPreferredFont {
	NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[self _viewControllerForAncestor];
	bool loc = (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2));
	if (enabled && fontValue && loc) {
		return [UIFont fontWithName:fontName size:titleSize];
	}
	return %orig;
}

%end

// Notification content
%hook NCNotificationContentView

- (void)didMoveToSuperview {
	%orig;
	if (![viewsToLayout containsObject:self] && ![self isKindOfClass:%c(WGPlatterHeaderContentView)]) {
		[viewsToLayout addObject:self];
	}
}

// Content fonts
- (void)setPrimaryText:(NSString *)primaryText {
	%orig;
	NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[self _viewControllerForAncestor];
	bool loc = (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2));
	if (enabled && fontValue && loc) {
		self.primaryLabel.font = [UIFont fontWithName:fontName size:textSize];
	}
}

- (void)setPrimarySubtitleText:(NSString *)primarySubtitleText {
	%orig;
	NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[self _viewControllerForAncestor];
	bool loc = (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2));
	if (enabled && fontValue && loc) {
		self.primarySubtitleLabel.font = [UIFont fontWithName:fontName size:textSize];
	}
}

- (void)setSecondaryText:(NSString *)secondaryText {
	%orig;
	NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[self _viewControllerForAncestor];
	bool loc = (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2));
	if (enabled && fontValue && loc) {
		self.secondaryLabel.font = [UIFont fontWithName:fontName size:textSize];
	}
}

- (void)setSummaryText:(NSString *)summaryText {
	%orig;
	NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[self _viewControllerForAncestor];
	bool loc = (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2));
	if (enabled && fontValue && loc) {
		self.summaryLabel.font = [UIFont fontWithName:fontName size:13];
	}
}

%end

%ctor {
	viewsToLayout = [NSMutableArray new];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) PreferencesChangedCallback, (CFStringRef)[NSString stringWithFormat:@"%@.prefschanged", bundleIdentifier], NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	refreshPrefs();
}
