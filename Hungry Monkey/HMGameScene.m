//
//  HMGameScene.m
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 18/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

@import CoreMotion;
@import AVFoundation;
#import "HMGameScene.h"
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(int, HMGameState)
{
    HMStateMainMenu,
    HMStateSettings,
    HMStatePause,
    HMStateGamePlay,
    HMStateGameOver,
    HMStateHowToPlay
};

typedef NS_ENUM(int, HMLayer)
{
    HMLayerGameSceneLayer,
    HMLayerHUD,
    HMLayerTouch,
    HMLayerControls,
    HMLayerMenu,
    HMLayerFlash
};

static const int kNumLives = 3;
static float kGroundLevel;
static const int kNumFlies = 1;
static const int kMegaStrengh = 26;
static const int kHeartAppearance = 20;

static NSString *const kFont = @"ChalkboardSE-Light";

static int kButtonFontSize;
static int kHUDFontSize;
static int kTitleFontSize;

static const float kMenuDarkScreenAlpha = 0.4;
static float kStrengthBarThreshold;

static const int APP_STORE_ID = 885807940;

@interface HMGameScene() <SKPhysicsContactDelegate>
@end

@implementation HMGameScene
{
    CMMotionManager *_motionManager;
    SKTextureAtlas *_textureAtlas;
    HMGameState _gameState;
    BOOL _monkeyHit;
    SKSpriteNode *_background;
    HMMonkey *_monkey;
    HMJoystick *_joystick;
    BOOL _accelerometerOn, _vibrationOn, _soundOn, _musicOn;
    NSUInteger _score, _lives;
    SKAction *_click, *_killFly, *_gotBanana, *_monkeyScream, *_monkeyStrong, *_heartBeat;
    id<MySceneDelegate> _delegate;
    BOOL _flipAccelerometer;
    AVAudioPlayer *_backgroundMusicPlayer;
    int _strength;
    BOOL _AdFlag;
}

- (id)initWithSize:(CGSize)size delegate:(id<MySceneDelegate>)delegate
{
    if (self = [super initWithSize:size]) {
        
        self.scaleMode = SKSceneScaleModeAspectFill;
        _textureAtlas = [HMTextureAtlas sharedInstance];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Accelerometer"]&&[[NSUserDefaults standardUserDefaults] objectForKey:@"Vibration"]&&[[NSUserDefaults standardUserDefaults] objectForKey:@"Sound"]&&[[NSUserDefaults standardUserDefaults] objectForKey:@"Music"]) {
            
            _accelerometerOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"Accelerometer"];
            _vibrationOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"Vibration"];
            _soundOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"Sound"];
            _musicOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"Music"];
            
            
        } else {
            _accelerometerOn = YES;
            _vibrationOn = YES;
            _soundOn = YES;
            _musicOn = YES;
        }
        
        _delegate = delegate;
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            kGroundLevel = 51.0;
            kButtonFontSize = 32;
            kHUDFontSize = 16;
            kTitleFontSize = 53;
            kStrengthBarThreshold = 20.0;
            
        } else {
            
            kGroundLevel = 175.0;
            kButtonFontSize = 64;
            kHUDFontSize = 32;
            kTitleFontSize = 106;
            kStrengthBarThreshold = 40.0;
        }
    }
    
    [self setupSound];
    [self setupBackgroundMusic];
    [self switchToMainMenu];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    return self;
}

#pragma mark - Setups

- (void)setupSound
{
    _click = [SKAction playSoundFileNamed:@"click.mp3" waitForCompletion:NO];
    _killFly = [SKAction playSoundFileNamed:@"killFly.mp3" waitForCompletion:NO];
    _gotBanana = [SKAction playSoundFileNamed:@"gotBanana.mp3" waitForCompletion:NO];
    _monkeyScream = [SKAction playSoundFileNamed:@"monkeyMad1.mp3" waitForCompletion:NO];
    _monkeyStrong = [SKAction playSoundFileNamed:@"monkeyStrong1.mp3" waitForCompletion:NO];
    _heartBeat = [SKAction playSoundFileNamed:@"heartBeat2.mp3" waitForCompletion:NO];
}

- (void)setupBackgroundMusic
{
    NSError *error;
    NSURL * backgroundMusicURL = [[NSBundle mainBundle] URLForResource:@"Dubakupado" withExtension:@"mp3"];
    _backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
    _backgroundMusicPlayer.numberOfLoops = -1;
    _backgroundMusicPlayer.volume = 0.1;
    [_backgroundMusicPlayer prepareToPlay];
}

- (void)setupAccelerometer
{
    _motionManager = [[CMMotionManager alloc] init];
    if (_motionManager.accelerometerAvailable) {
        [_motionManager startAccelerometerUpdates];
    }
}

- (void)setupPhysicsWorld
{
    self.physicsWorld.gravity = CGVectorMake(0, (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?-4:-9);
    self.physicsBody.friction = 0;
    self.physicsWorld.contactDelegate = self;
}

- (void)setupBackground
{
    _background = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"bg_repeatable"]];
    _background.name = @"Background";
    _background.zPosition = HMLayerGameSceneLayer;
    [_background setAnchorPoint:CGPointZero];
    _background.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, kGroundLevel, _background.frame.size.width, _background.frame.size.height-kGroundLevel)];
    _background.physicsBody.categoryBitMask = HMColliderTypeBackground;
    _background.physicsBody.restitution = 0;
    [self addChild:_background];
    
    _background.physicsBody.contactTestBitMask = HMColliderTypeMonkey;
}

- (void)setupBanana
{
    SKSpriteNode *banana = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"banana"]];
    banana.name = @"Banana";
    banana.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:banana.frame.size.width/3];
    banana.physicsBody.dynamic = NO;
    banana.zPosition = HMLayerGameSceneLayer;
    CGFloat locX = RandomFloatRange(banana.size.width, _background.size.width-banana.size.width);
    CGFloat locY = RandomFloatRange(kGroundLevel+banana.size.height, _background.size.height-banana.size.height);
    banana.position = CGPointMake(locX, locY);
    banana.physicsBody.categoryBitMask = HMColliderTypeBanana;
    banana.physicsBody.contactTestBitMask = HMColliderTypeMonkey;
    [_background addChild:banana];
    
    [banana setScale:0];
    [banana runAction:[SKAction scaleTo:1 duration:0.5]];
}

- (void)setupBanana:(CGPoint)position
{
    SKSpriteNode *banana = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"banana"]];
    banana.name = @"Banana";
    banana.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:banana.frame.size.width/3];
    banana.physicsBody.dynamic = NO;
    banana.zPosition = HMLayerGameSceneLayer;
    
    if (position.x < banana.size.width/2) {
        position.x = banana.size.width/2;
    }
    if (position.x > _background.size.width-banana.size.width/2) {
        position.x = _background.size.width-banana.size.width/2;
    }
    if (position.y > _background.size.height-banana.size.height/2) {
        position.y = _background.size.height-banana.size.height/2;
    }
    if (position.y < kGroundLevel+banana.size.height/2) {
        position.y = kGroundLevel+banana.size.height/2;
    }
    
    banana.position = position;
    banana.physicsBody.categoryBitMask = HMColliderTypeBanana;
    banana.physicsBody.contactTestBitMask = HMColliderTypeMonkey;
    [_background addChild:banana];
    
    [banana setScale:0];
    [banana runAction:[SKAction scaleTo:1 duration:0.5]];
}

