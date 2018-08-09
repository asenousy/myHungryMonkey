//
//  HMGameSceneController.m
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 18/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import <GameKit/GameKit.h>
#import "HMGameSceneController.h"
#import <StoreKit/StoreKit.h>
@import GoogleMobileAds;

@interface HMGameSceneController () <GKGameCenterControllerDelegate, MySceneDelegate, SKProductsRequestDelegate,SKPaymentTransactionObserver, GADBannerViewDelegate, GADInterstitialDelegate>
@property(nonatomic, strong) GADBannerView *bannerView;
@property(nonatomic, strong) GADInterstitial *interstitial;
@end

@implementation HMGameSceneController
{
    HMGameScene *_scene;
    BOOL _gameCenterEnabled;
    NSString *_leaderboardIdentifier;
    GKScore *_gkScore;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.view = [[SKView alloc] initWithFrame:self.view.frame];
        
        if (![self isNoAds]) {
            [self initGoogleAd];
            self.interstitial = [self createAndLoadInterstitial];
        }
    }
    return self;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.view.multipleTouchEnabled = YES;
    
    SKView * skView = (SKView *)self.view;
//    skView.ignoresSiblingOrder = YES;
    
    if (!skView.scene) {
//        skView.showsFPS = YES;
//        skView.showsNodeCount = YES;
//        skView.showsPhysics = YES;
//        skView.showsDrawCount = YES;
        
        // Create and configure the scene.
        _scene = [[HMGameScene alloc] initWithSize:skView.bounds.size delegate:self];
        
        [self showBanner];
        
        // Present the scene.
        [skView presentScene:_scene];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - GameCenter

- (void) authenticateLocalPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error){
        if (viewController != nil) {
            [_scene pauseGame];
            [self presentViewController:viewController animated:YES completion:nil];
        }
        else{
            if ([GKLocalPlayer localPlayer].authenticated) {
                _gameCenterEnabled = YES;

                [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:^(NSString *leaderboardIdentifier, NSError *error) {
                    
                    if (error != nil) {
                        NSLog(@"%@", [error localizedDescription]);
                    }
                    else{
                        _leaderboardIdentifier = leaderboardIdentifier;
                        [self updateLocalScore];
                    }
                }];
            }
            
            else{
                _gameCenterEnabled = NO;
            }
        }
    };

}

- (void)showGameCenterwithChallengesView:(BOOL)showChallengesView
{
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;
        gameCenterController.leaderboardIdentifier = _leaderboardIdentifier;
        gameCenterController.viewState = showChallengesView?GKGameCenterViewControllerStateChallenges:GKGameCenterViewControllerStateLeaderboards;
        [self presentViewController: gameCenterController animated: YES completion:nil];
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)reportGameCenterScore:(NSUInteger)currentScore
{
    if (_leaderboardIdentifier != NULL) {
        _gkScore = [[GKScore alloc] initWithLeaderboardIdentifier:_leaderboardIdentifier];
        _gkScore.value = currentScore;
        [GKScore reportScores:@[_gkScore] withCompletionHandler:^(NSError *error) {
            if (error != nil) {
                NSLog(@"%@", [error localizedDescription]);
            }
        }];
    }
}

- (void)challengeFriend
{
    GKLocalPlayer *lp = [GKLocalPlayer localPlayer];
    if (lp.isAuthenticated) {
        
        [lp loadFriendsWithCompletionHandler:^(NSArray *friendIDs, NSError *error)
         {
             if (friendIDs != nil)
             {
                 UIViewController *challengeController= [_gkScore challengeComposeControllerWithPlayers:friendIDs message:@"Beat my score" completionHandler:^(UIViewController *composeController, BOOL didIssueChallenge, NSArray *sentPlayerIDs) {
                     [composeController dismissViewControllerAnimated:YES completion:Nil];
                 }];
                 
                 [self presentViewController:challengeController animated:YES completion:Nil];
             }
         }];
    } else {
        
        [[[UIAlertView alloc] initWithTitle:@"Game Center Unavailable" message:@"Player is not signed in" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:Nil] show];
    }
}

#pragma mark - GoogleAd

