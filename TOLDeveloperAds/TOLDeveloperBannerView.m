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

@interface TOLDeveloperBannerViewFrame : UIView

@end

@interface TOLDeveloperBannerView ()

@property (nonatomic, strong) TOLDeveloperBannerViewFrame *bannerFrame;

@end

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
        
        self.bannerFrame = [[TOLDeveloperBannerViewFrame alloc] initWithFrame:self.bounds];
        self.bannerFrame.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:_appIconImageView];
        [self addSubview:_appNameLabel];
        [self addSubview:self.bannerFrame];
        
        self.backgroundColor = [UIColor greenColor];
    }
    return self;
}

- (void)setNeedsDisplay{
    [super setNeedsDisplay];
    [self.bannerFrame setNeedsDisplay];
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

@implementation TOLDeveloperBannerViewFrame

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect{
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    {
        CGContextClearRect(context, rect);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGFloat margin = 4.f;
        
        //icon cutout
        CGFloat iconDimension = CGRectGetHeight(rect)-margin*2;
        CGRect iconRect = CGRectMake(margin, margin, iconDimension, iconDimension);
        CGFloat contentXOrigin = CGRectGetWidth(iconRect)+margin*2;
        CGRect contentRect = CGRectMake(contentXOrigin,
                                        margin,
                                        CGRectGetWidth(rect)-CGRectGetWidth(iconRect)-3*margin,
                                        CGRectGetHeight(rect)-margin*2);
        
        UIBezierPath *iconCutout = [[UIBezierPath bezierPathWithRoundedRect:iconRect cornerRadius:margin*2] bezierPathByReversingPath];
        UIBezierPath *contentCutout = [[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:margin*2] bezierPathByReversingPath];
        UIBezierPath *fullRectPath = [UIBezierPath bezierPathWithRect:rect];
        [fullRectPath appendPath:contentCutout];
        [fullRectPath appendPath:iconCutout];
        
        CGContextSaveGState(context);
        {
            CGRect shadowContentRect = CGRectMake(contentXOrigin-2.f,
                                                  0.f,
                                                  CGRectGetWidth(rect)-contentXOrigin,
                                                  CGRectGetHeight(rect));
            
            //bounds shadow to content region
            UIBezierPath *clippingPath = [UIBezierPath bezierPathWithRect:contentRect];
            CGContextAddPath(context, clippingPath.CGPath);
            CGContextClip(context);
            
            
            UIBezierPath *shadowContentCutoutPath = [[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:margin*2] bezierPathByReversingPath];
            
            //creates path that will create shadow
            UIBezierPath *shadowRectPath = [UIBezierPath bezierPathWithRect:shadowContentRect];
            [shadowRectPath appendPath:shadowContentCutoutPath];
            
            [[UIColor whiteColor] setFill];
            
            CGColorRef redColor = CGColorRetain([UIColor colorWithWhite:0.f alpha:0.5f].CGColor);
            CGContextSetShadowWithColor(context, CGSizeZero, margin, redColor);
            CGColorRelease(redColor);
            
            CGContextAddPath(context, shadowRectPath.CGPath);
            CGContextFillPath(context);
        }
        CGContextRestoreGState(context);
        
        CGContextSaveGState(context);
        {   
            CGContextAddPath(context, fullRectPath.CGPath);
            CGContextClip(context);
            
            //Gradient
            CGFloat locations[2] = { 0.0, 1.0 };
            CGColorRef topColor = CGColorRetain([UIColor colorWithRed:0.87 green:0.87 blue:0.87 alpha:1.0].CGColor);
            CGColorRef bottomColor = CGColorRetain([UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0].CGColor);
            
            NSArray *colors = @[(__bridge id)topColor, (__bridge id)bottomColor];
            CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
            
            CGPoint startPoint = CGPointMake(CGRectGetWidth(rect)/2, 0.f);
            CGPoint endPoint = CGPointMake(CGRectGetWidth(rect)/2, CGRectGetHeight(rect));
            CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);
            
            CGColorRelease(topColor);
            CGColorRelease(bottomColor);
        }
        CGContextRestoreGState(context);
        
        //top line
        UIBezierPath *topLinePath = [UIBezierPath bezierPath];
        [topLinePath moveToPoint:CGPointMake(0.f, 1.f/scale)];
        [topLinePath addLineToPoint:CGPointMake(CGRectGetWidth(rect), 1.f/scale)];
        [topLinePath setLineWidth:1.f];
        [[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0] setStroke];
        [topLinePath stroke];
        
    }
    CGContextRestoreGState(context);
    
    [super drawRect:rect];
}

@end