- (void)setupMonkey
{
    _monkey = [[HMMonkey alloc] initWithPosition:CGPointMake(self.size.width/2, self.size.height/2)];
    _monkey.zPosition = HMLayerGameSceneLayer;
    [_background addChild:_monkey];
}

- (void)setupFlies
{
    for (int i=0; i<kNumFlies; i++) {
        [self addFly];
    }
    
    [_background runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction waitForDuration:6], [SKAction performSelector:@selector(addFly) onTarget:self]]]] withKey:@"FlySpawning"];
}

- (void)setupJoystick
{
    _joystick = [HMJoystick node];
    _joystick.zPosition = HMLayerControls;
    _joystick.position = CGPointMake(_joystick.controlRadius+_joystick.joystickRadius,(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?kGroundLevel+_joystick.joystickRadius:kGroundLevel);
    [self addChild:_joystick];
}

- (void)setupPause
{
    SKSpriteNode *pauseButton = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(80, 45)];
    pauseButton.name = @"Pause";
    pauseButton.zPosition = HMLayerControls;
    pauseButton.position = CGPointMake(self.size.width/2-pauseButton.size.width, self.size.height-pauseButton.size.height/2);
    [self addChild:pauseButton];
    SKSpriteNode *pause = [SKSpriteNode spriteNodeWithImageNamed:@"pause"];
    pause.name = @"Pause";
    pause.position = CGPointMake(0,pauseButton.size.height/2-pause.size.height/2);
    [pauseButton addChild:pause];
}

- (void)setupHUD
{
    SKNode *HUD = [SKNode node];
    HUD.name = @"HUD";
    HUD.zPosition = HMLayerHUD;
    [self addChild:HUD];
    
    SKSpriteNode *scoreImage = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"scorebanana"]];
    scoreImage.position = CGPointMake(-scoreImage.size.width/2, 0.0);
    
    SKLabelNode* scoreLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    scoreLabel.name = @"score";
    scoreLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    scoreLabel.fontSize = kHUDFontSize;
    scoreLabel.text = [NSString stringWithFormat:@"x %lu", (unsigned long)_score];
    scoreLabel.position = CGPointMake(scoreLabel.frame.size.width/1.5, scoreImage.position.y);
    
    SKSpriteNode *scoreNode = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(scoreImage.size.width+scoreLabel.frame.size.width, scoreImage.size.height) ];
    scoreNode.name = @"scoreHud";
    scoreNode.position = CGPointMake(scoreNode.size.width/2,self.size.height-scoreNode.size.height/2);
    [scoreNode addChild:scoreLabel];
    [scoreNode addChild:scoreImage];
    [HUD addChild:scoreNode];

    
    SKSpriteNode *life = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"heart"]];
    life.xScale = 0.60;
    life.yScale = 0.60;
    life.position = CGPointMake(-life.size.width/2, 0.0-life.size.height/10);
    
    SKLabelNode* healthLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    healthLabel.name = @"lives";
    healthLabel.fontSize = kHUDFontSize;
    healthLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    healthLabel.text = [NSString stringWithFormat:@"x %lu", (unsigned long)_lives];
    healthLabel.position = CGPointMake(healthLabel.frame.size.width/1.5, life.position.y);
    
    SKSpriteNode *healthNode = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(life.size.width+healthLabel.frame.size.width, life.size.height) ];
    healthNode.name = @"livesHud";
    healthNode.position = CGPointMake(self.size.width-healthNode.size.width/1.4, self.size.height-healthNode.size.height/2);
    [healthNode addChild:healthLabel];
    [healthNode addChild:life];
    [HUD addChild:healthNode];
}

- (void)setupTouchLayer
{
    SKSpriteNode *touchLayer = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:CGSizeMake(self.size.width, self.size.height)];
    touchLayer.anchorPoint = CGPointZero;

    touchLayer.position = CGPointMake(_accelerometerOn?0:self.size.width/4, 0);
    
    touchLayer.name = @"TouchLayer";
    touchLayer.zPosition = HMLayerTouch;
    [self addChild:touchLayer];
}

-(void)setupHeart
{
    SKSpriteNode *heart = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"heart"]];
    
    BOOL direction = RandomSign()>0?YES:NO;
    
    heart.position = CGPointMake(direction?-heart.size.width/2:_background.size.width+heart.size.width/2, kGroundLevel+self.size.height/2);
    heart.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:heart.size.width/3];
    heart.physicsBody.dynamic = NO;
    heart.physicsBody.categoryBitMask = HMColliderTypeLifeGinger;
    heart.physicsBody.contactTestBitMask = HMColliderTypeMonkey;
    [_background addChild:heart];
    
    SKAction *fly = [SKAction sequence:@[[SKAction moveToX:direction?_background.size.width+heart.size.width/2:-heart.size.width/2 duration:10],[SKAction runBlock:^{[heart removeFromParent];}]]];
    
    SKAction *zigzag = [SKAction repeatActionForever:[SKAction sequence:@[[SKAction moveBy:CGVectorMake(0, self.size.height/4) duration:0.5], [SKAction moveBy:CGVectorMake(0, -self.size.height/4) duration:0.5]]]];
    
    SKAction *scaling;
    
    if (_soundOn) {
        scaling = [SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleTo:1.2 duration:0.4],[SKAction scaleTo:0.8 duration:0.4],_heartBeat]]];
    } else {
        scaling = [SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleTo:1.2 duration:0.4],[SKAction scaleTo:0.8 duration:0.4]]]];
    }
    
    [heart runAction:[SKAction group:@[fly,zigzag,scaling]]];
}

#pragma mark - Menus

