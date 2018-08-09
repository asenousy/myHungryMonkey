//
//  HMJoystick.m
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 25/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import "HMJoystick.h"

@interface HMJoystick ()

@property (nonatomic, strong) SKShapeNode *interior;
@property float angle;
@property (nonatomic,strong) UITouch *onlyTouch;
@property float radiusSR2;
@property SKColor *baseColor;
@property SKColor *joystickColor;

@end

@implementation HMJoystick

-(id)init
{
    if((self = [super init]))
    {        
        self.controlRadius = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?40:80;
        self.baseRadius = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?45:90;
        self.joystickRadius = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?27:50;
        self.baseColor = [SKColor whiteColor];
        self.joystickColor = [SKColor redColor];
        self.onlyTouch = nil;
        self.name = @"Joystick";
        [self setUserInteractionEnabled:YES];
        
        CGMutablePathRef circlePath = CGPathCreateMutable();
        CGPathAddRect(circlePath, NULL, CGRectMake(self.position.x-self.controlRadius-self.joystickRadius, self.position.y-self.joystickRadius, self.controlRadius*2+self.joystickRadius*2, self.joystickRadius*2));
        self.path = circlePath;
        self.fillColor =  [SKColor clearColor];
        self.alpha = 0.4;
        self.lineWidth = 0.0;
        CGPathRelease( circlePath );
        
        
        SKShapeNode *dummy = [SKShapeNode node];
        dummy.name = @"Joystick";
        circlePath = CGPathCreateMutable();
        CGPathAddEllipseInRect(circlePath , NULL , CGRectMake(self.position.x-self.baseRadius, self.position.y-10, self.baseRadius*2, 20) );
        dummy.path = circlePath;
        dummy.fillColor =  self.baseColor;
        dummy.lineWidth = 0.0;
        CGPathRelease( circlePath );
        [self addChild:dummy];
        
        
        self.interior = [SKShapeNode node];
        self.interior.name = @"Joystick";
        circlePath = CGPathCreateMutable();
        CGPathAddEllipseInRect(circlePath , NULL , CGRectMake(self.position.x-self.joystickRadius, self.position.y-self.joystickRadius, self.joystickRadius*2, self.joystickRadius*2));
        self.interior.path = circlePath;
        self.interior.fillColor =  self.joystickColor;
        self.interior.lineWidth = 0.0;
        CGPathRelease( circlePath );
        [self addChild:self.interior];
    }
    return self;
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (!self.onlyTouch) {
        [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            SKNode *touchedSprite = [self.scene nodeAtPoint:[obj locationInNode:self.scene]];
            if ([touchedSprite.name isEqualToString:@"Joystick"])
            {
                self.onlyTouch = obj;
                [self touchesMoved:touches withEvent:event];
            }
        }];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if(!self.onlyTouch){
        return;
    }
    CGPoint location = [self.onlyTouch locationInNode:[self parent]];
    CGFloat newx = location.x;
    if(newx>self.position.x + self.controlRadius){
        newx = self.position.x + self.controlRadius;
    }
    if(newx<self.position.x - self.controlRadius){
        newx = self.position.x - self.controlRadius;
    }
    self.interior.position=[self convertPoint:CGPointMake(newx, self.position.y) fromNode:[self parent]];
    self.x = (newx-self.position.x)/self.controlRadius;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if ([[touches allObjects] containsObject:self.onlyTouch]) {
        self.onlyTouch = nil;
        self.interior.position=CGPointMake(0,0);
        self.x = 0;
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if ([[touches allObjects] containsObject:self.onlyTouch]) {
        self.onlyTouch = nil;
        self.interior.position=CGPointMake(0,0);
        self.x = 0;
    }
}

-(void)reset
{
    self.onlyTouch = nil;
    self.interior.position=CGPointMake(0,0);
    self.x = 0;
}

@end
