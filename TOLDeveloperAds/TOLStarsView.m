//
//  TOLStarsView.m
//  DeveloperAdsDemo
//
//  Created by Lars Anderson on 2/5/13.
//  Copyright (c) 2013 Lars Anderson. All rights reserved.
//

#import "TOLStarsView.h"

@interface TOLStarsView ()

@property (nonatomic, strong) UIImageView *emptyStars;
@property (nonatomic, strong) UIImageView *fullStars;

@end

@implementation TOLStarsView

- (instancetype)initWithFullStarsImage:(UIImage *)fullStarsImage emptyStars:(UIImage *)emptyStarsImage{
    NSAssert(fullStarsImage.size.width == emptyStarsImage.size.width, @"Both images must be the same width");
    NSAssert(fullStarsImage.size.height == emptyStarsImage.size.height, @"Both images must be the same height");
    
    CGRect frame = CGRectMake(0.f,
                              0.f,
                              fullStarsImage.size.width,
                              fullStarsImage.size.height);
    self = [super initWithFrame:CGRectIntegral(frame)];
    if (self) {
        self.emptyStars = [[UIImageView alloc] initWithImage:emptyStarsImage];
        self.emptyStars.contentMode = UIViewContentModeRight;
        self.emptyStars.clipsToBounds = YES;
        
        self.fullStars = [[UIImageView alloc] initWithImage:fullStarsImage];
        self.fullStars.contentMode = UIViewContentModeLeft;
        self.fullStars.clipsToBounds = YES;
        
        [self addSubview:self.emptyStars];
        [self addSubview:self.fullStars];//full stars on top
    }
    return self;
}

- (void)setPercentage:(CGFloat)percentage{
    NSAssert(percentage <= 1.f && percentage >= 0.f, @"Percentage must be between 0 and 1");
    
    CGRect emptyFrame = CGRectMake(CGRectGetWidth(self.frame)*percentage,
                                   0.f,
                                   CGRectGetWidth(self.frame)*(1.f-percentage),
                                   CGRectGetHeight(self.frame));
    CGRect fullFrame = CGRectMake(0.f,
                                  0.f,
                                  CGRectGetWidth(self.frame)*percentage,
                                  CGRectGetHeight(self.frame));
    
    self.emptyStars.frame = CGRectIntegral(emptyFrame);
    self.fullStars.frame = CGRectIntegral(fullFrame);
}

@end
