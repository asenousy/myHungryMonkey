//
//  HMGameSceneController.h
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 18/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import "HMGameScene.h"
#import <iAd/iAd.h>

@interface HMGameSceneController : UIViewController

//@property SKView *skView;

- (void)authenticateLocalPlayer;
- (void)pauseGame;

@end
