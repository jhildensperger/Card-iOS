//
//  ZYViewController.h
//  Card-iOS
//
//  Created by James Hildensperger on 6/11/14.
//  Copyright (c) 2014 Zymurgical. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZYInputLabel : UILabel

@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic) NSString *placeHolder;

@end

@interface CardView : UIView

@property (nonatomic, weak) IBOutlet UIView *inputFieldContainerView;
@property (nonatomic, weak) IBOutlet UITextField *inputField;
@property (nonatomic, weak) IBOutlet UIStepper *inputFieldStepper;

@property (nonatomic, weak) IBOutlet ZYInputLabel *cardNumberLabel;
@property (nonatomic, weak) IBOutlet ZYInputLabel *nameLabel;
@property (nonatomic, weak) IBOutlet ZYInputLabel *exprirationLabel;
@property (nonatomic, weak) IBOutlet ZYInputLabel *cvcLabel;
@property (nonatomic, weak) IBOutlet UIImageView *cardTypeImageView;

@end

@interface ZYViewController : UIViewController

@property (nonatomic, weak) IBOutlet CardView *cardView;

@end
