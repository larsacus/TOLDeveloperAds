//
//  TOLDeveloperBannerView.h
//  DeveloperAdsDemo
//
//  Created by Lars Anderson on 1/9/13.
//  Copyright (c) 2013 Lars Anderson. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const kTOLDeveloperBannerViewPadHeightPortrait;
extern CGFloat const kTOLDeveloperBannerViewPodHeightPortrait;
extern CGFloat const kTOLDeveloperBannerViewPadWidthPortrait;
extern CGFloat const kTOLDeveloperBannerViewPodWidthPortrait;

extern CGFloat const kTOLDeveloperBannerViewPadHeightLandscape;
extern CGFloat const kTOLDeveloperBannerViewPodHeightLandscape;
extern CGFloat const kTOLDeveloperBannerViewPadWidthLandscape;
extern CGFloat const kTOLDeveloperBannerViewPodWidthLandscape;
extern CGFloat const kTOLDeveloperBannerViewPodWidthLandscapeGiraffe;


@interface TOLDeveloperBannerView : UIView

@property (nonatomic, strong) UIImageView *appIconImageView;
@property (nonatomic, strong) UILabel *appNameLabel;
@property (nonatomic, strong) UILabel *priceLabel;

@end
