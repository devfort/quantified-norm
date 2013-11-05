//
//  NSKViewController.m
//  Quantified Norm
//
//  Created by Neil Kimmett on 09/10/2013.
//  Copyright (c) 2013 Neil Kimmett. All rights reserved.
//

#import "NSKViewController.h"
#import "UIView+AutoLayout.h"
#import "NSKDataManager.h"
#import "NSKSettingsViewController.h"

@interface NSKViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIStepper *stepper;
@property (nonatomic, strong) NSArray *data;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation NSKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"#norm";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UITextField *textField = [[UITextField alloc] init];
    textField.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    textField.delegate = self;
    [self.view addSubview:textField];
    self.textField = textField;
    
    UIStepper *stepper = [[UIStepper alloc] init];
    stepper.value = 1;
    [self.view addSubview:stepper];
    self.stepper = stepper;
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString stringWithFormat:@"%.0f", stepper.value];
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    self.label = label;

    CGRect frame = CGRectMake(10, 74, self.view.frame.size.width-20, 40);
    
    CGRect textFieldFrame, stepperFrame;
    CGRectDivide(frame, &textFieldFrame, &stepperFrame, 1./2. * frame.size.width, CGRectMinXEdge);
    stepperFrame.origin.x += 5;
    stepperFrame.origin.y += 5;
    
    CGRect labelFrame = CGRectMake(260, CGRectGetMinY(textFieldFrame), 55, 40);
    
    textField.frame = textFieldFrame;
    stepper.frame = stepperFrame;
    label.frame = labelFrame;
    
    [textField becomeFirstResponder];
    
    [stepper addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:nil];
    
    CGRect tableViewFrame = CGRectMake(0, CGRectGetMaxY(textFieldFrame), self.view.frame.size.width, self.view.frame.size.height - textFieldFrame.size.height);
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:tableViewFrame
                                                          style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    [self refreshData];
    
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(didTapSettingsButton:)];
    self.navigationItem.rightBarButtonItem = settingsButton;
}

- (void)refreshData
{
    self.data = [[NSKDataManager shared] loadDataFromFile];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    self.label.text = [NSString stringWithFormat:@"%d", [change[@"new"] intValue]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (![[NSKDataManager shared] url] && ![[NSKDataManager shared] authToken]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No url/auth token"
                                                        message:@"You might want to tap on that there 'Settings' button over there and put a URL and an auth token in"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    else {
        [textField resignFirstResponder];
        
        NSDictionary *params = @{textField.text: @(self.stepper.value)};
        
        [[NSKDataManager shared] sendDatum:params success:^{
            textField.text = @"";
            self.stepper.value = 1;
            [textField becomeFirstResponder];
            
            [self refreshData];
            [self.tableView reloadData];
        }];
        return YES;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:CellIdentifier];
    }
    NSDictionary *datum = self.data[indexPath.row];
    NSString *key = [datum[@"datum"] allKeys][0];
    cell.textLabel.text = key;
    cell.detailTextLabel.text = [datum[@"datum"][key] stringValue];
    
    BOOL sent = [datum[@"sent"] boolValue];
    cell.accessoryType = sent ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.textField resignFirstResponder];
}

#pragma mark - Buttons n shit
- (void)didTapSettingsButton:(UIBarButtonItem *)settingsButton
{
    NSKSettingsViewController *settingsViewController = [[NSKSettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

@end
