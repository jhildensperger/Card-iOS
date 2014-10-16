//
//  ZYViewController.m
//  Card-iOS
//
//  Created by James Hildensperger on 6/11/14.
//  Copyright (c) 2014 Zymurgical. All rights reserved.
//

#import "ZYViewController.h"
#import "UIFont+Additions.h"
#import "ReactiveCocoa.h"
#import "BlocksKit+UIKit.h"

@interface ZYInputLabel ()

@property (nonatomic, copy) id(^mappingBlock)(id field);

@end

@implementation ZYInputLabel

@end

@interface CardView ()

@property (nonatomic) NSArray *inputLabels;
@property (nonatomic) ZYInputLabel *activeInputLabel;

@end

@implementation CardView

+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay curve:(UIViewAnimationCurve)curve animations:(void (^)(void))animations {
    if (!animations) return;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationDelay:delay];
    [UIView setAnimationCurve:curve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    animations();
    [UIView commitAnimations];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupKeyboardNotifications];
    [self setupStepperBinding];
    [self setupCardNumberLabelBinding];
    [self setupNameLabelBinding];
    [self setupExpirationLabelBinding];
    [self setupCvcLabelBinding];

    self.inputLabels = @[self.cardNumberLabel, self.nameLabel, self.exprirationLabel, self.cvcLabel];
    
    [self.inputLabels enumerateObjectsUsingBlock:^(ZYInputLabel *inputLabel, NSUInteger idx, BOOL *stop) {
        UITapGestureRecognizer *cardNumberTapGestureRecognizer = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            self.inputFieldStepper.value = idx;
            [self.inputFieldStepper sendActionsForControlEvents:UIControlEventValueChanged];
        }];
        [inputLabel addGestureRecognizer:cardNumberTapGestureRecognizer];
    }];
}