- (void)setupGameOverMenu
{
    [[self childNodeWithName:@"Pause"] removeFromParent];
    
    SKNode *gameOverScreen = [SKNode node];
    gameOverScreen.name = @"GameOver";
    gameOverScreen.zPosition = HMLayerMenu;
    [self addChild:gameOverScreen];
    
    SKSpriteNode *darkScreen = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:self.size];
    darkScreen.anchorPoint = CGPointZero;
    darkScreen.alpha = kMenuDarkScreenAlpha;
    [gameOverScreen addChild:darkScreen];
    
    SKLabelNode *gameOverLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    gameOverLabel.text = @"GAME OVER";
    gameOverLabel.fontSize = kTitleFontSize;
    gameOverLabel.position = CGPointMake(self.size.width/2, self.size.height/1.2);
    [gameOverScreen addChild:gameOverLabel];
    
    SKLabelNode *highestScoreLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    highestScoreLabel.text = @"Best Score";
    highestScoreLabel.fontSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?26:52;
    highestScoreLabel.position = CGPointMake(gameOverLabel.position.x+gameOverLabel.frame.size.width/4, gameOverLabel.position.y-gameOverLabel.frame.size.height-15);
    [gameOverScreen addChild:highestScoreLabel];
    SKLabelNode *highestScore = [SKLabelNode labelNodeWithFontNamed:kFont];
    highestScore.text = [NSString stringWithFormat:@"%lu",(unsigned long)[self bestScore]];
    highestScore.fontSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?38:76;
    highestScore.position = CGPointMake(highestScoreLabel.position.x, highestScoreLabel.position.y-highestScoreLabel.frame.size.height-20);
    [gameOverScreen addChild:highestScore];
    
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    scoreLabel.text = @"Score";
    scoreLabel.fontSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?26:52;
    scoreLabel.position = CGPointMake(gameOverLabel.position.x-gameOverLabel.frame.size.width/4, gameOverLabel.position.y-gameOverLabel.frame.size.height-15);
    [gameOverScreen addChild:scoreLabel];
    SKLabelNode *score = [SKLabelNode labelNodeWithFontNamed:kFont];
    score.text = [NSString stringWithFormat:@"%lu",(unsigned long)_score];
    score.fontSize = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?38:76;
    score.position = CGPointMake(scoreLabel.position.x, scoreLabel.position.y-scoreLabel.frame.size.height-20);
    [gameOverScreen addChild:score];
    
    SKSpriteNode *againButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    againButton.position = CGPointMake(gameOverLabel.position.x, score.position.y-score.frame.size.height-20);
    againButton.name = @"PlayAgainButton";
    [gameOverScreen addChild:againButton];
    SKLabelNode *againButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    againButtonLabel.name = @"PlayAgainButton";
    againButtonLabel.text = @"Play Again";
    againButtonLabel.fontSize = kButtonFontSize;
    againButtonLabel.fontColor = [SKColor yellowColor];
    againButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [againButton addChild:againButtonLabel];
    
    SKSpriteNode *mainMenuButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    mainMenuButton.position = CGPointMake(againButton.position.x, againButton.position.y-againButton.frame.size.height-10);
    mainMenuButton.name = @"MainMenuButton";
    [gameOverScreen addChild:mainMenuButton];
    SKLabelNode *mainMenuButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    mainMenuButtonLabel.name = @"MainMenuButton";
    mainMenuButtonLabel.text = @"Main Menu";
    mainMenuButtonLabel.fontSize = kButtonFontSize;
    mainMenuButtonLabel.fontColor = [SKColor yellowColor];
    mainMenuButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [mainMenuButton addChild:mainMenuButtonLabel];
    
    SKSpriteNode *rateButton = [SKSpriteNode spriteNodeWithImageNamed:@"halfbutton"];
    rateButton.position = CGPointMake((againButton.position.x-againButton.size.width/2)/2, mainMenuButton.position.y);
    rateButton.name = @"RateButton";
    [gameOverScreen addChild:rateButton];
    SKLabelNode *rateLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    rateLabel.name = @"RateButton";
    rateLabel.text = @"Rate";
    rateLabel.fontColor = [SKColor yellowColor];
    rateLabel.fontSize = kButtonFontSize;
    rateLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [rateButton addChild:rateLabel];
    
    SKSpriteNode *shareButton = [SKSpriteNode spriteNodeWithImageNamed:@"halfbutton"];
    shareButton.xScale = 1.2;
    shareButton.position = CGPointMake((againButton.position.x-againButton.size.width/2)/2, againButton.position.y);
    shareButton.name = @"ShareButton";
    [gameOverScreen addChild:shareButton];
    SKLabelNode *shareLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    shareLabel.xScale = 1/1.2;
    shareLabel.name = @"ShareButton";
    shareLabel.text = @"Share";
    shareLabel.fontColor = [SKColor yellowColor];
    shareLabel.fontSize = kButtonFontSize;
    shareLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [shareButton addChild:shareLabel];
    
    SKSpriteNode *gameCenter = [SKSpriteNode spriteNodeWithImageNamed:@"StatsButton"];
    gameCenter.position = CGPointMake(shareButton.position.x, shareButton.position.y+gameCenter.size.height);
    gameCenter.name = @"GameCenter";
    [gameOverScreen addChild:gameCenter];
    
    SKSpriteNode *challengeButton = [SKSpriteNode spriteNodeWithImageNamed:@"doublebutton"];
    challengeButton.position = CGPointMake((mainMenuButton.position.x+mainMenuButton.size.width/2+self.size.width)/2, (againButton.position.y+mainMenuButton.position.y)/2);
    challengeButton.name = @"ChallengeButton";
    [gameOverScreen addChild:challengeButton];
    SKLabelNode *challengeButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    challengeButtonLabel.name = @"ChallengeButton";
    challengeButtonLabel.text = @"Challenge";
    challengeButtonLabel.fontSize = kButtonFontSize;
    challengeButtonLabel.fontColor = [SKColor yellowColor];
    challengeButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeBottom;
    [challengeButton addChild:challengeButtonLabel];
    SKLabelNode *challengeButtonLabel1 = [SKLabelNode labelNodeWithFontNamed:kFont];
    challengeButtonLabel1.name = @"ChallengeButton";
    challengeButtonLabel1.text = @"Friends";
    challengeButtonLabel1.fontSize = kButtonFontSize;
    challengeButtonLabel1.fontColor = [SKColor yellowColor];
    challengeButtonLabel1.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
    [challengeButton addChild:challengeButtonLabel1];
}

- (void)setupMainMenu
{
    SKNode *mainMenu = [SKNode node];
    mainMenu.name = @"MainMenu";
    mainMenu.zPosition = HMLayerMenu;
    [self addChild:mainMenu];
    
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"bg_repeatable"]];
    [background setAnchorPoint:CGPointZero];
    [mainMenu addChild:background];
    
    SKSpriteNode *darkScreen = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:self.size];
    darkScreen.anchorPoint = CGPointZero;
    darkScreen.alpha = kMenuDarkScreenAlpha;
    [mainMenu addChild:darkScreen];
    
    SKLabelNode *hungryMonkeyLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    hungryMonkeyLabel.text = @"My Hungry Monkey";
    hungryMonkeyLabel.fontSize = kTitleFontSize;
    hungryMonkeyLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    hungryMonkeyLabel.position = CGPointMake(self.size.width/2, self.size.height/1.3);
    [mainMenu addChild:hungryMonkeyLabel];
    
    SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    playButton.position = CGPointMake(hungryMonkeyLabel.position.x, hungryMonkeyLabel.position.y-hungryMonkeyLabel.frame.size.height-30);
    playButton.name = @"PlayButton";
    [mainMenu addChild:playButton];
    SKLabelNode *playButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    playButtonLabel.name = @"PlayButton";
    playButtonLabel.text = @"Play";
    playButtonLabel.fontSize = kButtonFontSize;
    playButtonLabel.fontColor = [SKColor yellowColor];
    playButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [playButton addChild:playButtonLabel];
    
    SKSpriteNode *settingsButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    settingsButton.position= CGPointMake(hungryMonkeyLabel.position.x, playButton.position.y-playButton.frame.size.height-10);
    settingsButton.name = @"SettingsButton";
    [mainMenu addChild:settingsButton];
    SKLabelNode *settingsButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    settingsButtonLabel.name = @"SettingsButton";
    settingsButtonLabel.text = @"Settings";
    settingsButtonLabel.fontSize = kButtonFontSize;
    settingsButtonLabel.fontColor = [SKColor yellowColor];
    settingsButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [settingsButton addChild:settingsButtonLabel];
    
    SKSpriteNode *gameCenter = [SKSpriteNode spriteNodeWithImageNamed:@"StatsButton"];
    gameCenter.position = CGPointMake((settingsButton.position.x+settingsButton.size.width/2+self.size.width)/2,settingsButton.position.y);
    gameCenter.name = @"GameCenter";
    [mainMenu addChild:gameCenter];
    
    SKSpriteNode *challengeButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    challengeButton.position = CGPointMake(hungryMonkeyLabel.position.x,settingsButton.position.y-settingsButton.frame.size.height-10);
    challengeButton.name = @"ChallengeButton";
    [mainMenu addChild:challengeButton];
    SKLabelNode *challengeButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    challengeButtonLabel.name = @"ChallengeButton";
    challengeButtonLabel.text = @"Challenges";
    challengeButtonLabel.fontSize = kButtonFontSize;
    challengeButtonLabel.fontColor = [SKColor yellowColor];
    challengeButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [challengeButton addChild:challengeButtonLabel];
    
    SKSpriteNode *rateButton = [SKSpriteNode spriteNodeWithImageNamed:@"halfbutton"];
    rateButton.position = CGPointMake((settingsButton.position.x-settingsButton.size.width/2)/2, [_delegate isNoAds] ? settingsButton.position.y : challengeButton.position.y);
    rateButton.name = @"RateButton";
    [mainMenu addChild:rateButton];
    SKLabelNode *rateLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    rateLabel.name = @"RateButton";
    rateLabel.text = @"Rate";
    rateLabel.fontColor = [SKColor yellowColor];
    rateLabel.fontSize = kButtonFontSize;
    rateLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [rateButton addChild:rateLabel];
    
    if (![_delegate isNoAds]) {
        
        SKSpriteNode *noAds = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"noAds"]];
        noAds.position = CGPointMake((challengeButton.position.x-challengeButton.size.width/2)/2,playButton.position.y);
        noAds.name = @"noAds";
        [mainMenu addChild:noAds];
    }
}

