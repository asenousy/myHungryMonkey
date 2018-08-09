//
//  HMMonkey.m
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 21/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import "HMMonkey.h"

typedef NS_ENUM(NSUInteger, HMMyState){
    HMStateWalk,
    HMStateJump,
    HMStateFall,
    HMStateDead
};

static const float kAnimationSpeed = 0.25;
static CGFloat kMonkeySpeed;

@implementation HMMonkey
{
    SKTextureAtlas *_textureAtlas;
    HMMyState _myState;
    SKAction *_walkRight, *_walkLeft;
}
- (id)initWithPosition:(CGPoint)position
{
    _textureAtlas = [HMTextureAtlas sharedInstance];
    
    if (self = [super initWithTexture:[_textureAtlas textureNamed:@"monkey_idle"]]) {
        
        _myState = HMStateWalk;
        self.position = position;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            kMonkeySpeed = 120;
        } else {
            kMonkeySpeed = 250;
        }
        
        SKTexture *w1 = [_textureAtlas textureNamed:@"monkey_walk_right_1"];
        SKTexture *w2 = [_textureAtlas textureNamed:@"monkey_walk_right_2"];
        SKTexture *w3 = [_textureAtlas textureNamed:@"monkey_walk_right_3"];
        SKTexture *w4 = [_textureAtlas textureNamed:@"monkey_walk_right_4"];
        NSArray *walkRightTextures = @[w1,w2,w3,w4];
        SKTexture *w5 = [_textureAtlas textureNamed:@"monkey_walk_left_1"];
        SKTexture *w6 = [_textureAtlas textureNamed:@"monkey_walk_left_2"];
        SKTexture *w7 = [_textureAtlas textureNamed:@"monkey_walk_left_3"];
        SKTexture *w8 = [_textureAtlas textureNamed:@"monkey_walk_left_4"];
        NSArray *walkLeftTextures = @[w5,w6,w7,w8];
        
        _walkRight = [SKAction animateWithTextures:walkRightTextures timePerFrame:kAnimationSpeed];
        _walkLeft = [SKAction animateWithTextures:walkLeftTextures timePerFrame:kAnimationSpeed];
        
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width-self.frame.size.width/2, self.frame.size.height-self.frame.size.height/6)];
        self.physicsBody.restitution = 0;
        self.physicsBody.mass = 1;
        self.physicsBody.allowsRotation = NO;
        self.physicsBody.friction = 0;
        self.physicsBody.categoryBitMask = HMColliderTypeMonkey;
        self.physicsBody.collisionBitMask = HMColliderTypeBackground;
    }
    return self;
}

#pragma mark - Updates

- (void)update:(CGFloat)movement
{
    switch (_myState) {
        case HMStateWalk:
            [self move:movement];
            break;
            
        case HMStateJump:
            [self checkJumpPeak];
            [self move:movement];
            break;
            
        case HMStateFall:
            [self move:movement];
            break;
            
        case HMStateDead:
            break;
    }
        [self adjustTextures];
}

- (void)move:(CGFloat)movement
{
    movement = movement * kMonkeySpeed;
    
        if (movement == 0) {
            self.physicsBody.velocity = CGVectorMake(0.0, self.physicsBody.velocity.dy);
        } else {
            
            self.physicsBody.velocity = CGVectorMake(_myState==HMStateWalk?movement:movement*1.5, self.physicsBody.velocity.dy);
        }
}

- (void)adjustTextures
{
    switch (_myState) {
            
        case HMStateJump:
            if (self.physicsBody.velocity.dx == 0) {
                self.texture = [_textureAtlas textureNamed:@"monkey_jump_up"];
            } else if (self.physicsBody.velocity.dx > 0) {
                self.texture = [_textureAtlas textureNamed:@"monkey_jump_right_up"];
            } else {
                self.texture = [_textureAtlas textureNamed:@"monkey_jump_left_up"];
            }
            break;
            
        case HMStateFall:
            if (self.physicsBody.velocity.dx == 0) {
                self.texture = [_textureAtlas textureNamed:@"monkey_cheer"];
            } else if (self.physicsBody.velocity.dx > 0) {
                self.texture = [_textureAtlas textureNamed:@"monkey_jump_right_down"];
            } else {
                self.texture = [_textureAtlas textureNamed:@"monkey_jump_left_down"];
            }
            break;
            
        case HMStateWalk:
            if (self.physicsBody.velocity.dx != 0) {
                if (self.physicsBody.velocity.dx > 0) {
                    [self animatewithKey:@"walkRight"];
                } else {
                    [self animatewithKey:@"walkLeft"];
                }
            } else {
                [self stopWalking];
                self.texture = [_textureAtlas textureNamed:@"monkey_idle"];
            }
            break;
            
        case HMStateDead:
            self.texture = [_textureAtlas textureNamed:@"monkey_dead"];
            break;
    }
}

#pragma mark - Switch State

- (void)switchToWalkState
{
    _myState = HMStateWalk;
}

- (void)switchToJumpState
{
    [self stopWalking];
    _myState = HMStateJump;
    self.physicsBody.velocity = CGVectorMake(self.physicsBody.velocity.dx, (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?500:1145);
}

- (void)switchToFallState
{
    _myState = HMStateFall;
}

- (void)switchToDeadState
{
    [self removeAllActions];
    _myState = HMStateDead;
    self.physicsBody.velocity = CGVectorMake(0, 0);
    self.physicsBody.affectedByGravity = NO;
    SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1],[SKAction fadeInWithDuration:0.1]]];
    SKAction *blinkForTime = [SKAction repeatAction:blink count:10];
    [self runAction:blinkForTime];
}

#pragma mark - Reactions

- (void)animatewithKey:(NSString *)animationKey
{
    SKAction *animAction = [self actionForKey:animationKey];
    if (animAction) {
        return;
    }
    [self stopWalking];
    [self runAction: [animationKey isEqualToString:@"walkRight"]?_walkRight:_walkLeft withKey:animationKey];
}

- (void)stopWalking
{
   [self removeActionForKey:@"walkLeft"];
    [self removeActionForKey:@"walkRight"];
}

- (void)jumpUp
{
    if (_myState == HMStateWalk) {
        [self switchToJumpState];
    }
}

- (void)die
{
    [self switchToDeadState];
}

- (void)onGround
{
    [self switchToWalkState];
}

- (void)jumpDown
{
    if (_myState == HMStateJump) {
        self.physicsBody.velocity = CGVectorMake(self.physicsBody.velocity.dx, self.physicsBody.velocity.dy/3);
    }
}

- (void)checkJumpPeak
{
    if (self.physicsBody.velocity.dy < 0) {
        [self switchToFallState];
    }
}

- (void)strong
{
    self.color = [SKColor redColor];
    SKAction *seq1 = [SKAction colorizeWithColorBlendFactor:1.0 duration:0.1];
    SKAction *seq2 = [SKAction waitForDuration:7];
    SKAction *redBlink = [SKAction sequence:@[[SKAction colorizeWithColor:[SKColor redColor] colorBlendFactor:0.0 duration:0.1],[SKAction colorizeWithColorBlendFactor:1.0 duration:0.1]]];
    SKAction *seq3 = [SKAction repeatAction:redBlink count:10];
    SKAction *seq4 = [SKAction colorizeWithColorBlendFactor:0.0 duration:0.1];
    
    [self runAction:[SKAction sequence:@[seq1, seq2, seq3, seq4]] withKey:@"strong"];
}

- (BOOL)isStrong
{
    if ([self actionForKey:@"strong"]) {
        return YES;
    } else {
        return NO;
    }
}

@end
