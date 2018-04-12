//
//  PDMultiLoginViewController.m
//  PopdeemSDK
//
//  Created by Niall Quinn on 10/01/2017.
//  Copyright © 2017 Popdeem. All rights reserved.
//

#import "PDMultiLoginViewController.h"
#import "PDSocialMediaManager.h"
#import "PDMultiLoginViewModel.h"
#import "PDTheme.h"
#import "PDConstants.h"
#import "PDUser.h"
#import "PDAbraClient.h"
#import "PDUser+Facebook.h"
#import "PDLogger.h"
#import "PDUtils.h"
#import "PDUserAPIService.h"
#import "PDAPIClient.h"
#import "PDUIInstagramLoginViewController.h"
#import "PDRewardAPIService.h"
#import "PDUIHomeViewController.h"
#import "PDUIRewardTableViewCell.h"
#import "PDUIDirectToSocialHomeHandler.h"

@interface PDMultiLoginViewController ()
@property (nonatomic, retain) PDMultiLoginViewModel* viewModel;
@property (nonatomic) BOOL facebookLoginOccurring;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *cancelButton;
@property (nonatomic, retain) PDUIRewardTableViewCell *rewardCell;
@property (nonatomic) BOOL twitterValid;
@end

@implementation PDMultiLoginViewController

- (instancetype) initFromNib {
  NSBundle *podBundle = [NSBundle bundleForClass:[PopdeemSDK class]];
  if (self = [self initWithNibName:@"PDMultiLoginViewController" bundle:podBundle]) {
    self.view.backgroundColor = [UIColor whiteColor];
    return self;
  }
  return nil;
}

- (void) setupSocialLoginReward:(PDReward*)reward {
  float width = self.view.frame.size.width;
  if (width > 400) {
    width = 375;
  }
  _rewardCell = [[PDUIRewardTableViewCell alloc] initWithFrame:CGRectMake(0, 0, width, 100) reward:reward];
  if (_rewardCell.logoImageView.image == nil) {
    NSURL *url = [NSURL URLWithString:reward.coverImageUrl];
    NSURLSessionTask *task2 = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
      if (data) {
        UIImage *image = [UIImage imageWithData:data];
        if (image) {
          dispatch_async(dispatch_get_main_queue(), ^{
            _rewardCell.logoImageView.image = image;
            reward.coverImage = image;
          });
        }
      }
    }];
    [task2 resume];
  }
  [_rewardView addSubview:_rewardCell];
  [_rewardView setHidden:NO];
  [_titleLabel setHidden:YES];
  [_bodyLabel setHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
  
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
	//View Setup
	_viewModel = [[PDMultiLoginViewModel alloc] initForViewController:self];
	[_viewModel setup];
	
	[_titleLabel setText:_viewModel.titleString];
	[_titleLabel setFont:_viewModel.titleFont];
	[_titleLabel setTextColor:_viewModel.titleColor];
  [_titleLabel sizeToFit];
	
	[_bodyLabel setText:_viewModel.bodyString];
	[_bodyLabel setTextColor:_viewModel.bodyColor];
	[_bodyLabel setFont:_viewModel.bodyFont];
	
	[_twitterLoginButton setBackgroundColor:_viewModel.twitterButtonColor];
	[_twitterLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  [_twitterLoginButton.titleLabel setFont:PopdeemFont(PDThemeFontPrimary, 15)];
  _twitterLoginButton.layer.cornerRadius = 5.0;
  _twitterLoginButton.clipsToBounds = YES;
	
	[_instagramLoginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  _instagramLoginButton.layer.cornerRadius = 5.0;
  _instagramLoginButton.clipsToBounds = YES;
  UIImage *image = [UIImage imageNamed:@"PDUI_IGBG"];
  if (image == nil) {
    NSBundle *podBundle = [NSBundle bundleForClass:[PopdeemSDK class]];
    NSString *imagePath = [podBundle pathForResource:@"PDUI_IGBG" ofType:@"png"];
    image = [UIImage imageWithContentsOfFile:imagePath];
  }
  [_instagramLoginButton.titleLabel setFont:PopdeemFont(PDThemeFontPrimary, 15)];
  [_instagramLoginButton setBackgroundImage:image forState:UIControlStateNormal];
	
	//Facebook setup
  _facebookLoginButton.layer.cornerRadius = 5.0;
  _facebookLoginButton.clipsToBounds = YES;
  [_facebookLoginButton setTitle:@"Log in with Facebook" forState:UIControlStateNormal];
  [self.facebookLoginButton.titleLabel setFont:PopdeemFont(PDThemeFontPrimary, 15)];
  
  if (_viewModel.image) {
    [self.imageView setImage:_viewModel.image];
  }
  [_imageView setContentMode:UIViewContentModeScaleAspectFill];
  _imageView.clipsToBounds = YES;
  
//  [self.facebookLoginButton.imageView setImage:nil];
  for (NSLayoutConstraint *l in self.facebookLoginButton.constraints) {
    if ( l.constant == 28 ){
      // Then disable it...
      l.active = false;
      break;
    }
  }
	
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelButtonPressed:) name:InstagramLoginuserDismissed object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
  NSArray *rewards = [PDRewardStore allRewards];
  if (rewards.count == 0) {
    PDRewardAPIService *service = [[PDRewardAPIService alloc] init];
    [service getAllRewardsWithCompletion:^(NSError *error) {
      for (PDReward* reward in [PDRewardStore allRewards]){
        if (reward.action == PDRewardActionSocialLogin) {
          [self setupSocialLoginReward:reward];
          break;
        }
      }
    }];
  } else {
    for (PDReward* reward in [PDRewardStore allRewards]){
      if (reward.action == PDRewardActionSocialLogin) {
        [self setupSocialLoginReward:reward];
        break;
      }
    }
  }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) appWillEnterForeground:(id)sender {
  [self performSelector:@selector(dismissIfWaiting) withObject:nil afterDelay:1.0];
}

- (void) dismissIfWaiting {
  if (!_twitterValid) {
    if (_loadingView) {
      [_loadingView hideAnimated:YES];
    }
  }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)twitterLoginButtonPressed:(id)sender {
  _loadingView = [[PDUIModalLoadingView alloc] initWithDefaultsForView:self.view];
  _loadingView.titleLabel.text = @"Logging in.";
  [_loadingView showAnimated:YES];
	PDSocialMediaManager *manager = [[PDSocialMediaManager alloc] initForViewController:self];
	[manager registerWithTwitter:^{
		//Continue to next stage of app, login has happened.
		[self proceedWithTwitterLoggedInUser];
    _twitterValid = YES;
	} failure:^(NSError *error) {
    _twitterValid = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
      [_loadingView hideAnimated:YES];
    });
		//Show some error, something went wrong
	}];
}