- (void)setupSettingsMenu:(HMGameState)currentGameState
{
    SKNode *settingsMenu = [SKNode node];
    settingsMenu.name = @"SettingsMenu";
    settingsMenu.zPosition = HMLayerMenu;
    [self addChild:settingsMenu];
    
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"bg_repeatable"]];
    [background setAnchorPoint:CGPointZero];
    [settingsMenu addChild:background];
    
    SKSpriteNode *darkScreen = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:self.size];
    darkScreen.anchorPoint = CGPointZero;
    darkScreen.alpha = kMenuDarkScreenAlpha;
    [settingsMenu addChild:darkScreen];
    
    SKLabelNode *settingsLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    settingsLabel.text = @"Settings";
    settingsLabel.fontSize = kTitleFontSize;
    settingsLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    settingsLabel.position = CGPointMake(self.size.width/2, self.size.height/1.2);
    [settingsMenu addChild:settingsLabel];
    
    SKLabelNode *accelerometerLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    accelerometerLabel.text = @"Accelerometer";
    accelerometerLabel.fontSize = kButtonFontSize;
    accelerometerLabel.fontColor = [SKColor yellowColor];
    accelerometerLabel.position = CGPointMake(settingsLabel.position.x-accelerometerLabel.frame.size.width/2, settingsLabel.position.y-settingsLabel.frame.size.height-30);
    [settingsMenu addChild:accelerometerLabel];
    SKLabelNode *accelerometerBool = [SKLabelNode labelNodeWithFontNamed:kFont];
    accelerometerBool.text = _accelerometerOn ? @"ON" : @"OFF";
    accelerometerBool.fontSize = kButtonFontSize;
    accelerometerBool.fontColor = [SKColor yellowColor];
    accelerometerBool.position = CGPointMake(accelerometerLabel.position.x+accelerometerLabel.frame.size.width, accelerometerLabel.position.y);
    accelerometerBool.name = @"AccelerometerBool";
    [settingsMenu addChild:accelerometerBool];
    
    SKLabelNode *vibrationLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    vibrationLabel.text = @"Vibration";
    vibrationLabel.fontSize = kButtonFontSize;
    vibrationLabel.fontColor = [SKColor yellowColor];
    vibrationLabel.position = CGPointMake(accelerometerLabel.position.x, accelerometerLabel.position.y-accelerometerLabel.frame.size.height);
    [settingsMenu addChild:vibrationLabel];
    SKLabelNode *vibrationBool = [SKLabelNode labelNodeWithFontNamed:kFont];
    vibrationBool.text = _vibrationOn ? @"ON" : @"OFF";
    vibrationBool.fontSize =kButtonFontSize;
    vibrationBool.fontColor = [SKColor yellowColor];
    vibrationBool.position = CGPointMake(accelerometerBool.position.x, vibrationLabel.position.y);
    vibrationBool.name = @"VibrationBool";
    [settingsMenu addChild:vibrationBool];
    
    SKLabelNode *soundLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    soundLabel.text = @"Sound";
    soundLabel.fontSize = kButtonFontSize;
    soundLabel.fontColor = [SKColor yellowColor];
    soundLabel.position = CGPointMake(accelerometerLabel.position.x, vibrationLabel.position.y-vibrationLabel.frame.size.height);
    [settingsMenu addChild:soundLabel];
    SKLabelNode *soundBool = [SKLabelNode labelNodeWithFontNamed:kFont];
    soundBool.text = _soundOn ? @"ON" : @"OFF";
    soundBool.fontSize = kButtonFontSize;
    soundBool.fontColor = [SKColor yellowColor];
    soundBool.position = CGPointMake(vibrationBool.position.x, soundLabel.position.y);
    soundBool.name = @"SoundBool";
    [settingsMenu addChild:soundBool];
    
    SKLabelNode *musicLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    musicLabel.text = @"Music";
    musicLabel.fontSize = kButtonFontSize;
    musicLabel.fontColor = [SKColor yellowColor];
    musicLabel.position = CGPointMake(accelerometerLabel.position.x, soundLabel.position.y-soundLabel.frame.size.height);
    [settingsMenu addChild:musicLabel];
    SKLabelNode *musicBool = [SKLabelNode labelNodeWithFontNamed:kFont];
    musicBool.text = _musicOn ? @"ON" : @"OFF";
    musicBool.fontSize = kButtonFontSize;
    musicBool.fontColor = [SKColor yellowColor];
    musicBool.position = CGPointMake(soundBool.position.x, musicLabel.position.y);
    musicBool.name = @"MusicBool";
    [settingsMenu addChild:musicBool];
    
    SKSpriteNode *backButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    backButton.position = CGPointMake(settingsLabel.position.x, soundLabel.position.y-soundLabel.frame.size.height-35);
    backButton.name = (currentGameState == HMStatePause)?@"backToPause":@"backToMainMenu";
    [settingsMenu addChild:backButton];
    SKLabelNode *backButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    backButtonLabel.name = (currentGameState == HMStatePause)?@"backToPause":@"backToMainMenu";
    backButtonLabel.text = @"Back";
    backButtonLabel.fontSize = kButtonFontSize;
    backButtonLabel.fontColor = [SKColor yellowColor];
    backButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [backButton addChild:backButtonLabel];
}

