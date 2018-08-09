//
//  HMTextureAtlas.h
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 24/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

typedef enum : uint8_t {
    HMColliderTypeBackground = 1,
    HMColliderTypeMonkey = 2,
    HMColliderTypeFly = 4,
    HMColliderTypeBanana = 8,
    HMColliderTypeLifeGinger = 16
} HMColliderType;

@interface HMTextureAtlas : NSObject

+ (SKTextureAtlas*)sharedInstance;

@end
