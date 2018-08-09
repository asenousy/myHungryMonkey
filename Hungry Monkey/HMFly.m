//
//  HMFly.m
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 27/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import "HMFly.h"

@implementation HMFly
{
    SKTextureAtlas *_textureAtlas;
    SKAction *_flapRight, *_flapLeft;
}
- (id)init
{
    _textureAtlas = [HMTextureAtlas sharedInstance];
    
    if (self = [super initWithTexture:[_textureAtlas textureNamed:@"fly_right_1"]]) {
        SKTexture *w1 = [_textureAtlas textureNamed:@"fly_right_1"];
        SKTexture *w2 = [_textureAtlas textureNamed:@"fly_right_2"];
        SKTexture *w3 = [_textureAtlas textureNamed:@"fly_left_1"];
        SKTexture *w4 = [_textureAtlas textureNamed:@"fly_left_2"];
        NSArray *rightTextures = @[w1,w2];
        NSArray *leftTextures = @[w3,w4];
        _flapRight = [SKAction repeatActionForever:[SKAction animateWithTextures:rightTextures timePerFrame:0.08]];
        _flapLeft = [SKAction repeatActionForever:[SKAction animateWithTextures:leftTextures timePerFrame:0.08]];
        
        self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:self.size.width/2.5];
        self.physicsBody.restitution = 0;
        self.physicsBody.mass = 1;
        self.physicsBody.allowsRotation = NO;
        self.physicsBody.friction = 0;
        self.physicsBody.affectedByGravity = NO;
        self.physicsBody.categoryBitMask = HMColliderTypeFly;
        self.physicsBody.collisionBitMask = HMColliderTypeBackground;
        
        [self animateSpawning];
        
    }
    return self;
}

- (void)animateSpawning
{
    [self setScale:0];
    SKAction *blink = [SKAction sequence:@[[SKAction fadeOutWithDuration:0.1],[SKAction fadeInWithDuration:0.1]]];
    SKAction *blinkForTime = [SKAction repeatAction:blink count:10];
    SKAction *rotate = [SKAction rotateByAngle:DegreesToRadians(360) duration:2];
    SKAction *scale = [SKAction scaleTo:1 duration:2];
    SKAction *group = [SKAction group:@[blinkForTime, rotate, scale]];
    [self runAction:group completion:^{
        self.physicsBody.contactTestBitMask = HMColliderTypeMonkey;
        
        [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction performSelector:@selector(changeVelocity) onTarget:self], [SKAction waitForDuration:5 withRange:4]]]]];
    }];
}

- (void)changeVelocity
{
    self.physicsBody.velocity = CGVectorMake(RandomFloatRange(-100, 100), RandomFloatRange(-100, 100));
    
    if (self.physicsBody.velocity.dx > 0) {
        [self runAction:_flapRight];
    } else {
        [self runAction:_flapLeft];
    }
}

@end
