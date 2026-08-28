//
//  LegacyViewController.m
//  Tipster
//
//  Created by Craig Hockenberry on 8/24/26.
//

#import "LegacyViewController.h"

// NOTE: This is needed to get the Objective-C methods in TipKitHelper.
#import "Tipster-Swift.h"

@interface LegacyViewController ()

@property (nonatomic, weak) IBOutlet UISwitch *toggleSwitch;

@property (nonatomic, strong) ToggleTipPresenter *toggleTipPresenter;

@end

@implementation LegacyViewController

- (void)dealloc
{
	NSLog(@"%s self = %@", __PRETTY_FUNCTION__, self);
	[self.toggleTipPresenter stop];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.toggleTipPresenter = [[ToggleTipPresenter alloc] initFrom:self sourceItem:self.toggleSwitch];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.toggleTipPresenter.isOn = self.toggleSwitch.isOn;
	[self.toggleTipPresenter start];
}

- (IBAction)dismiss:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleSwitchPressed:(id)sender {
	self.toggleTipPresenter.isOn = self.toggleSwitch.isOn;
	[NSTimer scheduledTimerWithTimeInterval:5.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
			[self.toggleSwitch setOn:NO animated:YES];
			self.toggleTipPresenter.isOn = NO;
			[timer invalidate];
	}];
}

@end
