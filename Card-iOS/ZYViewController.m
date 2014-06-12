//
//  ZYViewController.m
//  Card-iOS
//
//  Created by James Hildensperger on 6/11/14.
//  Copyright (c) 2014 Zymurgical. All rights reserved.
//

#import "ZYViewController.h"

@interface ZYViewController ()

@end

@implementation ZYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cardView.layer.cornerRadius = 9.0f;
    self.cardView.backgroundColor = [UIColor colorWithWhite:0.902 alpha:1.000];

    [UIView animateWithDuration:.25 delay:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.cardView.backgroundColor = [UIColor colorWithRed:0.101 green:0.456 blue:0.585 alpha:1.000];
        self.cardView.layer.shadowOpacity = .5;
        self.cardView.layer.shadowRadius = 5;
        self.cardView.layer.shadowOffset = CGSizeZero;
    } completion:nil];
    
    [self.cardFields enumerateObjectsUsingBlock:^(UITextField *textfield, NSUInteger idx, BOOL *stop) {
        textfield.layer.borderColor = [UIColor colorWithWhite:0.800 alpha:1.000].CGColor;
        textfield.layer.borderWidth = 1;
        
        UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [textfield setLeftViewMode:UITextFieldViewModeAlways];
        [textfield setLeftView:spacerView];
        [textfield setRightViewMode:UITextFieldViewModeAlways];
        [textfield setRightView:spacerView];
    }];
}

@end