- (void)setupPauseMenu
{
    SKNode *pauseMenu = [SKNode node];
    pauseMenu.name = @"PauseMenu";
    pauseMenu.zPosition = HMLayerMenu;
    [self addChild:pauseMenu];
    
    SKSpriteNode *darkScreen = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:self.size];
    darkScreen.anchorPoint = CGPointZero;
    darkScreen.alpha = kMenuDarkScreenAlpha;
    [pauseMenu addChild:darkScreen];
    
    SKLabelNode *pauseLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    pauseLabel.text = @"Paused";
    pauseLabel.fontSize = kTitleFontSize;
    pauseLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    pauseLabel.position = CGPointMake(self.size.width/2, self.size.height/1.3);
    [pauseMenu addChild:pauseLabel];
    
    SKSpriteNode *continueButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    continueButton.position = CGPointMake(pauseLabel.position.x-continueButton.size.width/2, pauseLabel.position.y-pauseLabel.frame.size.height-30);
    continueButton.name = @"Continue";
    [pauseMenu addChild:continueButton];
    SKLabelNode *continueButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    continueButtonLabel.name = @"Continue";
    continueButtonLabel.text = @"Continue";
    continueButtonLabel.fontSize = kButtonFontSize;
    continueButtonLabel.fontColor = [SKColor yellowColor];
    continueButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [continueButton addChild:continueButtonLabel];
    
    SKSpriteNode *settingsButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    settingsButton.position = CGPointMake(continueButton.position.x, continueButton.position.y-continueButton.frame.size.height-20);
    settingsButton.name = @"settingsButton";
    [pauseMenu addChild:settingsButton];
    SKLabelNode *settingsButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    settingsButtonLabel.name = @"settingsButton";
    settingsButtonLabel.text = @"Settings";
    settingsButtonLabel.fontSize = kButtonFontSize;
    settingsButtonLabel.fontColor = [SKColor yellowColor];
    settingsButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [settingsButton addChild:settingsButtonLabel];
    
    SKSpriteNode *mainMenuButton = [SKSpriteNode spriteNodeWithImageNamed:@"button"];
    mainMenuButton.position = CGPointMake(settingsButton.position.x, settingsButton.position.y-settingsButton.frame.size.height-20);
    mainMenuButton.name = @"MainMenuButton";
    [pauseMenu addChild:mainMenuButton];
    SKLabelNode *mainMenuButtonLabel = [SKLabelNode labelNodeWithFontNamed:kFont];
    mainMenuButtonLabel.name = @"MainMenuButton";
    mainMenuButtonLabel.text = @"Main Menu";
    mainMenuButtonLabel.fontSize = kButtonFontSize;
    mainMenuButtonLabel.fontColor = [SKColor yellowColor];
    mainMenuButtonLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    [mainMenuButton addChild:mainMenuButtonLabel];
    
    SKSpriteNode *refreshButton = [SKSpriteNode spriteNodeWithImageNamed:@"refreshbutton"];
    refreshButton.position = CGPointMake(mainMenuButton.position.x+mainMenuButton.size.width, (continueButton.position.y+mainMenuButton.position.y)/2.0);
    refreshButton.name = @"Refresh";
    [pauseMenu addChild:refreshButton];
}


#pragma mark - Updates

- (void)update:(NSTimeInterval)currentTime
{
    switch (_gameState) {
            
        case HMStateMainMenu:
            break;
            
        case HMStateSettings:
            break;
            
        case HMStatePause:
            break;
            
        case HMStateGamePlay:
            
            [self scrollBackground];
            [self checkBanana];
            [self checkStrengthBar];
            CGFloat accelerometer = _motionManager.accelerometerData.acceleration.y;
            accelerometer = (ABS(accelerometer) < 0.1)? 0 : accelerometer;
            accelerometer = (accelerometer > 0.4)? 0.4 : accelerometer;
            accelerometer = (accelerometer < -0.4)? -0.4 : accelerometer;
            accelerometer *= 2.5; //to make it range -1:1
            
            if (_flipAccelerometer) {
                accelerometer = -accelerometer;
            }
            
            if (_accelerometerOn) {
                [_monkey update:accelerometer];
            } else {
                [_monkey update:_joystick.x];
            }
            break;

        case HMStateGameOver:
            [_monkey update:0.0];
            break;
            
            case HMStateHowToPlay:
            break;
    }
}

- (void)checkBanana
{
    if (![_background childNodeWithName:@"Banana"]) {
        [self setupBanana];
    }
}

- (void)scrollBackground
{
    if ([self convertPoint:_monkey.position fromNode:_background].x >= self.frame.size.width/3*2) {
        _background.position = CGPointMake(_background.position.x-[self convertPoint:_monkey.position fromNode:_background].x+self.frame.size.width/3*2, 0.0);
    }
    
    if ([self convertPoint:_monkey.position fromNode:_background].x <= self.frame.size.width/3) {
        _background.position = CGPointMake(_background.position.x-[self convertPoint:_monkey.position fromNode:_background].x+self.frame.size.width/3, 0.0);
    }
    
    _background.position = CGPointMake(MIN(_background.position.x, 0.0), _background.position.y);
    
    _background.position = CGPointMake(MAX(_background.position.x, -_background.frame.size.width+self.frame.size.width), _background.position.y);
}

- (void)removeLife {
    
    _lives -= 1;
    SKLabelNode* lives = (SKLabelNode*)[[[self childNodeWithName:@"HUD"] childNodeWithName:@"livesHud"] childNodeWithName:@"lives"];
    lives.text = [NSString stringWithFormat:@"x %lu", (unsigned long)_lives];
    if (_lives <= 0) [self switchToGameOver];
}

- (void)addFly
{
    HMFly *fly = [HMFly node];
    fly.name = @"Fly";
    fly.zPosition = HMLayerGameSceneLayer;
    
    CGFloat locX;
    do {
        locX = RandomFloatRange(0+fly.size.width, _background.frame.size.width-fly.size.width);
    } while (CGRectContainsPoint(CGRectMake(_monkey.position.x-_monkey.size.width, 0, _monkey.size.width*2, _background.size.height), CGPointMake(locX, 0)));
    
    CGFloat locY = RandomFloatRange(kGroundLevel+fly.size.height, _background.frame.size.height-fly.size.height);
    fly.position = CGPointMake(locX, locY);
    [_background addChild:fly];
}

- (void)addStatue:(SKTexture*)texture position:(CGPoint)position
{
    SKSpriteNode *statue;
    
    if (texture == nil) {
        statue = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"statue_00"]];
        statue.position = CGPointMake(RandomFloatRange(0.0+statue.size.width/2, _background.size.width-statue.size.width/2), kGroundLevel+statue.size.height/2.2);
    } else {
        statue = [SKSpriteNode spriteNodeWithTexture:texture];
        statue.position = CGPointMake(position.x, kGroundLevel+statue.size.height/2.2);
    }
    
    statue.name = @"statue";
    statue.zPosition = HMLayerGameSceneLayer;
    [_background addChild:statue];

    statue.userData = [NSMutableDictionary dictionaryWithObjects:@[[_textureAtlas textureNamed:@"statue_00"],[_textureAtlas textureNamed:@"statue_01"],[_textureAtlas textureNamed:@"statue_02"],[_textureAtlas textureNamed:@"statue_03"],[_textureAtlas textureNamed:@"statue_04"],[_textureAtlas textureNamed:@"statue_05"]] forKeys:@[@"0texture",@"1texture",@"2texture",@"3texture",@"4texture",@"5texture"]];
    
    statue.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:statue.size];
    statue.physicsBody.dynamic = NO;
    statue.physicsBody.restitution = 1.0;
    statue.physicsBody.contactTestBitMask = HMColliderTypeMonkey;
}

#pragma mark - Switch State

- (void)switchToMainMenu
{
    [self setPaused:NO];
    [self removeAllChildren];
    _gameState = HMStateMainMenu;
    [self setupMainMenu];
}

