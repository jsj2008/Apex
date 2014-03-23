#import "STKSelectionTitleTextField.h"
#import "STKConstants.h"

@implementation STKSelectionTitleTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.keyboardAppearance = UIKeyboardAppearanceDark;
        self.returnKeyType = UIReturnKeySearch;
        self.layer.cornerRadius = 10.f;
        self.layer.masksToBounds = YES;
        self.placeholder = @"Select Sub-App";
        self.textAlignment = NSTextAlignmentCenter;
        self.textColor = [UIColor colorWithWhite:1.0 alpha:0.5f];
        self.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24.f];
        self.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.3f];
        self.typingAttributes = @{
            NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:24.f],
            NSForegroundColorAttributeName: [UIColor whiteColor]
        };

        UIImageView *searchIconView = [[[UIImageView alloc] initWithImage:UIIMAGE_NAMED(@"Search@2x")] autorelease];
        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [clearButton addTarget:self action:@selector(_clearTextField) forControlEvents:UIControlEventTouchUpInside];
        UIImage *clearImage = UIIMAGE_NAMED(@"Clear@2x");
        [clearButton setImage:clearImage forState:UIControlStateNormal];
        clearButton.frame = (CGRect){CGPointZero, clearImage.size};

        self.leftViewMode = UITextFieldViewModeAlways;
        self.rightViewMode = UITextFieldViewModeWhileEditing;
        self.leftView = searchIconView;
        self.rightView = clearButton;
    }
    return self;
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    CGSize size = self.leftView.frame.size;
    return (CGRect){{11, ceilf(CGRectGetMidY(bounds) - (size.height * 0.5))}, size};
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    CGSize size = self.rightView.frame.size;
    return (CGRect){{255, ceilf(CGRectGetMidY(bounds) - (size.height * 0.5))}, size};
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect rect = [super editingRectForBounds:bounds];
    rect.origin.x += 11.f;
    return rect;
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    CGRect rect = [super placeholderRectForBounds:bounds];
    rect.origin.x -= 11.f;
    return rect;
}

- (void)_clearTextField
{
    self.text = @"";
}

@end
