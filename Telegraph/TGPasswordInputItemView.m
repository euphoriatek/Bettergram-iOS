#import "TGPasswordInputItemView.h"

#import <LegacyComponents/LegacyComponents.h>

#import <LegacyComponents/TGTextField.h>

#import "TGPresentation.h"

@interface TGPasswordInputItemView () <UITextFieldDelegate>
{
    TGTextField *_textField;
}

@end

@implementation TGPasswordInputItemView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        _textField = [[TGTextField alloc] init];
        _textField.delegate = self;
        _textField.textColor = [UIColor blackColor];
        _textField.font = TGSystemFontOfSize(18.0f);
        _textField.placeholderFont = _textField.font;
        _textField.placeholderColor = UIColorRGB(0xbfbfbf);
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _textField.backgroundColor = [UIColor clearColor];
        _textField.leftInset = 15.0f;
        _textField.rightInset = 15.0f;
        _textField.secureTextEntry = true;
        [self.contentView addSubview:_textField];
    }
    return self;
}

- (void)setPresentation:(TGPresentation *)presentation
{
    [super setPresentation:presentation];
    
    _textField.textColor = presentation.pallete.collectionMenuTextColor;
    _textField.placeholderColor = presentation.pallete.collectionMenuPlaceholderColor;
    _textField.keyboardAppearance = presentation.pallete.prefersDarkKeyboard ? UIKeyboardAppearanceAlert : UIKeyboardAppearanceDefault;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _textField.placeholder = placeholder;
}

- (void)setPassword:(NSString *)password
{
    _textField.text = password;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _textField.frame = CGRectMake(self.safeAreaInset.left, 4.0f, self.contentView.frame.size.width - self.safeAreaInset.left - self.safeAreaInset.right, self.contentView.frame.size.height - 8);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (_passwordChanged)
        _passwordChanged(string.length == 0 ? @"" : text);
    
    return true;
}

- (BOOL)textFieldShouldClear:(UITextField *)__unused textField
{
    if (_passwordChanged)
        _passwordChanged(@"");
    
    return true;
}

- (void)makeTextFieldFirstResponder
{
    [_textField becomeFirstResponder];
}

@end
