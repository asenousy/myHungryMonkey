//
//  HMJoystick.h
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 25/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface HMJoystick : SKShapeNode

@property float joystickRadius;
@property float baseRadius;
@property float controlRadius;
@property CGFloat x;

- (void)reset;

@end
