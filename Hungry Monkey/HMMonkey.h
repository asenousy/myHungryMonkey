//
//  HMMonkey.h
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 21/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface HMMonkey : SKSpriteNode

- (id)initWithPosition:(CGPoint)position;
- (void)update:(CGFloat)movement;
- (void)onGround;
- (void)die;
- (void)strong;
- (BOOL)isStrong;

- (void)jumpUp;
- (void)jumpDown;

@end
