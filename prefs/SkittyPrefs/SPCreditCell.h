// SPCreditCell.h

#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
/*
@interface PSSpecifier (Properties)
@property (nonatomic, retain) NSMutableArray *properties;
@end
*/
@interface SPCreditCell : PSTableCell

@property (nonatomic, retain) UIImageView *creditImageView;
@property (nonatomic, assign) UIImage *creditImage;
@property (nonatomic, assign) NSString *twitterUsername;

@end
