//
//  BGSubscribeViewController.m
//  Bettergram
//
//  Created by Dukhov Philip on 9/5/18.
//

#import "BGSubscribeViewController.h"

#import "STPEmailAddressValidator.h"
#import "RMIntroViewController.h"
#import "TGCryptoManager.h"

@interface BGSubscribeViewController () <UITextFieldDelegate> {
    UIView *_backgroudView;
    UIImageView *_logoImageView;
    UITextField *_emailTextField;
    UIButton *_signUpButton;
    UIButton *_termsButton;
    UIButton *_newsletterButton;
}

@end

static const CGFloat kButtonTFHeight = 54;

@implementation BGSubscribeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIFont *font = TGMediumSystemFontOfSize(14);
    
    _backgroudView = [[UIImageView alloc] initWithImage:TGImageNamed(@"splash_background.png")];
    [self.view addSubview:_backgroudView];
    
    _logoImageView = [[UIImageView alloc] initWithImage:TGImageNamed(@"logo_big.png")];
    [self.view addSubview:_logoImageView];
    
    _emailTextField = [[UITextField alloc] init];
    _emailTextField.delegate = self;
    [_emailTextField addTarget:self
                        action:@selector(textFieldDidChange:)
              forControlEvents:UIControlEventEditingChanged];
    _emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    if (iosMajorVersion() >= 10) {
        _emailTextField.textContentType = UITextContentTypeEmailAddress;
    }
    _emailTextField.returnKeyType = UIReturnKeyDone;
    _emailTextField.textColor = UIColorRGB(0x828282);
    _emailTextField.font = font;
    _emailTextField.layer.cornerRadius = 8;
    _emailTextField.backgroundColor = UIColor.whiteColor;
    _emailTextField.placeholder = TGLocalized(@"Bettergram.SignUp.TextfieldPlaceholder");
    _emailTextField.textAlignment = NSTextAlignmentCenter;
    _emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _emailTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    _emailTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.view addSubview:_emailTextField];
    
    _signUpButton = [[UIButton alloc] init];
    [_signUpButton addTarget:self action:@selector(signUpButtonTap) forControlEvents:UIControlEventTouchUpInside];
    [_signUpButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(kButtonTFHeight, kButtonTFHeight), false, 0.0f);
        CGContextRef contextRef = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(contextRef, UIColorRGB(0x219E56).CGColor);
        CGContextFillEllipseInRect(contextRef, CGRectMake(0, 0, kButtonTFHeight, kButtonTFHeight));
        UIImage *startButtonImage = [UIGraphicsGetImageFromCurrentImageContext() stretchableImageWithLeftCapWidth:24 topCapHeight:24];
        UIGraphicsEndImageContext();
        
        [_signUpButton setBackgroundImage:startButtonImage forState:UIControlStateNormal];
        [_signUpButton setContentEdgeInsets:UIEdgeInsetsMake(0, 20, 0, 20)];
    }
    _signUpButton.layer.shadowColor = UIColorRGB(0x2D2D2D).CGColor;
    _signUpButton.layer.shadowOpacity = 0.2f;
    _signUpButton.layer.shadowOffset = CGSizeMake(0, 2);
    _signUpButton.layer.shadowRadius = 4;
    [_signUpButton setTitle:TGLocalized(@"Bettergram.SignUp.ButtonTitle") forState:UIControlStateNormal];
    _signUpButton.titleLabel.clipsToBounds = false;
    _signUpButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _signUpButton.adjustsImageWhenHighlighted = NO;
    [self.view addSubview:_signUpButton];
    
    _termsButton = [self createCheckboxButton];
    _termsButton.selected = YES;
    [_termsButton setTitle:TGLocalized(@"Bettergram.SignUp.Terms") forState:UIControlStateNormal];
    [self.view addSubview:_termsButton];
    
    _newsletterButton = [self createCheckboxButton];
    [_newsletterButton setTitle:TGLocalized(@"Bettergram.SignUp.Newsletter") forState:UIControlStateNormal];
    [self.view addSubview:_newsletterButton];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGSize viewSize = self.view.bounds.size;
    
    _backgroudView.frame = CGRectMake(0, 0, viewSize.width, viewSize.height);
    
    _emailTextField.frame = CGRectMake(viewSize.width * 0.05, viewSize.height / 2 - kButtonTFHeight,
                                       viewSize.width * 0.9, kButtonTFHeight);    
    {
        CGRect frame = CGRectZero;
        frame.size = _logoImageView.image.size;
        frame.origin.x = (viewSize.width - frame.size.width)/2;
        frame.origin.y = (_emailTextField.frame.origin.y - frame.size.height) * 0.7;
        _logoImageView.frame = frame;
    }{
        CGRect frame = CGRectZero;
        frame.size = CGSizeMake(viewSize.width * 0.48, kButtonTFHeight);
        frame.origin.x = (viewSize.width - frame.size.width)/2;
        frame.origin.y = CGRectGetMaxY(_emailTextField.frame) + 23;
        _signUpButton.frame = frame;
    }{
        CGRect(^baseButtonFrame)(UIButton *) = ^(UIButton *button) {
            CGRect frame = CGRectZero;
            frame.size = [button sizeThatFits:button.frame.size];
            frame.size.height = MAX(frame.size.height, 45);
            frame.size.width = MIN(frame.size.width + button.titleEdgeInsets.left, viewSize.width * 0.9);
            frame.origin.x = (viewSize.width - frame.size.width)/2;
            return frame;
        };
        
        CGRect newsletterFrame = baseButtonFrame(_newsletterButton);
        newsletterFrame.origin.y = viewSize.height - newsletterFrame.size.height - MAX(33, self.controllerSafeAreaInset.bottom);
        
        CGRect termsFrame = baseButtonFrame(_termsButton);
        termsFrame.origin.y = newsletterFrame.origin.y - termsFrame.size.height;
        
        newsletterFrame.origin.x = termsFrame.origin.x = MIN(termsFrame.origin.x, newsletterFrame.origin.x);
        
        _newsletterButton.frame = newsletterFrame;
        _termsButton.frame = termsFrame;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (void)checkboxButtonTap:(UIButton *)button
{
    button.selected = !button.selected;
    button.titleLabel.textColor = nil;
}

- (void)signUpButtonTap
{
    BOOL isValid = YES;
    if (!_termsButton.isSelected) {
        isValid = NO;
        [self shake:_termsButton direction:1 shakes:0];
    }
    if (![self textFieldShouldReturn:_emailTextField]) {
        isValid = NO;
        [self shake:_emailTextField direction:1 shakes:0];
    }
    if (isValid) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"bettergramGotEmail"];
        [TGCryptoManager.manager subscribeToListsWithEmail:self.cleanEmailString includeCrypto:_newsletterButton.isSelected];
        [self.navigationController setViewControllers:@[[[RMIntroViewController alloc] init]] animated:YES];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidChange:(UITextField *)__unused textField
{
    BOOL isValid = [STPEmailAddressValidator stringIsValidPartialEmailAddress:self.cleanEmailString];
    _emailTextField.textColor = isValid ? UIColorRGB(0x828282) : UIColorRGB(0xFF7764);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField endEditing:YES];
    if (![STPEmailAddressValidator stringIsValidEmailAddress:self.cleanEmailString]) {
        _emailTextField.textColor = UIColorRGB(0xFF7764);
        return NO;
    }
    return YES;
}

