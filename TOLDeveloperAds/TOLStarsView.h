//
//  TOLStarsView.h
//  DeveloperAdsDemo
//
//  Created by Lars Anderson on 2/5/13.
//  Copyright (c) 2013 Lars Anderson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TOLStarsView : UIView

- (instancetype)initWithFullStarsImage:(UIImage *)fullStarsImage emptyStars:(UIImage *)emptyStarsImage;

- (void)setPercentage:(CGFloat)percentage;

@end
