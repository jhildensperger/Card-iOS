//
//  ZYViewController.h
//  Card-iOS
//
//  Created by James Hildensperger on 6/11/14.
//  Copyright (c) 2014 Zymurgical. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CardView : UIView

@property (nonatomic, weak) IBOutlet UILabel *cardNumberLabel;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *exprirationLabel;
@property (nonatomic, weak) IBOutlet UILabel *cvcLabel;
@property (nonatomic, weak) IBOutlet UIImageView *cardTypeImageView;

@end

@interface ZYViewController : UIViewController

@property (nonatomic, weak) IBOutlet CardView *cardView;
@property (nonatomic, weak) IBOutlet UITextField *cardNumberField;
@property (nonatomic, weak) IBOutlet UITextField *nameField;
@property (nonatomic, weak) IBOutlet UITextField *exprirationField;
@property (nonatomic, weak) IBOutlet UITextField *cvcField;
@property (nonatomic) IBOutletCollection(UITextField) NSArray *cardFields;

@end
