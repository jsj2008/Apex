#import "STKPreferences.h"
#import "STKConstants.h"
#import "STKStackManager.h"

#import <SpringBoard/SpringBoard.h>
#import <objc/runtime.h>

@interface STKPreferences ()
{
    NSDictionary *_currentPrefs;
    NSArray      *_layouts;
    NSArray      *_iconsInGroups;
}

- (void)_refreshGroupedIcons;

@end

@implementation STKPreferences

+ (instancetype)sharedPreferences
{
    static id sharedInstance;
    
    if (!sharedInstance) {
        sharedInstance = [[self alloc] init];
        [sharedInstance reloadPreferences];
        [[NSFileManager defaultManager] createDirectoryAtPath:[STKStackManager layoutsPath] withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions : @511} error:NULL];
        [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions : @511} ofItemAtPath:[STKStackManager layoutsPath] error:NULL]; // Make sure the permissions are correct anyway
    }

    return sharedInstance;
}

- (NSArray *)identifiersForIconsWithStack
{
    static NSString *fileType = @".layout";
    NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:_layouts.count];

    for (NSString *layout in _layouts) {
        if ([layout hasSuffix:fileType]) {
            [identifiers addObject:[layout substringToIndex:(layout.length - fileType.length)]];
        }
    }
    return identifiers;
}

- (NSArray *)stackIconsForIcon:(SBIcon *)icon
{
    SBIconModel *model = [(SBIconController *)[objc_getClass("SBIconController") sharedInstance] model];

    NSDictionary *attributes = [NSDictionary dictionaryWithContentsOfFile:[self layoutPathForIcon:icon]];

    NSMutableArray *stackIcons = [NSMutableArray arrayWithCapacity:(((NSArray *)attributes[STKStackManagerStackIconsKey]).count)];
    for (NSString *identifier in attributes[STKStackManagerStackIconsKey]) {
        // Get the SBIcon instances for the identifiers
        [stackIcons addObject:[model applicationIconForDisplayIdentifier:identifier]];
    }
    return stackIcons;
}

- (NSString *)layoutPathForIconID:(NSString *)iconID
{
    return [NSString stringWithFormat:@"%@/%@.layout", [STKStackManager layoutsPath], iconID];
}

- (NSString *)layoutPathForIcon:(SBIcon *)icon
{
    return [self layoutPathForIconID:icon.leafIdentifier];
}

- (void)reloadPreferences
{
    [_currentPrefs release];
    [_layouts release];

    _currentPrefs = [[NSDictionary alloc] initWithContentsOfFile:kPrefPath];
    if (!_currentPrefs) {
        _currentPrefs = [[NSDictionary alloc] init];
    }

    _layouts = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[STKStackManager layoutsPath] error:nil] retain];
}

- (BOOL)iconHasStack:(SBIcon *)icon
{
    return [[self identifiersForIconsWithStack] containsObject:icon.leafIdentifier];
}

- (BOOL)iconIsInStack:(SBIcon *)icon
{
    if (!_iconsInGroups) {
        [self _refreshGroupedIcons];
    }

    return [_iconsInGroups containsObject:icon.leafIdentifier];
}

- (BOOL)saveLayoutWithCentralIcon:(SBIcon *)centralIcon stackIcons:(NSArray *)icons
{
    return [self saveLayoutWithCentralIconID:centralIcon.leafIdentifier stackIconIDs:[icons valueForKeyPath:@"leafIdentifier"]];
}

- (BOOL)saveLayoutWithCentralIconID:(NSString *)iconID stackIconIDs:(NSArray *)stackIconIDs
{
    NSDictionary *attributes = @{STKStackManagerCentralIconKey : iconID,
                                 STKStackManagerStackIconsKey  : stackIconIDs}; // KVC FTW

    BOOL success = [attributes writeToFile:[self layoutPathForIconID:iconID] atomically:YES];
    if (success) {
        // Only reload if the write succeeded, hence save IO operations
        [self reloadPreferences];
    }

    return success;
}

- (void)_refreshGroupedIcons
{
    [_iconsInGroups release];

    NSMutableArray *groupedIcons = [NSMutableArray array];
    NSArray *identifiers = [self identifiersForIconsWithStack];
    for (NSString *identifier in identifiers) {
        SBIcon *centralIcon = [[(SBIconController *)[objc_getClass("SBIconController") sharedInstance] model] applicationIconForDisplayIdentifier:identifier];
        [groupedIcons addObjectsFromArray:[(NSArray *)[self stackIconsForIcon:centralIcon] valueForKeyPath:@"leafIdentifier"]];
    }

     _iconsInGroups = [groupedIcons copy];
}

@end