- (void)switchToGamePlayWithResume:(BOOL)resume
{
    [self setPaused:NO];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    if (resume) {
        
        [[self childNodeWithName:@"PauseMenu"] removeFromParent];
        _gameState = HMStateGamePlay;
        if(_musicOn) [_backgroundMusicPlayer play];
        
            if (!_accelerometerOn) {
                if(![self childNodeWithName:@"Joystick"])[self setupJoystick];
            } else {
                [_joystick removeFromParent];
            }
        
    } else {
        
        [self removeAllChildren];
        _lives = kNumLives;
        _score = 0;
        _strength = 0;
        _gameState = HMStateGamePlay;
        _monkeyHit = NO;
        [self setupAccelerometer];
        [self setupPhysicsWorld];
        [self setupBackground];
        [self setupMonkey];
        [self setupBanana];
        [self setupFlies];
        [self setupHUD];
        if (!_accelerometerOn) [self setupJoystick];
        [self setupTouchLayer];
        [self setupPause];
        [self setupStrengthBar];
        _backgroundMusicPlayer.currentTime = 0;
        if(_musicOn) [_backgroundMusicPlayer play];
    }
}

- (void)switchToSettings:(HMGameState)currentGameState
{
    _gameState = HMStateSettings;
    [self setupSettingsMenu:currentGameState];
}

- (void)switchToGameOver
{
    _gameState = HMStateGameOver;
    [_backgroundMusicPlayer pause];
    [_monkey die];
    [_background removeActionForKey:@"FlySpawning"];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    SKSpriteNode *whiteNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:self.size];
    whiteNode.position = CGPointMake(self.size.width*0.5, self.size.height*0.5);
    whiteNode.zPosition = HMLayerFlash;
    [self addChild:whiteNode];
    [whiteNode runAction:[SKAction sequence:@[
                                              [SKAction fadeOutWithDuration:0.01],
                                              [SKAction waitForDuration:1],
                                              [SKAction performSelector:@selector(setupGameOverMenu) onTarget:self],
                                              [SKAction removeFromParent]
                                              ]] completion:^{if(_AdFlag){[_delegate presentInterstitialAd];}_AdFlag=!_AdFlag;}];
    
    if (_score > [self bestScore]) {
        [self setBestScore:_score];
    }
    
    [_delegate reportGameCenterScore:_score];
    
}

- (void)switchToHowToPlayState
{
    [self removeAllChildren];
    [self setupBackground];
    
    SKSpriteNode *howToPlayImage = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"howtoplay"]];
    howToPlayImage.name = @"HowToPlay";
    howToPlayImage.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:howToPlayImage];
    
    SKSpriteNode *dontUnchecked = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"dont"]];
    dontUnchecked.name = @"DontUnchecked";
    dontUnchecked.position = CGPointMake(howToPlayImage.size.width/2-dontUnchecked.size.width/2, howToPlayImage.size.height/2-dontUnchecked.size.height);
    [howToPlayImage addChild:dontUnchecked];
    
    SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"playbutton"];
    playButton.position = CGPointMake(dontUnchecked.position.x,dontUnchecked.position.y-dontUnchecked.size.height-playButton.size.height/2);
    playButton.name = @"Play";
    [howToPlayImage addChild:playButton];
    
    _gameState = HMStateHowToPlay;
}

- (void)switchToPauseState
{
    [self setPaused:YES];
    [_backgroundMusicPlayer pause];
    [self setupPauseMenu];
    _gameState = HMStatePause;
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)pauseGame
{
    if (_gameState == HMStateGamePlay) {
        [self switchToPauseState];
    }
    
    if (_gameState == HMStatePause) {
        [self setPaused:YES];
    }
    
    [_joystick reset];
}