- (void)setupKeyboardNotifications {
    RACSignal *keyboardWillShowOrHide = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] merge:[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillHideNotification object:nil]];
    [[keyboardWillShowOrHide takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id x) {
        BOOL isWillShowNotification = [[x name] isEqualToString:UIKeyboardWillShowNotification];
        CGFloat duration = [[x userInfo][UIKeyboardAnimationDurationUserInfoKey] floatValue];
        NSUInteger curve = [[x userInfo][UIKeyboardAnimationCurveUserInfoKey] integerValue];
        CGRect endFrame = [[x userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
        [CardView animateWithDuration:duration delay:0 curve:curve animations:^{
            self.inputFieldContainerView.alpha = isWillShowNotification;
            self.inputFieldContainerView.center = CGPointMake(self.inputFieldContainerView.center.x, CGRectGetMinY(endFrame) - self.inputFieldContainerView.frame.size.height/2);
        }];
    }];
}

- (void)setupStepperBinding {
    [self.inputFieldStepper bk_addEventHandler:^(UIStepper *stepper) {
        ZYInputLabel *inputLabel = self.inputLabels[(int)stepper.value];
        self.activeInputLabel = inputLabel;
        
        self.inputField.keyboardType = inputLabel.keyboardType;
        self.inputField.placeholder = inputLabel.placeHolder;
        [self.inputField reloadInputViews];
        
        RACSignal *textSignal = [self.inputField.rac_textSignal map:inputLabel.mappingBlock];
        [inputLabel rac_liftSelector:@selector(setText:) withSignals:textSignal, nil];
        
        [self.inputField becomeFirstResponder];
        self.inputField.text = nil;
    } forControlEvents:UIControlEventValueChanged];
}

- (void)setupCardNumberLabelBinding {
    self.cardNumberLabel.keyboardType = UIKeyboardTypeNumberPad;
    self.cardNumberLabel.placeHolder = @"●●●● ●●●● ●●●● ●●●●";
    self.cardNumberLabel.mappingBlock = ^id(id value) {
        if ([value isEqualToString:@""]) {
            self.cardNumberLabel.font = [UIFont creditCardFontOfSize:19];
            return self.cardNumberLabel.placeHolder;
        }
        
        NSString *processedValue = [self.class formatString:value];
        BOOL isValid = [self.class validateString:processedValue];
        self.cardNumberLabel.textColor = [[UIColor lightGrayColor] colorWithAlphaComponent:isValid ? 1 : .5];
        self.cardNumberLabel.font = [UIFont creditCardFontOfSize:15];
        
        __block NSString *type;
        [[self.class creditCards] enumerateObjectsUsingBlock:^(NSDictionary *cardInfo, NSUInteger idx, BOOL *stop) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", cardInfo[@"pattern"]];
            if ([predicate evaluateWithObject:processedValue]) {
                type = cardInfo[@"type"];
                *stop = YES;
            }
        }];
        
        static NSString *imageName;
        if (![imageName isEqualToString:type]) {
            if (type) {
                self.cardTypeImageView.image = [UIImage imageNamed:type];
                [UIView animateWithDuration:.5 animations:^{
                    self.cardTypeImageView.alpha = 1;
                }];
            } else if (self.cardTypeImageView.alpha) {
                [UIView animateWithDuration:.25 animations:^{
                    self.cardTypeImageView.alpha = 0;
                } completion:^(BOOL finished) {
                    self.cardTypeImageView.image = nil;
                }];
            }
            
            imageName = type;
        }
        
        if (4 < [processedValue length] && [processedValue length] <= 8) {
            processedValue = [processedValue stringByReplacingCharactersInRange:NSMakeRange(4, 0) withString:@" "];
        } else if (8 < [processedValue length] && [processedValue length] <= 12) {
            processedValue = [processedValue stringByReplacingCharactersInRange:NSMakeRange(4, 0) withString:@" "];
            processedValue = [processedValue stringByReplacingCharactersInRange:NSMakeRange(9, 0) withString:@" "];
        } else if ([processedValue length] >= 13) {
            processedValue = [processedValue stringByReplacingCharactersInRange:NSMakeRange(4, 0) withString:@" "];
            processedValue = [processedValue stringByReplacingCharactersInRange:NSMakeRange(9, 0) withString:@" "];
            processedValue = [processedValue stringByReplacingCharactersInRange:NSMakeRange(14, 0) withString:@" "];
        }
        self.inputField.text = processedValue;
        return processedValue;
    };
}

- (void)setupNameLabelBinding {
    self.nameLabel.mappingBlock = ^id(id value) {
        if ([value isEqualToString:@""]) {
            return @"NAME ON CARD";
        }
        return [value uppercaseString];
    };
}

- (void)setupExpirationLabelBinding {
    self.exprirationLabel.keyboardType = UIKeyboardTypeNumberPad;
    self.exprirationLabel.mappingBlock = ^id(id value) {
        static NSString *slashString = @" / ";
        if ([value isEqualToString:@""]) {
            return @"●● / ●●";
        }
        
        if ([value length] == 2) {
            self.inputField.text = [value stringByReplacingCharactersInRange:NSMakeRange(2, 0) withString:slashString];
        } else if ([value length] == 5) {
            self.inputField.text = [value stringByReplacingOccurrencesOfString:slashString withString:@""];
        }
        return self.inputField.text;
    };
}

- (void)setupCvcLabelBinding {
    self.cvcLabel.keyboardType = UIKeyboardTypeNumberPad;
    self.cvcLabel.mappingBlock = ^id(id value) {
        if ([value isEqualToString:@""]) {
            return @"●●●";
        }
        return [value uppercaseString];
    };
}

