//
//  HMGameScene.h
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 18/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <GameKit/GameKit.h>
#import "HMMonkey.h"
#import "HMJoystick.h"
#import "HMFly.h"

@protocol MySceneDelegate <NSObject>

- (void)showGameCenterwithChallengesView:(BOOL)showChallengesView;
- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController*)gameCenterViewController;

- (void)reportGameCenterScore:(NSUInteger)currentScore;
- (void)challengeFriend;

- (UIImage *)screenshot;
- (void)shareString:(NSString *)string url:(NSURL*)url image:(UIImage *)screenshot;

- (BOOL)isNoAds;
-(void)NoAdsButton;

- (void)presentInterstitialAd;

@end

@interface HMGameScene : SKScene

- (id)initWithSize:(CGSize)size delegate:(id<MySceneDelegate>)delegate;
- (void)pauseGame;
- (void)switchToMainMenu;

@end