- (void) initGoogleAd
{
    _bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerLandscape origin:CGPointMake(0, CGRectGetMaxY(self.view.frame)-CGSizeFromGADAdSize(kGADAdSizeSmartBannerLandscape).height)];
                                                                                                                                                                
    _bannerView.hidden = YES;
    _bannerView.adUnitID = @"";
    _bannerView.rootViewController = self;
    _bannerView.delegate = self;
    [self.view addSubview:_bannerView];
}

- (void)showBanner {
    GADRequest *request = [GADRequest request];
    [_bannerView loadRequest:request];
}

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView {
    bannerView.hidden = NO;
}

- (GADInterstitial *)createAndLoadInterstitial {
    GADInterstitial *interstitial =
    [[GADInterstitial alloc] initWithAdUnitID:@""];
    interstitial.delegate = self;
    GADRequest *request = [GADRequest request];
    [interstitial loadRequest:request];
    return interstitial;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    _interstitial = [self createAndLoadInterstitial];
}

- (void)presentInterstitialAd {
    if (![self isNoAds]) {
        if ([_interstitial isReady] && ![_interstitial hasBeenUsed]) {
            [_interstitial presentFromRootViewController:self];
        }
    }
}

#pragma mark - Other

- (void)pauseGame
{
    [_scene pauseGame];
}

- (void)updateLocalScore
{
    [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
        GKLeaderboard *leaderboard = leaderboards[0];
        [leaderboard loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
            
            NSUInteger onlineBestScore = (NSUInteger) leaderboard.localPlayerScore.value;
            NSUInteger localBestScore = [[NSUserDefaults standardUserDefaults] integerForKey:@"BestScore"];
            
            if (onlineBestScore > localBestScore) {
                [self setBestScore:onlineBestScore];
            }
        }];
    }];
}

- (void)setBestScore:(NSUInteger)bestScore {
    [[NSUserDefaults standardUserDefaults] setInteger:bestScore forKey:@"BestScore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (UIImage *)screenshot {
//    CGSize tempSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height- ([self isNoAds]?0:_adView.bounds.size.height));
    CGSize tempSize = CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height- ([self isNoAds]?0:_bannerView.bounds.size.height));
    UIGraphicsBeginImageContextWithOptions(tempSize, NO, 1.0);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)shareString:(NSString *)string url:(NSURL*)url image:(UIImage *)image {
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[string, url, image] applicationActivities:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (BOOL)isNoAds
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"NoAds"];
}

- (void)setNoAds
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NoAds"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [_bannerView removeFromSuperview];
    [_scene switchToMainMenu];
}

#pragma mark - StoreKit

-(void)NoAdsButton
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Remove Ads" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* actionPurchase = [UIAlertAction actionWithTitle:@"Remove Ads with In-App Purchase" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self purchase];
    }];
    [alert addAction:actionPurchase];
    
    UIAlertAction* actionRestore = [UIAlertAction actionWithTitle:@"Restore Previous Purchases" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"restore");
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }];
    [alert addAction:actionRestore];
    
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
    [alert addAction:actionCancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)purchase
{
    SKProductsRequest *request= [[SKProductsRequest alloc]
                                 initWithProductIdentifiers: [NSSet setWithObject: @"MyHungryMonkeyNoAds"]];
    request.delegate = self;
    [request start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    NSArray *myProduct = response.products;
    
    //Since only one product, we do not need to choose from the array. Proceed directly to payment.
    
    SKPayment *newPayment = [SKPayment paymentWithProduct:[myProduct objectAtIndex:0]];
    [[SKPaymentQueue defaultQueue] addPayment:newPayment];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
    [self setNoAds];
    // Finally, remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
    [self setNoAds];
    // Finally, remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
//    [activityIndicator stopAnimating];
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // Display an error here.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Purchase Unsuccessful"
                                                        message:@"Your purchase failed. Please try again."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    // Finally, remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    if (queue.transactions.count > 0) {
        [self setNoAds];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restore Unsuccessful"
                                                        message:@"Restoring Purchase failed. Please try again."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restore Unsuccessful"
                                                    message:@"Restoring Purchase failed. Please try again."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