+ (NSArray *)creditCards {
    static NSArray *creditCards;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        creditCards = @[@{
                            @"type": @"diners",
                            @"pattern": @"^3(?:0[0-5]|[68][0-9])[0-9]{4,}$",
                            @"format": @"defaultFormat",
                            @"length": @[@14],
                            @"cvcLength": @[@3]
                            }, @{
                            @"type": @"jcb",
                            @"pattern": @"^(?:2131|1800|35[0-9]{3})[0-9]{3,}$",
                            @"format": @"defaultFormat",
                            @"length": @[@16],
                            @"cvcLength": @[@3]
                            }, @{
                            @"type": @"discover",
                            @"pattern": @"^6(?:011|5[0-9]{2})[0-9]{3,}$",
                            @"format": @"defaultFormat",
                            @"length": @[@16],
                            @"cvcLength": @[@3]
                            }, @{
                            @"type:": @"mastercard",
                            @"pattern": @"^5[1-5][0-9]{5,}$",
                            @"format": @"defaultFormat",
                            @"length": @[@16],
                            @"cvcLength": @[@3]
                            }, @{
                            @"type": @"amex",
                            @"pattern": @"^3[47][0-9]{5,}$",
                            @"format": @"/(\\d{1,4})(\\d{1,6})?(\\d{1,5})?/@",
                            @"length": @[@15],
                            @"cvcLength": @[@3, @4]
                            }, @{
                            @"type": @"visa",
                            @"pattern": @"^4[0-9]{6,}$",
                            @"format": @"defaultFormat",
                            @"length": @[@13, @16],
                            @"cvcLength": @[@3]
                            }];
    });
    return creditCards;
}

+ (BOOL)validateString:(NSString *)string {
    if (!string || string.length < 9) {
        return NO;
    }
    
    NSMutableString *reversedString = [NSMutableString stringWithCapacity:[string length]];
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length]) options:(NSStringEnumerationReverse |NSStringEnumerationByComposedCharacterSequences) usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        [reversedString appendString:substring];
    }];
    
    NSUInteger oddSum = 0, evenSum = 0;
    
    for (NSUInteger i = 0; i < [reversedString length]; i++) {
        NSInteger digit = [[NSString stringWithFormat:@"%C", [reversedString characterAtIndex:i]] integerValue];
        
        if (i % 2 == 0) {
            evenSum += digit;
        } else {
            oddSum += digit / 5 + (2 * digit) % 10;
        }
    }
    return (oddSum + evenSum) % 10 == 0;
}

+ (NSString *)formatString:(NSString *)string {
    NSCharacterSet *illegalCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray *components = [string componentsSeparatedByCharactersInSet:illegalCharacters];
    return [components componentsJoinedByString:@""];
}

@end

@interface ZYViewController ()

@end

@implementation ZYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureCardView];
    
    [UIView animateWithDuration:.5 delay:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.cardView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"shattered_100"]];
        self.cardView.layer.shadowOpacity = .5;
        self.cardView.layer.shadowRadius = 5;
        self.cardView.layer.shadowOffset = CGSizeZero;
    } completion:nil];
    self.cardView.layer.cornerRadius = 9.0f;
}


- (void)configureCardView {
    self.cardView.cardNumberLabel.font = [UIFont creditCardFontOfSize:16];
    self.cardView.cardNumberLabel.userInteractionEnabled = YES;
    self.cardView.nameLabel.font = [UIFont creditCardFontOfSize:17];
    self.cardView.nameLabel.userInteractionEnabled = YES;
    self.cardView.exprirationLabel.font = [UIFont creditCardFontOfSize:12];
    self.cardView.exprirationLabel.userInteractionEnabled = YES;
    self.cardView.cvcLabel.font = [UIFont creditCardFontOfSize:15];
}

#pragma mark - actions 
- (IBAction)didSwipeCard:(id)sender {
   UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:@"Submit Card" message:@"This will send me your credit information"];
    [alertView bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
    [alertView bk_addButtonWithTitle:@"Yes" handler:^{
//        [self.cardFields enumerateObjectsUsingBlock:^(UITextField *textfield, NSUInteger idx, BOOL *stop) {
//            textfield.text = @"";
//            [textfield sendActionsForControlEvents:UIControlEventEditingChanged];
//        }];
    }];
    [alertView show];
}

- (IBAction)didTapSendButton:(id)sender {
    [self.cardView.inputField resignFirstResponder];
}

@end
