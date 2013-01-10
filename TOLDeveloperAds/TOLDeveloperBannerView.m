//
//  TOLDeveloperBannerView.m
//  DeveloperAdsDemo
//
//  Created by Lars Anderson on 1/9/13.
//  Copyright (c) 2013 Lars Anderson. All rights reserved.
//

#import "TOLDeveloperBannerView.h"
#import <QuartzCore/QuartzCore.h>

/** portrait constants */
CGFloat const kTOLDeveloperBannerViewPadHeightPortrait = 90.f;
CGFloat const kTOLDeveloperBannerViewPodHeightPortrait = 50.f;
CGFloat const kTOLDeveloperBannerViewPadWidthPortrait = 768.f;
CGFloat const kTOLDeveloperBannerViewPodWidthPortrait = 320.f;

/** landscape constants */
CGFloat const kTOLDeveloperBannerViewPadHeightLandscape = 50.f;
CGFloat const kTOLDeveloperBannerViewPodHeightLandscape = 35.f;
CGFloat const kTOLDeveloperBannerViewPadWidthLandscape = 1024.f;
CGFloat const kTOLDeveloperBannerViewPodWidthLandscape = 480.f;

@implementation TOLDeveloperBannerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat iconHeight = 40.f;
        CGRect iconFrame = CGRectMake(5.f,
                                      (CGRectGetHeight(frame)-iconHeight)/2,
                                      iconHeight,
                                      iconHeight);
        _appIconImageView = [[UIImageView alloc] initWithFrame:iconFrame];
        _appIconImageView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        
        CGFloat appNameHeight = 30.f;
        CGRect appNameFrame = CGRectMake(CGRectGetMaxX(iconFrame) + 10.f,
                                         (CGRectGetHeight(frame)-appNameHeight)/2,
                                         CGRectGetWidth(frame)-CGRectGetMaxX(iconFrame)-20.f,
                                         appNameHeight);
        _appNameLabel = [[UILabel alloc] initWithFrame:appNameFrame];
        _appNameLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        
        CGColorRef redColor = CGColorRetain([UIColor redColor].CGColor);
        
        _appNameLabel.layer.borderColor = redColor;
        _appNameLabel.layer.borderWidth = 1.f;
        
        _appIconImageView.layer.borderColor = redColor;
        _appIconImageView.layer.borderWidth = 1.f;
        
        [self addSubview:_appIconImageView];
        [self addSubview:_appNameLabel];
        
        self.backgroundColor = [UIColor greenColor];
        
        CGColorRelease(redColor);
    }
    return self;
}

@end
