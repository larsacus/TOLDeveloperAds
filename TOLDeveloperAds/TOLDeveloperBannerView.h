//
//  TOLDeveloperBannerView.h
//  DeveloperAdsDemo
//
//  Created by Lars Anderson on 1/9/13.
//  Copyright (c) 2013 Lars Anderson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOLDeveloperBannerProtocol.h"

extern CGFloat const kTOLDeveloperBannerViewPadHeightPortrait;
extern CGFloat const kTOLDeveloperBannerViewPodHeightPortrait;
extern CGFloat const kTOLDeveloperBannerViewPadWidthPortrait;
extern CGFloat const kTOLDeveloperBannerViewPodWidthPortrait;

extern CGFloat const kTOLDeveloperBannerViewPadHeightLandscape;
extern CGFloat const kTOLDeveloperBannerViewPodHeightLandscape;
extern CGFloat const kTOLDeveloperBannerViewPadWidthLandscape;
extern CGFloat const kTOLDeveloperBannerViewPodWidthLandscape;
extern CGFloat const kTOLDeveloperBannerViewPodWidthLandscapeGiraffe;


@interface TOLDeveloperBannerView : UIView <TOLDeveloperBannerProtocol>

@property (nonatomic, strong) UIColor *secondaryColor;
@property (nonatomic) CGFloat percentage;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *price;
@property (nonatomic, strong) UIColor *primaryColor;
@property (nonatomic, strong) UIImage *appIconImage;
@property (nonatomic) UIInterfaceOrientation orientation;

@end
