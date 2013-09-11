#import "STKPrefsController.h"
#import "Localization.h"
#import "Globals.h"
#import "../STKConstants.h"

#define BETA NO

#define TEXT_COLOR [UIColor colorWithRed:76/255.0f green:86/255.0f blue:106/255.0f alpha:1.0f]
#define TEXT_LARGE_FONT [UIFont fontWithName:@"HelveticaNeue" size:72.0f]
#define TEXT_FONT [UIFont fontWithName:@"HelveticaNeue" size:15.0f]

#define TEXT_SHADOW_OFFSET CGSizeMake(0, 1)
#define TEXT_SHADOW_COLOR [UIColor whiteColor]

@implementation STKPrefsController

- (id)initForContentSize:(CGSize)size
{
	if ([PSViewController instancesRespondToSelector:@selector(initForContentSize:)])
		self = [super initForContentSize:size];
	else
		self = [super init];
	
	if (self)
	{
		NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/ApexSettings.bundle"];
		UIImage *image = [UIImage imageNamed:@"GroupLogo.png" inBundle:bundle];
		UINavigationItem *item = self.navigationItem;
		item.titleView = [[[UIImageView alloc] initWithImage:image] autorelease];
		
		UIImage *heart = [UIImage imageNamed:@"Heart.png" inBundle:bundle];
		UIButton *buttonView = [[[UIButton alloc] initWithFrame:(CGRect){CGPointZero, {heart.size.width + 12, heart.size.height}}] autorelease];
		[buttonView setImage:heart forState:UIControlStateNormal];
		[buttonView addTarget:self action:@selector(showHeartDialog) forControlEvents:UIControlEventTouchUpInside];
		UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithCustomView:buttonView] autorelease];
		item.rightBarButtonItem = button;
	}
	return self;
}

- (id)specifiers
{
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"ApexSettings" target:self] retain];
	}
	return _specifiers;
}

- (NSArray *)loadSpecifiersFromPlistName:(NSString *)plistName target:(id)target
{
	// Always make the target self so that things will resolve properly
	NSArray *result = [super loadSpecifiersFromPlistName:plistName target:self];

	CLog(@"%@ %@ %@", plistName, target, result);

	for (PSSpecifier *specifier in result) {
		[specifier setName:Localize([specifier name])];
		NSString *footerText = [specifier propertyForKey:@"footerText"];
		if ([footerText isKindOfClass:[NSString class]]) {
			[specifier setProperty:Localize(footerText) forKey:@"footerText"];
		}
	}
	return result;
}

- (id)navigationTitle
{
	return @"Apex";
}

- (NSString *)title
{    
	return @"Apex";
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, -6.0f, 320.0f, 84.0f)];
	label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	label.layer.contentsGravity = kCAGravityCenter;
	label.backgroundColor = [UIColor clearColor];
	label.textAlignment = NSTextAlignmentCenter;
	label.numberOfLines = 0;
	label.lineBreakMode = NSLineBreakByWordWrapping;
	label.textColor = TEXT_COLOR;
	label.font = [UIFont systemFontOfSize:72.0f];
	label.shadowColor = [UIColor whiteColor];
	label.shadowOffset = CGSizeMake(0, 1);
	label.text = @"Apex";
	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 54.0f)];
	[header addSubview:label];
	[label release];
	[self table].tableHeaderView = header;
	[header release];
	for (PSSpecifier *specifier in self.specifiers) {
		specifier.target = self;
	}
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)showHeartDialog
{
	if ([TWTweetComposeViewController canSendTweet])
	{        
		TWTweetComposeViewController *controller = [[TWTweetComposeViewController alloc] init];
		controller.completionHandler = ^(TWTweetComposeViewControllerResult res) {
			[controller dismissModalViewControllerAnimated:YES];            
			[controller release];
		};
		[controller setInitialText:LOCALIZE(LOVE_GAMES)];
		
		UIViewController *presentController = self;
		[presentController presentViewController:controller animated:YES completion:NULL];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALIZE(CANNOT_SEND_TWEET) message:LOCALIZE(CANNOT_SEND_TWEET_DETAILS) delegate:nil cancelButtonTitle:LOCALIZE(OK) otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}
#pragma GCC diagnostic pop

static inline void LoadDeviceKey(NSMutableDictionary *dict, NSString *key)
{
	id result = [[UIDevice currentDevice] deviceInfoForKey:key];
	if (result) {
		[dict setObject:result forKey:key];
	}
}

- (void)showMailDialog
{
	if ([MFMailComposeViewController canSendMail])
	{
		MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
		mailViewController.mailComposeDelegate = self;
		[mailViewController setSubject:LOCALIZE(APEX_SUPPORT)];
		[mailViewController setToRecipients:[NSArray arrayWithObject:@"apexsupport@a3tweaks.com"]];
		NSString *filePath = kPrefPath;

		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:filePath] ?: [NSMutableDictionary dictionary];
		LoadDeviceKey(dict, @"UniqueDeviceID");
		LoadDeviceKey(dict, @"ProductVersion");
		LoadDeviceKey(dict, @"ProductType");
		LoadDeviceKey(dict, @"DiskUsage");
		LoadDeviceKey(dict, @"DeviceColor");
		LoadDeviceKey(dict, @"CPUArchitecture");

#ifdef kPackageVersion
		[dict setObject:@kPackageVersion forKey:@"Version"];
#endif
		NSString *packageDetails = [NSString stringWithContentsOfFile:@"/var/lib/dpkg/status" encoding:NSUTF8StringEncoding error:NULL];
		if (packageDetails) {
			[dict setObject:packageDetails forKey:@"Packages"];
		}
		NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
		if (data) {
			[mailViewController addAttachmentData:data mimeType:@"application/x-plist" fileName:[filePath lastPathComponent]];
		}
		[self presentViewController:mailViewController animated:YES completion:NULL];
		[mailViewController release];
	}
	else{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALIZE(CANNOT_SEND_MAIL) message:LOCALIZE(CANNOT_SEND_MAIL_DETAILS) delegate:nil cancelButtonTitle:LOCALIZE(OK) otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{              
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end