#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <GraphicsServices/GraphicsServices.h>
#import <dlfcn.h>
#import <substrate.h>

#define kSTKTweakName @"Apex"
#define DLog(fmt, ...) NSLog((@"[%@] %s [Line %d] " fmt), kSTKTweakName, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define CLog(fmt, ...) NSLog((@"[%@] " fmt), kSTKTweakName, ##__VA_ARGS__)


static NSMutableArray *_stackedIconIdentifiers = nil;

void STKUpdateIdentifiers(void)
{
    static NSString * const LayoutsDirectory = @"/User/Library/Preferences/Apex/Layouts/";

    [_stackedIconIdentifiers release];
    _stackedIconIdentifiers = [NSMutableArray new];

    NSError *error = nil;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:LayoutsDirectory error:&error];

    for (NSString *file in contents) {
        NSString *fullPath = [LayoutsDirectory stringByAppendingString:file];
        NSDictionary *layout = [NSDictionary dictionaryWithContentsOfFile:fullPath];
        NSArray *stackIcons = layout[@"STKStackIcons"];
        if (stackIcons) {
            [_stackedIconIdentifiers addObjectsFromArray:stackIcons];
        }
    }
}

CFPropertyListRef (*original_GSSystemCopyCapability)(CFStringRef cap);
CFPropertyListRef new_GSSystemCopyCapability(CFStringRef cap)
{
    CFPropertyListRef ret = original_GSSystemCopyCapability(cap);
    
    if (cap == NULL) {
        NSMutableDictionary *capabilites = [(NSDictionary *)ret mutableCopy];
        NSMutableArray *displayIDs = [[(NSArray *)[capabilites objectForKey:(NSString *)kGSDisplayIdentifiersCapability] mutableCopy] autorelease];
        if (displayIDs && _stackedIconIdentifiers) {
            [displayIDs addObjectsFromArray:_stackedIconIdentifiers];
        }

        capabilites[(NSString *)kGSDisplayIdentifiersCapability] = displayIDs;
        return capabilites;
    }

    if (CFStringCompare(cap, kGSDisplayIdentifiersCapability, 0) == kCFCompareEqualTo) {
        NSMutableArray *identifiers = [[NSMutableArray arrayWithArray:(NSArray *)ret] retain];
        if (_stackedIconIdentifiers) {
            [identifiers addObjectsFromArray:_stackedIconIdentifiers];
        }
        
        return (CFPropertyListRef)identifiers;
    }

    return ret;
}

static __attribute__((constructor)) void _construct(void)
{
    @autoreleasepool {
        STKUpdateIdentifiers();

        [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/GraphicsServices.framework"] load];
        void *func = (void *)dlsym(RTLD_DEFAULT, "GSSystemCopyCapability");
        MSHookFunction(func, (void *)new_GSSystemCopyCapability, (void **)&original_GSSystemCopyCapability);     
    }
}