- (IBAction)instagramLoginButtonPressed:(id)sender {
  _loadingView = [[PDUIModalLoadingView alloc] initWithDefaultsForView:self.view];
  _loadingView.titleLabel.text = @"Logging in.";
  [_loadingView showAnimated:YES];
	PDUIInstagramLoginViewController *instaVC = [[PDUIInstagramLoginViewController alloc] initForParent:self delegate:self connectMode:NO directConnect:YES];
	instaVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
	instaVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[self presentViewController:instaVC animated:YES completion:^(void){}];
}

- (void) proceedWithTwitterLoggedInUser {
  dispatch_async(dispatch_get_main_queue(), ^{
    [_loadingView hideAnimated:YES];
  });
	[self addUserToUserDefaults:[PDUser sharedInstance]];
	AbraLogEvent(ABRA_EVENT_LOGIN, @{@"Source" : @"Login Takeover"});
  [[NSNotificationCenter defaultCenter] postNotificationName:PDUserDidLogin
                                                      object:nil];
	[self dismissViewControllerAnimated:YES completion:^{
    [[NSNotificationCenter defaultCenter] postNotificationName:DirectToSocialHome object:nil];
  }];
}

- (void) addUserToUserDefaults:(PDUser*)user {
	[[NSUserDefaults standardUserDefaults] setObject:[user dictionaryRepresentation] forKey:@"popdeemUser"];
}

#pragma mark - Instagram Login Delegate Methods

- (void) connectInstagramAccount:(NSString*)identifier accessToken:(NSString*)accessToken userName:(NSString*)userName {
	PDUserAPIService *service = [[PDUserAPIService alloc] init];
	
	[service registerUserWithInstagramId:identifier accessToken:accessToken fullName:@"" userName:userName profilePicture:@"" success:^(PDUser *user){
		[self addUserToUserDefaults:user];
		AbraLogEvent(ABRA_EVENT_LOGIN, @{@"Source" : @"Login Takeover"});
    dispatch_async(dispatch_get_main_queue(), ^{
      [_loadingView hideAnimated:YES];
      [[NSNotificationCenter defaultCenter] postNotificationName:PDUserDidLogin
                                                          object:nil];
      [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:DirectToSocialHome object:nil];
      }];
    });
	} failure:^(NSError* error){
    dispatch_async(dispatch_get_main_queue(), ^{
      [_loadingView hideAnimated:YES];
    });
	}];

}
- (IBAction)cancelButtonPressed:(id)sender {
  dispatch_async(dispatch_get_main_queue(), ^{
    [_loadingView hideAnimated:YES];
		});
	[self dismissAction:sender];
}

- (IBAction) dismissAction:(id)sender {
  dispatch_async(dispatch_get_main_queue(), ^{
    [_loadingView hideAnimated:YES];
  });
	[self dismissViewControllerAnimated:YES completion:^{
		//Any cleanup to do?
	}];
	AbraLogEvent(ABRA_EVENT_CLICKED_CLOSE_LOGIN_TAKEOVER, @{@"Source" : @"Dismiss Button"});
}

#pragma mark - Facebook Login -
- (IBAction) connectFacebook:(id)sender {
  self.facebookLoginOccurring = YES;
  _loadingView = [[PDUIModalLoadingView alloc] initWithDefaultsForView:self.view];
  _loadingView.titleLabel.text = @"Logging in.";
  [_loadingView showAnimated:YES];
  [[PDSocialMediaManager manager] loginWithFacebookReadPermissions:@[
                                                                     @"public_profile",
                                                                     @"email",
                                                                     @"user_birthday",
                                                                     @"user_posts",
                                                                     @"user_friends",
                                                                     @"user_education_history"]
                                               registerWithPopdeem:YES
                                                           success:^(void) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                               [self facebookLoginSuccess];
                                                             });
                                                           } failure:^(NSError *error) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                               [self facebookLoginFailure];
                                                             });
                                                           }];
}

- (void) facebookLoginSuccess {
  dispatch_async(dispatch_get_main_queue(), ^{
    [_loadingView hideAnimated:YES];
  });
  [[NSNotificationCenter defaultCenter] postNotificationName:PDUserDidLogin
                                                      object:nil];
  AbraLogEvent(ABRA_EVENT_LOGIN, @{@"Source" : @"Login Takeover"});
  [self dismissViewControllerAnimated:YES completion:^{
    [[NSNotificationCenter defaultCenter] postNotificationName:DirectToSocialHome object:nil];
  }];
}

- (void) facebookLoginFailure {
  dispatch_async(dispatch_get_main_queue(), ^{
    [_loadingView hideAnimated:YES];
  });
}

@end
