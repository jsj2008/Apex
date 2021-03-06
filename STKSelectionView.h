#import <UIKit/UIKit.h>

typedef void(^STKSelectionViewSelectionHandler)(void);

@class SBIcon, SBIconView, SBFolderBackgroundView;
@interface STKSelectionView : UIView <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UITextFieldDelegate>

- (instancetype)initWithFrame:(CGRect)frame selectedIcon:(SBIcon *)selectedIcon centralIcon:(SBIcon *)centralIcon;

@property (nonatomic, copy) NSArray *iconsForSelection;
@property (nonatomic, readonly) SBIcon *selectedIcon; // selectedIcon has to be in iconsForSelection
@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, readonly) UITextField *searchTextField;
@property (nonatomic, readonly) UIView *iconCollectionView;
@property (nonatomic, readonly) SBFolderBackgroundView *backgroundView;
@property (nonatomic, readonly) BOOL isKeyboardVisible;
@property (nonatomic, copy) STKSelectionViewSelectionHandler selectionHandler;

- (void)scrollToSelectedIconAnimated:(BOOL)animated;
- (void)flashScrollIndicators;

- (void)dismissKeyboard;

@end
