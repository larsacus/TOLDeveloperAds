//
//  TOLDeveloperBannerProtocol.h
//  DeveloperAdsDemo
//
//  Created by Lars Anderson on 2/5/13.
//  Copyright (c) 2013 Lars Anderson. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TOLDeveloperBannerProtocol <NSObject>

- (void)setSecondaryColor:(UIColor *)secondaryColor;

@required
- (void)setPercentage:(CGFloat)percentage;
- (void)setAppName:(NSString *)appName;
- (void)setPrice:(NSString *)appPrice;
- (void)setPrimaryColor:(UIColor *)primaryColor;
- (void)setAppIconImage:(UIImage *)iconImage;
- (void)setOrientation:(UIInterfaceOrientation)orientation;

- (CGSize)iconImageSize;

@end
