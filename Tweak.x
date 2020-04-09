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
static int style;
static int fontValue;
static int bannerAnimation;

static NSMutableArray *viewsToLayout;

// Update notification banner style
void updateBannerStyle(NCNotificationShortLookViewController *controller) {
	// ColorBanners/ColorMeNotifs support
	BOOL colorBanners = NO;

	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/ColorBanners3.dylib"]) {
		for (UIView *sview in controller.viewForPreview.backgroundMaterialView.subviews) {
			if ([[sview class] isEqual:%c(CBR3GradientView)]) {
				if (((CAGradientLayer *)sview.layer).colors.count > 0) {
					controller.backgroundColorView.backgroundColor = [[UIColor alloc] initWithCGColor:(__bridge CGColorRef)(((CAGradientLayer *)sview.layer).colors[0])] ?: [UIColor whiteColor];
					colorBanners = YES;
				}
				break;
			}
		}
	}
	if (!colorBanners && [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/ColorMeNotifs.dylib"] && controller.viewForPreview.backgroundMaterialView.backgroundColor) {
		controller.backgroundColorView.backgroundColor = controller.viewForPreview.backgroundMaterialView.backgroundColor;
		colorBanners = YES;
	}

	// Banner style
	BOOL darkMode = NO;

	if (@available(iOS 13, *)) {
		if (controller.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark && (style == 0 || style == 2)) {
			darkMode = YES;
		}
	}
	if (style == 2) {
		darkMode = YES;
	}

	PLPlatterHeaderContentView *headerView = [controller.viewForPreview valueForKey:@"_headerContentView"];
	NCNotificationContentView *contentView = [controller.viewForPreview valueForKey:@"_notificationContentView"];

	if (!colorBanners) {
		[controller.viewForPreview.otherHeaderView.titleLabel enableDarkMode:darkMode];
		[controller.viewForPreview.otherHeaderView.dateLabel enableDarkMode:darkMode];

		[contentView.primaryLabel enableDarkMode:darkMode];
		[contentView.primarySubtitleLabel enableDarkMode:darkMode];
		[contentView.secondaryLabel enableDarkMode:darkMode];
		[contentView.summaryLabelCopy enableDarkMode:darkMode];

		if (darkMode) {
			controller.backgroundColorView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.00];
		} else {
			controller.backgroundColorView.backgroundColor = [UIColor whiteColor];
		}
	} else {
		// This is kinda dumb ngl. I need a better system.
		controller.viewForPreview.otherHeaderView.titleLabel.darkModeEnabled = NO;
		controller.viewForPreview.otherHeaderView.titleLabel.lightModeEnabled = NO;
		controller.viewForPreview.otherHeaderView.dateLabel.darkModeEnabled = NO;
		controller.viewForPreview.otherHeaderView.dateLabel.lightModeEnabled = NO;
		contentView.primaryLabel.darkModeEnabled = NO;
		contentView.primaryLabel.lightModeEnabled = NO;
		contentView.primarySubtitleLabel.darkModeEnabled = NO;
		contentView.primarySubtitleLabel.lightModeEnabled = NO;
		contentView.secondaryLabel.darkModeEnabled = NO;
		contentView.secondaryLabel.lightModeEnabled = NO;
		contentView.summaryLabelCopy.darkModeEnabled = NO;
		contentView.summaryLabelCopy.lightModeEnabled = NO;

		controller.viewForPreview.otherHeaderView.titleLabel.layer.filters = headerView.titleLabel.layer.filters;
		controller.viewForPreview.otherHeaderView.dateLabel.layer.filters = headerView.dateLabel.layer.filters;
		contentView.summaryLabelCopy.layer.filters = contentView.summaryLabel.layer.filters;

		controller.viewForPreview.otherHeaderView.titleLabel.textColor = headerView.titleLabel.textColor;
		controller.viewForPreview.otherHeaderView.dateLabel.textColor = headerView.dateLabel.textColor;
		contentView.summaryLabelCopy.textColor = contentView.summaryLabel.textColor;
	}

	if (darkMode) {
		controller.backgroundImageView.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Pokebox/Pokeballs-Dark-Border.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(35, 100, 35, 100) resizingMode:UIImageResizingModeStretch];
	} else {	
		controller.backgroundImageView.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Pokebox/Pokeballs-Border.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(35, 100, 35, 100) resizingMode:UIImageResizingModeStretch];
	}
}

