//
//  HMTextureAtlas.m
//  Hungry Monkey
//
//  Created by Ahmed ElSenousi on 24/03/2014.
//  Copyright (c) 2014 Ahmed ElSenousi. All rights reserved.
//

#import "HMTextureAtlas.h"

@implementation HMTextureAtlas

+ (SKTextureAtlas*)sharedInstance
{
    static SKTextureAtlas *_sharedInstance = nil;

    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [SKTextureAtlas atlasNamed:[NSString stringWithFormat:@"HungryMonkey-%@",(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)?@"iphone":@"ipad"]];
    });
    return _sharedInstance;
}

@end