#pragma mark - Reactions

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [_monkey jumpDown];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    switch (_gameState) {
        
        case HMStateMainMenu:
        {
            SKNode *touchedSprite = [self nodeAtPoint:[[touches anyObject] locationInNode:self]];
            if ([touchedSprite.name isEqualToString:@"PlayButton"]) {
                if(_soundOn) [self runAction:_click];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DontCheckedv1.4"]) {
                    [self switchToGamePlayWithResume:NO];
                } else {
                    [self switchToHowToPlayState];
                }
            } else if ([touchedSprite.name isEqualToString:@"SettingsButton"]) {
                if(_soundOn) [self runAction:_click];
                [self switchToSettings:_gameState];
            } else if ([touchedSprite.name isEqualToString:@"GameCenter"]) {
                if(_soundOn) [self runAction:_click];
                [_delegate showGameCenterwithChallengesView:NO];
            } else if ([touchedSprite.name isEqualToString:@"RateButton"]) {
                if(_soundOn) [self runAction:_click];
                [self rateApp];
            } else if ([touchedSprite.name isEqualToString:@"ChallengeButton"]) {
                if(_soundOn) [self runAction:_click];
                [_delegate showGameCenterwithChallengesView:YES];
            } else if ([touchedSprite.name isEqualToString:@"noAds"]) {
                if(_soundOn) [self runAction:_click];
                [_delegate NoAdsButton];
            }
            break;
        }
        
        case HMStateGamePlay:
        {
            SKNode *touchedSprite = [self nodeAtPoint:[[touches anyObject] locationInNode:self]];
            if ([touchedSprite.name isEqualToString:@"Pause"]) {
                [self switchToPauseState];
            } else if ([touchedSprite.name isEqualToString:@"TouchLayer"]){
                [_monkey jumpUp];
            } else if ([touchedSprite.name isEqualToString:@"strength"] || [touchedSprite.name isEqualToString:@"strengthBar"] || [touchedSprite.name isEqualToString:@"strengthBarLabel"]){
                
                if (!_monkey.isStrong) {
                    if (_strength >= kMegaStrengh) {
                        [self resetStrengthBar];
                        [self convertFliesToBananas];
                    } else if([[self childNodeWithName:@"strengthNode"] actionForKey:@"bigStrength"]) {
                        if(_soundOn) [self runAction:_monkeyStrong];
                        [_monkey strong];
                        [self resetStrengthBar];
                    }
                }
            }
            break;
        }
        
        case HMStatePause:
        {
            SKNode *touchedSprite = [self nodeAtPoint:[[touches anyObject] locationInNode:self]];
            if ([touchedSprite.name isEqualToString:@"Continue"]) {
                [self switchToGamePlayWithResume:YES];
                if(_soundOn) [self runAction:_click];
            } else if ([touchedSprite.name isEqualToString:@"MainMenuButton"]) {
                [self switchToMainMenu];
                if(_soundOn) [self runAction:_click];
            } else if ([touchedSprite.name isEqualToString:@"Refresh"]) {
                [self switchToGamePlayWithResume:NO];
                if(_soundOn) [self runAction:_click];
            } else if ([touchedSprite.name isEqualToString:@"settingsButton"]) {
                [self switchToSettings:_gameState];
                if(_soundOn) [self runAction:_click];
            }
            break;
        }
            
        case HMStateGameOver:
        {
            SKNode *touchedSprite = [self nodeAtPoint:[[touches anyObject] locationInNode:self]];
            if ([touchedSprite.name isEqualToString:@"PlayAgainButton"]) {
                if(_soundOn) [self runAction:_click];
                [self switchToGamePlayWithResume:NO];
            } else if ([touchedSprite.name isEqualToString:@"MainMenuButton"]) {
                if(_soundOn) [self runAction:_click];
                [self switchToMainMenu];
            } else if ([touchedSprite.name isEqualToString:@"GameCenter"]) {
                if(_soundOn) [self runAction:_click];
                [_delegate showGameCenterwithChallengesView:NO];
            } else if ([touchedSprite.name isEqualToString:@"RateButton"]) {
                if(_soundOn) [self runAction:_click];
                [self rateApp];
            }else if ([touchedSprite.name isEqualToString:@"ShareButton"]) {
                if(_soundOn) [self runAction:_click];
                [self shareScore];
            }else if ([touchedSprite.name isEqualToString:@"ChallengeButton"]) {
                if(_soundOn) [self runAction:_click];
                [_delegate challengeFriend];
            }
            break;
        }
            
        case HMStateSettings:
        {
            SKNode *touchedSprite = [self nodeAtPoint:[[touches anyObject] locationInNode:self]];
            if ([touchedSprite.name isEqualToString:@"backToPause"]) {
                if(_soundOn) [self runAction:_click];
                [self storeSettings];
                _gameState = HMStatePause;
                [[self childNodeWithName:@"SettingsMenu"] removeFromParent];
                
            } else if ([touchedSprite.name isEqualToString:@"backToMainMenu"]) {
                if(_soundOn) [self runAction:_click];
                [self storeSettings];
                _gameState = HMStateMainMenu;
                [[self childNodeWithName:@"SettingsMenu"] removeFromParent];
                
            } else if ([touchedSprite.name isEqualToString:@"AccelerometerBool"]) {
                if(_soundOn) [self runAction:_click];
                _accelerometerOn = !_accelerometerOn;
                [(SKLabelNode*)touchedSprite setText:_accelerometerOn?@"ON":@"OFF"];
                
            } else if ([touchedSprite.name isEqualToString:@"VibrationBool"]) {
                if(_soundOn) [self runAction:_click];
                _vibrationOn = !_vibrationOn;
                [(SKLabelNode*)touchedSprite setText:_vibrationOn?@"ON":@"OFF"];
            
            } else if ([touchedSprite.name isEqualToString:@"SoundBool"]) {
                _soundOn = !_soundOn;
                if(_soundOn) [self runAction:_click];
                [(SKLabelNode*)touchedSprite setText:_soundOn?@"ON":@"OFF"];
            } else if ([touchedSprite.name isEqualToString:@"MusicBool"]) {
                _musicOn = !_musicOn;
                if(_soundOn) [self runAction:_click];
                [(SKLabelNode*)touchedSprite setText:_musicOn?@"ON":@"OFF"];
            }
            break;
        }
            
            case HMStateHowToPlay:
        {
            SKNode *touchedSprite = [self nodeAtPoint:[[touches anyObject] locationInNode:self]];
            if ([touchedSprite.name isEqualToString:@"DontUnchecked"]) {
                if(_soundOn) [self runAction:_click];
                SKSpriteNode *howToPlayImage = (SKSpriteNode*)[self childNodeWithName:@"HowToPlay"];
                [[howToPlayImage childNodeWithName:@"DontUnchecked"] removeFromParent];
                
                SKSpriteNode *DontChecked = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"dontchecked"]];
                DontChecked.name = @"DontChecked";
                DontChecked.position = CGPointMake(howToPlayImage.size.width/2-DontChecked.size.width/2, howToPlayImage.size.height/2-DontChecked.size.height);
                [howToPlayImage addChild:DontChecked];
                
            } else if ([touchedSprite.name isEqualToString:@"DontChecked"]) {
                if(_soundOn) [self runAction:_click];
                SKSpriteNode *howToPlayImage = (SKSpriteNode*)[self childNodeWithName:@"HowToPlay"];
                [[howToPlayImage childNodeWithName:@"DontChecked"] removeFromParent];
                
                SKSpriteNode *DontUnchecked = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"dont"]];
                DontUnchecked.name = @"DontUnchecked";
                DontUnchecked.position = CGPointMake(howToPlayImage.size.width/2-DontUnchecked.size.width/2, howToPlayImage.size.height/2-DontUnchecked.size.height);
                [howToPlayImage addChild:DontUnchecked];
                
            } else if ([touchedSprite.name isEqualToString:@"Play"]) {
                if(_soundOn) [self runAction:_click];
                SKSpriteNode *howToPlayImage = (SKSpriteNode*)[self childNodeWithName:@"HowToPlay"];
                
                if ([howToPlayImage childNodeWithName:@"DontChecked"]) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DontCheckedv1.4"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                } else {
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DontCheckedv1.4"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                [self switchToGamePlayWithResume:NO];
            }
            break;
            }
    }
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    if (_gameState == HMStateGamePlay) {
        SKPhysicsBody *otherBody = contact.bodyA.categoryBitMask == HMColliderTypeMonkey ? contact.bodyB : contact.bodyA;
        
        switch (otherBody.categoryBitMask) {
            case HMColliderTypeBanana:
                if(_soundOn) [self runAction:_gotBanana];
                [otherBody.node removeFromParent];
                [self addScore];
                
                if ([self testSingleBanana]) {
                    [self updateStrengthBar];
                }
                
                break;
                
            case HMColliderTypeFly:
                if ([_monkey isStrong]) {
                    if(_soundOn) [self runAction:_killFly];
                    [self removeFly:otherBody.node];
                } else {
                    if (!_monkeyHit) {
                        if(_soundOn) [self runAction:_monkeyScream];
                        if(_vibrationOn) AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                        [self monkeyBlink];
                        [self removeLife];
                    }
                }
                break;
                
            case HMColliderTypeBackground:
                if (CGRectContainsPoint(CGRectMake(0, kGroundLevel-_monkey.size.height/2, self.size.width, _monkey.size.height), contact.contactPoint)) {
                    [_monkey onGround];
                }
                break;
                
                case HMColliderTypeLifeGinger:
                _lives++;
                if(_soundOn) [self runAction:_click];
                SKLabelNode* score = (SKLabelNode*)[[[self childNodeWithName:@"HUD"] childNodeWithName:@"livesHud"] childNodeWithName:@"lives"];
                [otherBody.node removeAllActions];
                [otherBody.node runAction:[SKAction moveTo:[_background convertPoint:score.parent.position fromNode:self] duration:0.2] completion:^{
                    score.text = [NSString stringWithFormat:@"x %lu", (unsigned long)_lives];
                    [otherBody.node removeFromParent];
                }];
                break;
        }
    }
}

-(void)deviceOrientationDidChange
{
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationLandscapeLeft:
            _flipAccelerometer = YES;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            _flipAccelerometer = NO;
            break;
            
        default:
            break;
    }
}

#pragma mark - Score

- (void)addScore {
    _score ++;
    SKLabelNode* score = (SKLabelNode*)[[[self childNodeWithName:@"HUD"] childNodeWithName:@"scoreHud"] childNodeWithName:@"score"];
    score.text = [NSString stringWithFormat:@"x %lu", (unsigned long)_score];
}

- (void)removeFly:(SKNode*)fly
{
    SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1],[SKAction fadeInWithDuration:0.1]]];
    SKAction *blinkForTime = [SKAction repeatAction:blink count:10];
    SKAction *rotate = [SKAction rotateByAngle:DegreesToRadians(360) duration:2];
    SKAction *scale = [SKAction scaleTo:0 duration:2];
    SKAction *group = [SKAction group:@[blinkForTime, rotate, scale]];
    
    fly.physicsBody.contactTestBitMask = 0;
    [fly runAction:group completion:^{
        [fly removeFromParent];
    }];
}

- (NSUInteger)bestScore {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"BestScore"];
}

