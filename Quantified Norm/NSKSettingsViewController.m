//
//  NSKSettingsViewController.m
//  Quantified Norm
//
//  Created by Neil Kimmett on 10/10/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import "NSKSettingsViewController.h"

@interface NSKSettingsViewController () <UITextFieldDelegate>

@end

@implementation NSKSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Settings";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *urlLabel = [[UILabel alloc] init];
    urlLabel.text = @"URL to post to:";
    [self.view addSubview:urlLabel];

    UITextField *urlTextField = [[UITextField alloc] init];
    urlTextField.tag = 0;
    urlTextField.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    urlTextField.delegate = self;
    urlTextField.keyboardType = UIKeyboardTypeURL;
    urlTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:urlTextField];

    UILabel *authLabel = [[UILabel alloc] init];
    authLabel.text = @"Auth token:";
    [self.view addSubview:authLabel];

    UITextField *authTextField = [[UITextField alloc] init];
    authTextField.tag = 1;
    authTextField.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    authTextField.delegate = self;
    authTextField.keyboardType = UIKeyboardTypeURL;
    authTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [self.view addSubview:authTextField];
    
    CGRect frame = CGRectMake(10, 74, self.view.frame.size.width-20, 40);
    urlLabel.frame = frame;
    urlTextField.frame = CGRectOffset(frame, 0, 50);
    authLabel.frame = CGRectOffset(urlTextField.frame, 0, 50);
    authTextField.frame = CGRectOffset(authLabel.frame, 0, 50);
    
    urlTextField.text = [[NSUserDefaults standardUserDefaults] valueForKey:[self userDefaultsKeyForTag:0]];
    authTextField.text = [[NSUserDefaults standardUserDefaults] valueForKey:[self userDefaultsKeyForTag:1]];
}

- (NSString *)userDefaultsKeyForTag:(NSUInteger)tag
{
    switch (tag) {
        case 0:
            return @"QuantifiedNormURLToPOSTTo";
        case 1:
            return @"QuantifiedNormAuthToken";
    }
    return nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [[NSUserDefaults standardUserDefaults] setValue:textField.text forKey:[self userDefaultsKeyForTag:textField.tag]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [[NSUserDefaults standardUserDefaults] setValue:textField.text forKey:[self userDefaultsKeyForTag:textField.tag]];
    [[NSUserDefaults standardUserDefaults] synchronize];    
}

@end
