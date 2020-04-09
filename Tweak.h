// Pokébox Headers
#import <UserNotifications/UserNotifications.h>

@interface UIView (Private)
- (UIViewController *)_viewControllerForAncestor;
@end

@class BSUIFontProvider;

@interface PLPlatterHeaderContentView : UIView
@property (setter=_setFontProvider:, getter=_fontProvider, nonatomic, retain) BSUIFontProvider * fontProvider; 
@property (getter=_titleLabel, nonatomic, readonly) UILabel *titleLabel; 
@property (getter=_dateLabel, nonatomic, readonly) UILabel *dateLabel;
@property (nonatomic,readonly) NSArray<UIButton *> *iconButtons;
- (void)_configureTitleLabel:(id)titleLabel;
- (void)_configureDateLabel;
- (void)_recycleDateLabel;
- (id)_titleLabel;
- (void)updateFrame;
- (UIFont *)_titleLabelPreferredFont;
- (UIFont *)_dateLabelPreferredFont;
@end

@interface PLPlatterView : UIView
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, retain) UIImageView *backgroundImageView;
@end

@interface BSUIEmojiLabelView : UIView
@property (nonatomic, retain) UILabel *contentLabel;
@property (nonatomic, assign) UIFont *font;
@property (nonatomic, assign) UIColor *textColor;
@property (nonatomic, assign) NSString *text;
- (void)enableDarkMode:(BOOL)enable;
@end

@interface NCNotificationContentView : UIView
@property (setter=_setPrimaryLabel:, getter=_primaryLabel, nonatomic, retain) UILabel *primaryLabel;
@property (setter=_setPrimarySubtitleLabel:, getter=_primarySubtitleLabel, nonatomic, retain) UILabel *primarySubtitleLabel;
@property (getter=_secondaryLabel, nonatomic, readonly) UILabel *secondaryLabel;
@property (setter=_setSummaryLabel:, getter=_summaryLabel, nonatomic, retain) BSUIEmojiLabelView *summaryLabel;
@property (nonatomic, strong, readwrite) NSString *secondaryText; 
@property (nonatomic, retain) UILabel *summaryLabelCopy;
@end

@interface PBHeaderView : UIView
@property (nonatomic, retain) UIButton *iconButton;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@end

@interface NCNotificationShortLookView : PLPlatterView
@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, retain) UIView *backgroundMaterialView;
@property (nonatomic, retain) PBHeaderView *otherHeaderView;
@property (nonatomic, retain) NCNotificationContentView *notificationContentView;
@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) NSString *secondaryText;
@property (nonatomic, retain) NSString *originalSecondaryText;
@property (nonatomic, assign) unsigned long long maximumNumberOfSecondaryTextLines; 
- (PLPlatterHeaderContentView *)_headerContentView;
- (NCNotificationContentView *)_notificationContentView;
- (void)updateFrame;
@end

@interface NCNotificationViewControllerView : UIView
@property (nonatomic, strong) NCNotificationShortLookView *contentView;
@end

@interface NCNotificationContent : NSObject
@property (nonatomic, assign) NSString *header;
@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) NSString *message;
@property (nonatomic, assign) NSArray<UIImage *> *icons;
@end

@interface NCNotificationRequest : NSObject
- (NCNotificationContent *)content;
@end

@interface PLClickPresentationInteractionManager : NSObject
@property (nonatomic, assign) BOOL hasCommittedToPresentation;
@end

@interface NCNotificationViewController : UIViewController
- (UIView *)_longLookViewIfLoaded;
@end

@interface NCNotificationLongLookViewController : NCNotificationViewController
@end

@interface NCNotificationShortLookViewController : NCNotificationViewController
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) NCNotificationShortLookView *viewForPreview;
@property (nonatomic, strong) NCNotificationRequest *notificationRequest;
@property (nonatomic,readonly) PLClickPresentationInteractionManager * clickPresentationInteractionManager;                                                   //@synthesize scrollView=_scrollView - In the implementation block
@property (getter=_presentedLongLookViewController,nonatomic,readonly) NCNotificationViewController * presentedLongLookViewController; 
@property (nonatomic, retain) UIImageView *backgroundImageView;
@property (nonatomic, retain) UIView *backgroundColorView;
- (void)_presentLongLookForScrollAnimated:(BOOL)arg1 completion:(/*^block*/id)arg2 ;
- (BOOL)_didScrollPresentLongLookViewController;
@end

@interface CAFilter : NSObject
+ (CAFilter*)filterWithType:(NSString*)type;
+ (CAFilter*)filterWithName:(NSString*)name;
- (id)initWithType:(NSString*)type;
- (id)initWithName:(NSString*)name;
- (void)setDefaults;
@end

@interface UILabel (Pokebox)
@property (nonatomic, assign) BOOL lightModeEnabled;
@property (nonatomic, assign) BOOL darkModeEnabled;
- (void)enableDarkMode:(BOOL)enable;
@end