- (void)setBestScore:(NSUInteger)bestScore {
    [[NSUserDefaults standardUserDefaults] setInteger:bestScore forKey:@"BestScore"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)monkeyBlink
{
    SKAction *animAction = [_monkey actionForKey:@"hit"];
    if (animAction) {
        return;
    }
    _monkeyHit = YES;
    SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1],[SKAction fadeInWithDuration:0.1]]];
    SKAction *blinkForTime = [SKAction repeatAction:blink count:5];
    SKAction *block = [SKAction runBlock:^{_monkeyHit = NO;}];
    SKAction *sequence = [SKAction sequence:@[blinkForTime, block]];
    [_monkey runAction:sequence withKey:@"hit"];
}

- (void)rateApp {
    
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8", APP_STORE_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

- (void)shareScore {
    
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%d?mt=8", APP_STORE_ID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    UIImage *screenshot = [_delegate screenshot];
    
    NSString *initialTextString = [NSString stringWithFormat:@"HEY! I collected %lu bananas in My Hungry Monkey!", (unsigned long)_score];
    [_delegate shareString:initialTextString url:url image:screenshot];
}

- (void)storeSettings
{
    [[NSUserDefaults standardUserDefaults] setBool:_accelerometerOn forKey:@"Accelerometer"];
    [[NSUserDefaults standardUserDefaults] setBool:_vibrationOn forKey:@"Vibration"];
    [[NSUserDefaults standardUserDefaults] setBool:_soundOn forKey:@"Sound"];
    [[NSUserDefaults standardUserDefaults] setBool:_musicOn forKey:@"Music"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Strength

- (void)setupStrengthBar
{
    SKNode *strengthNode = [SKNode node];
    strengthNode.zPosition = HMLayerControls;
    strengthNode.name = @"strengthNode";
    strengthNode.position = CGPointMake((self.size.width/2+[[self childNodeWithName:@"HUD"]childNodeWithName:@"livesHud"].position.x-[[self childNodeWithName:@"HUD"]childNodeWithName:@"livesHud"].frame.size.width/2)/2, [[self childNodeWithName:@"HUD"]childNodeWithName:@"scoreHud"].position.y);
    [self addChild:strengthNode];
    
    SKSpriteNode *strengthBar = [SKSpriteNode spriteNodeWithColor:[SKColor orangeColor] size:(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)? CGSizeMake(150.0, 20.0) : CGSizeMake(300.0, 40.0)];
    strengthBar.name = @"strengthBar";
    strengthBar.anchorPoint = CGPointZero;
    strengthBar.position = CGPointMake(-strengthBar.size.width/2, -strengthBar.size.height/2);
    strengthBar.xScale = 0.0;
    [strengthNode addChild:strengthBar];
    
    SKSpriteNode *strength = [SKSpriteNode spriteNodeWithTexture:[_textureAtlas textureNamed:@"powerBar"]];
    strength.name = @"strength";
    [strengthNode addChild:strength];
    
    SKLabelNode *fullLabel = [SKLabelNode labelNodeWithFontNamed:@"ChalkboardSE-Bold"];
    fullLabel.name = @"strengthBarLabel";
    fullLabel.fontColor = [SKColor yellowColor];
    fullLabel.fontSize = (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)? 14 : 28;
    fullLabel.text = @"Power";
    fullLabel.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    fullLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    [strengthNode addChild:fullLabel];
}

- (void)updateStrengthBar
{
    _strength++;
    
    SKSpriteNode *strengthBar = (SKSpriteNode*)[[self childNodeWithName:@"strengthNode"] childNodeWithName:@"strengthBar"];
    
    if (_strength <= kMegaStrengh) {
        [strengthBar runAction:[SKAction scaleXTo:((float)_strength)/(float)kMegaStrengh duration:0.5]];
    }
    
    if (_strength%kHeartAppearance == 0) {
        [self setupHeart];
    }
}

- (void)checkStrengthBar
{
    SKSpriteNode *strengthBar = (SKSpriteNode*)[[self childNodeWithName:@"strengthNode"] childNodeWithName:@"strengthBar"];
    
    if (![strengthBar actionForKey:@"reset"]) {
        
        if([[self childNodeWithName:@"strengthNode"] childNodeWithName:@"strengthBar"].xScale >= 1.0) {
            strengthBar.color = [SKColor purpleColor];
            [(SKLabelNode*)[strengthBar.parent childNodeWithName:@"strengthBarLabel"] setText:@"!!! TAP !!!"];
            [(SKLabelNode*)[strengthBar.parent childNodeWithName:@"strengthBarLabel"] setHorizontalAlignmentMode:SKLabelHorizontalAlignmentModeRight];
            
            if (![strengthBar.parent actionForKey:@"megaStrength"]) {
                SKAction *rotateSequence = [SKAction repeatActionForever:[SKAction sequence:@[[SKAction rotateToAngle:DegreesToRadians(2.5) duration:0.1],[SKAction rotateToAngle:DegreesToRadians(-2.5) duration:0.1]]]];
                [strengthBar.parent runAction:rotateSequence withKey:@"megaStrength"];
            }
        } else if (strengthBar.position.x+strengthBar.size.width >= kStrengthBarThreshold) {
            strengthBar.color = [SKColor redColor];
            [(SKLabelNode*)[strengthBar.parent childNodeWithName:@"strengthBarLabel"] setText:@"Tap or Wait"];
            [(SKLabelNode*)[strengthBar.parent childNodeWithName:@"strengthBarLabel"] setHorizontalAlignmentMode:SKLabelHorizontalAlignmentModeCenter];
            
            if (![strengthBar.parent actionForKey:@"bigStrength"]) {
                [strengthBar.parent runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction scaleTo:1.1 duration:0.5],[SKAction scaleTo:1.0 duration:0.5]]]] withKey:@"bigStrength"];
            }
        }
        
    }
    
}

- (void)resetStrengthBar
{
    _strength = 0;
    SKSpriteNode *strengthBar = (SKSpriteNode*) [[self childNodeWithName:@"strengthNode"] childNodeWithName:@"strengthBar"];
    [strengthBar.parent removeAllActions];
    strengthBar.parent.zRotation = 0.0;
    [strengthBar.parent setScale:1.0];
    strengthBar.color = [SKColor orangeColor];
    [strengthBar runAction:[SKAction scaleXTo:0.0 duration:0.5] withKey:@"reset"];
    [(SKLabelNode*)[strengthBar.parent childNodeWithName:@"strengthBarLabel"] setText:@"Power"];
    [(SKLabelNode*)[strengthBar.parent childNodeWithName:@"strengthBarLabel"] setHorizontalAlignmentMode:SKLabelHorizontalAlignmentModeRight];
}

- (void)convertFliesToBananas
{
    [_background enumerateChildNodesWithName:@"Fly" usingBlock:^(SKNode *node, BOOL *stop) {
        [self setupBanana:node.position];
        [node removeFromParent];
    }];
}

- (BOOL)testSingleBanana
{
    __block int sum = 0;
    
    [_background enumerateChildNodesWithName:@"Banana" usingBlock:^(SKNode *node, BOOL *stop) {
       sum++;
    }];
    
    if (sum > 1) {
        return NO;
    } else {
        return YES;
    }
}

- (void)debug
{
    SKLabelNode *label = (SKLabelNode*)[self childNodeWithName:@"debug"];
    
    if (!label) {
        label = [SKLabelNode labelNodeWithFontNamed:kFont];
        label.name = @"debug";
        label.fontSize = kHUDFontSize;
        label.position = CGPointMake(self.size.width/2, self.size.height-20.0);
        [self addChild:label];
    }
    
    label.text = [NSString stringWithFormat:@"%lu", (unsigned long)_strength];
}

@end