// Refresh views instead of respringing
// If you have a better idea of how to do this, let me know. Please.
void refreshViews() {
	for (UIView *view in viewsToLayout) {
		if ([view isKindOfClass:%c(NCNotificationShortLookViewController)]) {
			NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)view;
			if (enabled && (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2))) {
				((UIImageView *)[controller.viewForPreview valueForKey:@"_shadowView"]).hidden = YES;
				controller.viewForPreview.backgroundView.hidden = YES;
				controller.backgroundImageView.hidden = NO;
			} else {
				((UIImageView *)[controller.viewForPreview valueForKey:@"_shadowView"]).hidden = NO;
				controller.viewForPreview.backgroundView.hidden = NO;
				controller.backgroundImageView.hidden = YES;
			}
			updateBannerStyle(controller);
		} else if ([view isKindOfClass:%c(NCNotificationContentView)]) {
			NCNotificationContentView *contentView = (NCNotificationContentView *)view;
			NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[view _viewControllerForAncestor];
			if (fontValue && enabled && (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2))) {
				contentView.primaryLabel.font = [UIFont fontWithName:fontName size:textSize];
				contentView.primarySubtitleLabel.font = [UIFont fontWithName:fontName size:textSize];
				contentView.secondaryLabel.font = [UIFont fontWithName:fontName size:textSize];
				contentView.summaryLabel.font = [UIFont fontWithName:fontName size:13];
				contentView.summaryLabelCopy.font = [UIFont fontWithName:fontName size:13];
			} else {
				contentView.primaryLabel.font = [UIFont systemFontOfSize:textSize weight:UIFontWeightSemibold];
				contentView.primarySubtitleLabel.font = [UIFont systemFontOfSize:textSize weight:UIFontWeightSemibold];
				contentView.secondaryLabel.font = [UIFont systemFontOfSize:textSize];
				contentView.summaryLabel.font = [UIFont systemFontOfSize:13];
				contentView.summaryLabelCopy.font = [UIFont systemFontOfSize:13];
			}
			[view setNeedsLayout];
		} else if ([view isKindOfClass:%c(PLPlatterHeaderContentView)]) {
			PLPlatterHeaderContentView *headerView = (PLPlatterHeaderContentView *)view;
			[headerView _configureTitleLabel:[headerView _titleLabel]];
			[headerView _recycleDateLabel];
			[headerView _configureDateLabel];
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
	style = [([settings objectForKey:@"style"] ?: @(0)) integerValue];
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
%property (nonatomic, retain) UIView *backgroundColorView;

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

	//self.viewForPreview.otherHeaderView.titleLabel.text = [headerView.titleLabel.attributedText string];
	NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:headerView.titleLabel.attributedText.string];
	NSDictionary *attrs = [headerView.titleLabel.attributedText attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, headerView.titleLabel.attributedText.length)];;
	if ([attrs objectForKey:@"NSParagraphStyle"]) {
		[titleText addAttribute:NSParagraphStyleAttributeName value:[attrs objectForKey:@"NSParagraphStyle"] range:NSMakeRange(0, titleText.length)];
	} else {
		titleText = [[NSMutableAttributedString alloc] initWithString:attrs.description];
	}
	self.viewForPreview.otherHeaderView.titleLabel.attributedText = titleText;

	//self.viewForPreview.otherHeaderView.titleLabel.layer.filters = headerView.titleLabel.layer.filters;
	[self.viewForPreview.otherHeaderView addSubview:self.viewForPreview.otherHeaderView.titleLabel];

	self.viewForPreview.otherHeaderView.dateLabel = [[UILabel alloc] initWithFrame:headerView.dateLabel.frame];
	self.viewForPreview.otherHeaderView.dateLabel.attributedText = headerView.dateLabel.attributedText;
	self.viewForPreview.otherHeaderView.dateLabel.layer.filters = headerView.dateLabel.layer.filters;
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

	// ColorMeNotifs support
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/ColorMeNotifs.dylib"] && self.viewForPreview.backgroundMaterialView.backgroundColor) {
		self.backgroundColorView.backgroundColor = self.viewForPreview.backgroundMaterialView.backgroundColor;
	}

	// Load background image
	if (!self.backgroundImageView) {
		self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.viewForPreview.backgroundView.bounds];
		self.backgroundImageView.image = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/Pokebox/Pokeballs-Border.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(35, 100, 35, 100) resizingMode:UIImageResizingModeStretch];
		self.backgroundImageView.hidden = YES;
		[self.viewForPreview insertSubview:self.backgroundImageView atIndex:0];

		self.backgroundColorView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, self.backgroundImageView.bounds.size.width - 10, self.backgroundImageView.bounds.size.height - 10)];
		self.backgroundColorView.backgroundColor = [UIColor whiteColor];
		[self.viewForPreview insertSubview:self.backgroundColorView atIndex:0];

		updateBannerStyle(self);
	}

	self.backgroundImageView.frame = self.viewForPreview.backgroundView.bounds;
	self.backgroundColorView.frame = CGRectMake(5, 5, self.backgroundImageView.bounds.size.width - 10, self.backgroundImageView.bounds.size.height - 10);

	if (enabled && (location == 0 || ([self.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![self.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2))) {
  		if ([[[UIDevice currentDevice] systemVersion] floatValue] < 13.0) {
			((UIView *)[self.viewForPreview valueForKey:@ "_mainOverlayView"]).hidden = YES;
		}
		((UIView *)[self.viewForPreview valueForKey:@"_grabberView"]).hidden = YES;
		((UIImageView *)[self.viewForPreview valueForKey:@"_shadowView"]).hidden = YES;
		self.viewForPreview.backgroundView.hidden = YES;
		self.backgroundImageView.hidden = NO;
	} else { // This might mess up some tweaks if they hide these
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
			self.viewForPreview.originalSecondaryText = self.viewForPreview.secondaryText ?: @"";
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
			NSString *newText = self.viewForPreview.originalSecondaryText ?: @"";
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
	if (self.backgroundImageView && self.backgroundColorView) {
		updateBannerStyle(self);
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
%property (nonatomic, retain) NSString *originalSecondaryText;

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

			superview.otherHeaderView.iconButton.frame = self.iconButtons[0].frame;
			[superview.otherHeaderView.iconButton setImage:self.iconButtons[0].imageView.image forState:UIControlStateNormal];

			superview.otherHeaderView.titleLabel.frame = self.titleLabel.frame;
			superview.otherHeaderView.titleLabel.font = [self _titleLabelPreferredFont];

			// Hide header icon option
			if (hideIcon) {
				superview.otherHeaderView.iconButton.hidden = YES;
				superview.otherHeaderView.titleLabel.frame = CGRectMake(-17, self.titleLabel.frame.origin.y, self.titleLabel.frame.size.width, self.titleLabel.frame.size.height);
			} else {
				superview.otherHeaderView.iconButton.hidden = NO;
			}

			// Funky attributed string stuff -- this is necessary because we want the text indent but NOT the color override on the title.
			NSMutableAttributedString *titleText = [[NSMutableAttributedString alloc] initWithString:self.titleLabel.attributedText.string];
			NSDictionary *attrs = [self.titleLabel.attributedText attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, self.titleLabel.attributedText.length)];;
			if ([attrs objectForKey:@"NSParagraphStyle"]) {
				[titleText addAttribute:NSParagraphStyleAttributeName value:[attrs objectForKey:@"NSParagraphStyle"] range:NSMakeRange(0, titleText.length)];
			} else {
				titleText = [[NSMutableAttributedString alloc] initWithString:attrs.description];
			}
			superview.otherHeaderView.titleLabel.attributedText = titleText;

			superview.otherHeaderView.dateLabel.frame = self.dateLabel.frame;
			superview.otherHeaderView.dateLabel.text = self.dateLabel.text;
			superview.otherHeaderView.dateLabel.font = [self _dateLabelPreferredFont];

			// Override style fix
			if (style == 1 || style == 2) {
				superview.otherHeaderView.titleLabel.layer.filters = nil;
				superview.otherHeaderView.dateLabel.layer.filters = nil;
			} else {
				superview.otherHeaderView.titleLabel.layer.filters = self.titleLabel.layer.filters;
				superview.otherHeaderView.dateLabel.layer.filters = self.dateLabel.layer.filters;
			}
			NCNotificationContentView *contentView = [superview valueForKey:@"_notificationContentView"];
			[contentView setNeedsLayout];

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
%property (nonatomic, retain) UILabel *summaryLabelCopy;

- (void)didMoveToSuperview {
	%orig;
	if (![viewsToLayout containsObject:self] && ![self isKindOfClass:%c(WGPlatterHeaderContentView)]) {
		[viewsToLayout addObject:self];
	}
}

- (void)layoutSubviews {
	%orig;

	if (self.summaryLabelCopy) {
		if (enabled) {
			self.summaryLabel.hidden = YES;
			self.summaryLabelCopy.hidden = NO;
		} else {
			self.summaryLabel.hidden = NO;
			self.summaryLabelCopy.hidden = YES;
		}

		self.summaryLabelCopy.frame = self.summaryLabel.frame;
		self.summaryLabelCopy.text = self.summaryLabel.text;

		// Override style fix
		if (style == 1 || style == 2) {
			self.summaryLabelCopy.layer.filters = nil;
		} else {
			self.summaryLabelCopy.layer.filters = self.summaryLabel.contentLabel.layer.filters;
		}
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
	if (!self.summaryLabelCopy) {
		self.summaryLabelCopy = [[UILabel alloc] initWithFrame:self.summaryLabel.frame];
		[self.summaryLabel.superview addSubview:self.summaryLabelCopy];
	}
	self.summaryLabelCopy.text = self.summaryLabel.text;
	self.summaryLabelCopy.layer.filters = self.summaryLabel.contentLabel.layer.filters;

	self.summaryLabel.hidden = YES;
	self.summaryLabelCopy.hidden = NO;

	NCNotificationShortLookViewController *controller = (NCNotificationShortLookViewController *)[self _viewControllerForAncestor];
	bool loc = (location == 0 || ([controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 1) || (![controller.delegate isKindOfClass:%c(SBNotificationBannerDestination)] && location == 2));
	if (enabled && fontValue && loc) {
		self.summaryLabel.font = [UIFont fontWithName:fontName size:13];
		self.summaryLabelCopy.font = [UIFont fontWithName:fontName size:13];
	}
}

%end

// Hook UILabel and BSUIEmojiLabelView to add support for dark mode on labels
%hook UILabel
%property (nonatomic, assign) BOOL lightModeEnabled;
%property (nonatomic, assign) BOOL darkModeEnabled;

- (void)setTextColor:(UIColor *)textColor {
	if ((style == 1 || style == 2) && (self.darkModeEnabled || self.lightModeEnabled)) {
		return %orig(self.darkModeEnabled ? [UIColor whiteColor] : [UIColor blackColor]);
	}
	%orig;
}

%new
- (void)enableDarkMode:(BOOL)enable {
	self.lightModeEnabled = !enable;
	self.darkModeEnabled = enable;
	self.textColor = enable ? [UIColor whiteColor] : [UIColor blackColor];
}

%end

%hook BSUIEmojiLabelView
%new
- (void)enableDarkMode:(BOOL)enable {
	self.textColor = enable ? [UIColor whiteColor] : [UIColor blackColor];
}
%end

%ctor {
	viewsToLayout = [NSMutableArray new];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) PreferencesChangedCallback, (CFStringRef)[NSString stringWithFormat:@"%@.prefschanged", bundleIdentifier], NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	refreshPrefs();
}
