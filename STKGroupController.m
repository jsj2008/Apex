#import "STKGroupController.h"
#import "STKConstants.h"

@implementation STKGroupController
{
    STKGroupView *_openGroupView;
    UISwipeGestureRecognizer *_closeSwipeRecognizer;
    UITapGestureRecognizer *_closeTapRecognizer;
    BOOL _openGroupIsEditing;
}

+ (instancetype)sharedController
{
	static dispatch_once_t pred;
	static id _si;
	dispatch_once(&pred, ^{
		_si = [[self alloc] init];
	});
	return _si;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _closeTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_closeOpenGroupView)];
        _closeSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_closeOpenGroupView)];
        _closeSwipeRecognizer.direction = (UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown);
        _closeSwipeRecognizer.delegate = self;
        _closeTapRecognizer.delegate = self;
    }
    return self;
}

- (void)addGroupViewToIconView:(SBIconView *)iconView
{
    if (iconView.icon == [[CLASS(SBIconController) sharedInstance] grabbedIcon]) {
        return;
    }
    STKGroupView *groupView = nil;
    if ((groupView = [iconView groupView])) {
        SBIconCoordinate currentCoordinate = [STKGroupLayoutHandler coordinateForIcon:iconView.icon];
        [groupView.group relayoutForNewCoordinate:currentCoordinate];
        return;
    }

    STKGroup *group = [[STKPreferences preferences] groupForIcon:iconView.icon];
    if (!group) {
    	group = [self _groupWithEmptySlotsForIcon:iconView.icon];
    }
    group.lastKnownCoordinate = [STKGroupLayoutHandler coordinateForIcon:group.centralIcon];
    groupView = [[[STKGroupView alloc] initWithGroup:group] autorelease];
    groupView.delegate = self;
    [iconView setGroupView:groupView];
}

- (void)removeGroupViewFromIconView:(SBIconView *)iconView
{
    iconView.groupView = nil;
}

- (STKGroup *)_groupWithEmptySlotsForIcon:(SBIcon *)icon
{
	STKGroupLayout *slotLayout = [STKGroupLayoutHandler emptyLayoutForIconAtLocation:[STKGroupLayoutHandler locationForIcon:icon]];
	STKGroup *group = [[STKGroup alloc] initWithCentralIcon:icon layout:slotLayout];
    group.state = STKGroupStateEmpty;
	return [group autorelease];
}

- (UIScrollView *)_currentScrollView
{
    SBFolderController *currentFolderController = [[CLASS(SBIconController) sharedInstance] _currentFolderController];
    return [currentFolderController.contentView scrollView];
}

- (void)_closeOpenGroupView
{
    [_openGroupView close];
    [self _removeCloseGestureRecognizers];
}

- (void)_addCloseGestureRecognizers
{
    UIView *view = [[CLASS(SBIconController) sharedInstance] contentView];
    [view addGestureRecognizer:_closeSwipeRecognizer];
    [view addGestureRecognizer:_closeTapRecognizer];
}

- (void)_removeCloseGestureRecognizers
{
    [_closeTapRecognizer.view removeGestureRecognizer:_closeTapRecognizer];
    [_closeSwipeRecognizer.view removeGestureRecognizer:_closeSwipeRecognizer];
}

#pragma mark - Group View Delegate
- (BOOL)shouldGroupViewOpen:(STKGroupView *)groupView
{
    return !_openGroupView;
}

- (BOOL)groupView:(STKGroupView *)groupView shouldRecognizeGesturesSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)recognizer
{
    if (recognizer == _closeSwipeRecognizer || recognizer == _closeTapRecognizer) {
        return NO;
    }
    NSArray *targets = [recognizer valueForKey:@"_targets"];
    id target = ((targets.count > 0) ? targets[0] : nil);
    target = [target valueForKey:@"_target"];
    return (![target isKindOfClass:CLASS(SBSearchScrollView)] && [recognizer.view isKindOfClass:[UIScrollView class]]);
}

- (void)groupViewWillOpen:(STKGroupView *)groupView
{
    if (groupView.activationMode != STKActivationModeDoubleTap) {
        [self _currentScrollView].scrollEnabled = NO;
    }
}

- (void)groupViewDidOpen:(STKGroupView *)groupView
{
    _openGroupView = groupView;
    [self _addCloseGestureRecognizers];
    [[CLASS(SBSearchGesture) sharedInstance] setEnabled:NO];
    [self _currentScrollView].scrollEnabled = YES;
}

- (void)groupViewWillClose:(STKGroupView *)groupView
{
    [self _currentScrollView].scrollEnabled = YES;
}

- (void)groupViewDidClose:(STKGroupView *)groupView
{
    if (_openGroupIsEditing) {
        for (SBIconView *iconView in _openGroupView.subappLayout) {
            [iconView removeApexOverlay];
        }
    }
    [self _removeCloseGestureRecognizers];
    [[CLASS(SBSearchGesture) sharedInstance] setEnabled:YES];
    _openGroupView = nil;
}

- (BOOL)iconShouldAllowTap:(SBIconView *)iconView
{
    return YES;   
}

- (void)iconTapped:(SBIconView *)iconView
{
    if (_openGroupIsEditing) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [iconView setHighlighted:NO];
    });
    [iconView.icon launchFromLocation:SBIconLocationHomeScreen];
}

- (BOOL)iconViewDisplaysCloseBox:(SBIconView *)iconView
{
    return NO;
}

- (BOOL)iconViewDisplaysBadges:(SBIconView *)iconView
{
    return [[CLASS(SBIconController) sharedInstance] iconViewDisplaysBadges:iconView];
}

- (BOOL)icon:(SBIconView *)iconView canReceiveGrabbedIcon:(SBIcon *)grabbedIcon
{
    return NO;
}

- (void)iconHandleLongPress:(SBIconView *)iconView
{
    if ([iconView.icon isEmptyPlaceholder] || _openGroupView == nil) {
        return;
    }
    [iconView setHighlighted:NO];
    for (SBIconView *iconView in _openGroupView.subappLayout) {
        [iconView showApexOverlayOfType:STKOverlayTypeEditing];
    }
    _openGroupIsEditing = YES;
}

- (void)iconTouchBegan:(SBIconView *)iconView
{
    [iconView setHighlighted:YES];   
}

- (void)icon:(SBIconView *)iconView touchEnded:(BOOL)ended
{
    [iconView setHighlighted:NO];
}

#pragma mark - Gesture Recognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint point = [touch locationInView:_openGroupView];
    return !([_openGroupView hitTest:point withEvent:nil]);   
}

@end
