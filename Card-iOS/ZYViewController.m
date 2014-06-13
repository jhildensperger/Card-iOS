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
#import <BlocksKit/UIAlertView+BlocksKit.h>

@implementation CardView

@end

@interface ZYViewController ()

@end

@implementation ZYViewController

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
    
    [self.cardFields enumerateObjectsUsingBlock:^(UITextField *textfield, NSUInteger idx, BOOL *stop) {
        textfield.layer.borderColor = [UIColor colorWithWhite:0.800 alpha:1.000].CGColor;
        textfield.layer.borderWidth = 1;
        
        UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
        [textfield setLeftViewMode:UITextFieldViewModeAlways];
        [textfield setLeftView:spacerView];
        [textfield setRightViewMode:UITextFieldViewModeAlways];
        [textfield setRightView:spacerView];
    }];
}


- (void)configureCardView {
    self.cardView.cardNumberLabel.font = [UIFont creditCardFontOfSize:16];
    self.cardView.cardNumberLabel.userInteractionEnabled = YES;
    self.cardView.nameLabel.font = [UIFont creditCardFontOfSize:17];
    self.cardView.nameLabel.userInteractionEnabled = YES;
    self.cardView.exprirationLabel.font = [UIFont creditCardFontOfSize:12];
    self.cardView.exprirationLabel.userInteractionEnabled = YES;
    self.cardView.cvcLabel.font = [UIFont creditCardFontOfSize:15];
    
    RACSignal *cardNumberFieldSignal = [self.cardNumberField.rac_textSignal map:^id(id value) {
        if ([value isEqualToString:@""]) {
            self.cardView.cardNumberLabel.font = [UIFont creditCardFontOfSize:19];
            return @"●●●● ●●●● ●●●● ●●●●";
        }
        
        NSString *processedValue = [self.class formatString:value];
        BOOL isValid = [self.class validateString:processedValue];
        self.cardView.cardNumberLabel.textColor = [[UIColor lightGrayColor] colorWithAlphaComponent:isValid ? 1 : .5];
        self.cardView.cardNumberLabel.font = [UIFont creditCardFontOfSize:15];

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
                self.cardView.cardTypeImageView.image = [UIImage imageNamed:type];
                [UIView animateWithDuration:.5 animations:^{
                    self.cardView.cardTypeImageView.alpha = 1;
                }];
            } else if (self.cardView.cardTypeImageView.alpha) {
                [UIView animateWithDuration:.25 animations:^{
                    self.cardView.cardTypeImageView.alpha = 0;
                } completion:^(BOOL finished) {
                    self.cardView.cardTypeImageView.image = nil;
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
        self.cardNumberField.text = processedValue;
        return processedValue;
    }];
    [self.cardView.cardNumberLabel rac_liftSelector:@selector(setText:) withSignals:cardNumberFieldSignal, nil];
    
    RACSignal *nameFieldSignal = [self.nameField.rac_textSignal map:^id(id value) {
        if ([value isEqualToString:@""]) {
            return @"NAME ON CARD";
        }
        return [value uppercaseString];
    }];
    [self.cardView.nameLabel rac_liftSelector:@selector(setText:) withSignals:nameFieldSignal, nil];
    
    
    RACSignal *exprirationFieldSignal = [self.exprirationField.rac_textSignal map:^id(id value) {
        static NSString *slashString = @" / ";
        if ([value isEqualToString:@""]) {
            return @"●● / ●●";
        }
        
        if ([value length] == 2) {
            self.exprirationField.text = [value stringByReplacingCharactersInRange:NSMakeRange(2, 0) withString:slashString];
        } else if ([value length] == 5) {
            self.exprirationField.text = [value stringByReplacingOccurrencesOfString:slashString withString:@""];
        }
        return self.exprirationField.text;
    }];
    [self.cardView.exprirationLabel rac_liftSelector:@selector(setText:) withSignals:exprirationFieldSignal, nil];
    
    RACSignal *cvcFieldSignal = [self.cvcField.rac_textSignal map:^id(id value) {
        if ([value isEqualToString:@""]) {
            return @"●●●";
        }
        return [value uppercaseString];
    }];
    [self.cardView.cvcLabel rac_liftSelector:@selector(setText:) withSignals:cvcFieldSignal, nil];
}

#pragma mark - actions 
- (IBAction)didSwipeCard:(id)sender {
   UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:@"Submit Card" message:@"This will send me your credit information"];
    [alertView bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
    [alertView bk_addButtonWithTitle:@"Yes" handler:^{
        [self.cardFields enumerateObjectsUsingBlock:^(UITextField *textfield, NSUInteger idx, BOOL *stop) {
            textfield.text = @"";
            [textfield sendActionsForControlEvents:UIControlEventEditingChanged];
        }];
    }];
    [alertView show];
}

- (IBAction)didTapCardNumberLabel:(id)sender {
    [self.cardNumberField becomeFirstResponder];
}

- (IBAction)didTapNameLabel:(id)sender {
    [self.nameField becomeFirstResponder];
}

- (IBAction)didTapExpirationLabel:(id)sender {
    [self.exprirationField becomeFirstResponder];
}

@end