#pragma mark - Helpers

- (NSString *)cleanEmailString
{
    return [_emailTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].lowercaseString;
}

- (UIButton *)createCheckboxButton
{
    UIButton *button = [[UIButton alloc] init];
    
    UIImage *checkMarkImage = TGImageNamed(@"check_mark.png");
    UIGraphicsBeginImageContextWithOptions(checkMarkImage.size, false, 0.0f);
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(contextRef, UIColor.whiteColor.CGColor);
    CGContextFillRect(contextRef, CGRectMake(0, 0, kButtonTFHeight, kButtonTFHeight));
    UIImage *whiteRectImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [button setImage:whiteRectImage forState:UIControlStateNormal];
    [button setImage:checkMarkImage forState:UIControlStateSelected];
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    [button addTarget:self action:@selector(checkboxButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    button.titleLabel.font = TGMediumSystemFontOfSize(14);
    button.adjustsImageWhenHighlighted = NO;
    return button;
}

-(void)shake:(UIView *)theOneYouWannaShake direction:(int)direction shakes:(int)shakes
{
    [UIView animateWithDuration:0.06
                     animations:^
     {
         theOneYouWannaShake.transform = CGAffineTransformMakeTranslation(theOneYouWannaShake.frame.size.width * 0.01 * direction, 0);
     }
                     completion:^(__unused BOOL finished)
     {
         if(shakes >= 5)
         {
             theOneYouWannaShake.transform = CGAffineTransformIdentity;
             return;
         }
         [self shake:theOneYouWannaShake
           direction:direction * -1
              shakes:shakes + 1];
     }];
}

@end
