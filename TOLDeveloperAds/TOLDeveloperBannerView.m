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
CGFloat const kTOLDeveloperBannerViewPodWidthLandscapeGiraffe = 568.f;

@implementation TOLDeveloperBannerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _appIconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _appIconImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        
        _appNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _appNameLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        _appNameLabel.backgroundColor = [UIColor clearColor];
        
//        CGColorRef redColor = CGColorRetain([UIColor redColor].CGColor);
//        
//        _appNameLabel.layer.borderColor = redColor;
//        _appNameLabel.layer.borderWidth = 1.f;
//        
//        CGColorRelease(redColor);
        
        _appIconImageView.layer.cornerRadius = 5.f;
        _appIconImageView.clipsToBounds = YES;
        _appIconImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [self addSubview:_appIconImageView];
        [self addSubview:_appNameLabel];
        
        self.backgroundColor = [UIColor greenColor];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    
    CGFloat margin = 5.f;
    CGFloat iconHeight = CGRectGetHeight(frame)-margin*2;
    CGRect iconFrame = CGRectMake(margin,
                                  margin,
                                  iconHeight,
                                  iconHeight);
    self.appIconImageView.frame = iconFrame;
    
    CGFloat appNameHeight = 30.f;
    CGRect appNameFrame = CGRectMake(CGRectGetMaxX(iconFrame) + 10.f,
                                     (CGRectGetHeight(frame)-appNameHeight)/2,
                                     CGRectGetWidth(frame)-CGRectGetMaxX(iconFrame)-20.f,
                                     appNameHeight);
    self.appNameLabel.frame = appNameFrame;

}

@end
