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
@property (nonatomic, strong) UIImageView *priceTagImageView;

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
        _appNameLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.f];
        
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
        
        UIImage *priceImage = [UIImage imageNamed:@"pricetag"];
        CGSize priceTagImageSize = priceImage.size;
        self.priceTagImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(frame)-priceTagImageSize.width,
                                                                               0.f,
                                                                               priceTagImageSize.width,
                                                                               priceTagImageSize.height)];
        self.priceTagImageView.image = priceImage;
        self.priceTagImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        [self addSubview:_appIconImageView];
        [self addSubview:_appNameLabel];
        [self addSubview:self.bannerFrame];
        [self addSubview:self.priceTagImageView];
        
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
    
    CGFloat margin = 4.f;
    CGFloat iconHeight = CGRectGetHeight(frame)-margin*2;
    CGRect iconFrame = CGRectMake(margin,
                                  margin,
                                  iconHeight,
                                  iconHeight);
    self.appIconImageView.frame = iconFrame;
    
    CGFloat appNameHeight = CGRectGetHeight(frame)/3;
    CGRect appNameFrame = CGRectMake(CGRectGetMaxX(iconFrame) + 10.f,
                                     margin*2,
                                     CGRectGetWidth(frame)-CGRectGetMaxX(iconFrame)-20.f,
                                     appNameHeight);
    self.appNameLabel.layer.borderColor = [UIColor redColor].CGColor;
    self.appNameLabel.layer.borderWidth = 1.f;
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
        CGFloat margin = 4.f;
        CGFloat cornerRadius = CGRectGetHeight(rect)/8.f;
        
        //icon cutout
        CGFloat iconDimension = CGRectGetHeight(rect)-margin*2;
        CGRect iconRect = CGRectMake(margin, margin, iconDimension, iconDimension);
        CGFloat contentXOrigin = CGRectGetWidth(iconRect)+margin*2;
        CGRect contentRect = CGRectMake(contentXOrigin,
                                        margin,
                                        CGRectGetWidth(rect)-CGRectGetWidth(iconRect)-3*margin,
                                        CGRectGetHeight(rect)-margin*2);
        
        UIBezierPath *iconCutout = [[UIBezierPath bezierPathWithRoundedRect:iconRect cornerRadius:cornerRadius] bezierPathByReversingPath];
        UIBezierPath *contentCutout = [[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:cornerRadius] bezierPathByReversingPath];
        UIBezierPath *fullRectPath = [UIBezierPath bezierPathWithRect:rect];
        [fullRectPath appendPath:contentCutout];
        [fullRectPath appendPath:iconCutout];
        
        CGContextSaveGState(context);
        {
//            CGRect shadowContentRect = CGRectMake(contentXOrigin-2.f,
//                                                  0.f,
//                                                  CGRectGetWidth(rect)-contentXOrigin,
//                                                  CGRectGetHeight(rect));
//            
//            //bounds shadow to content region
//            UIBezierPath *clippingPath = [UIBezierPath bezierPathWithRect:contentRect];
//            CGContextAddPath(context, clippingPath.CGPath);
//            CGContextClip(context);
//            
//            
//            UIBezierPath *shadowContentCutoutPath = [[UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:margin*2] bezierPathByReversingPath];
//            
//            //creates path that will create shadow
//            UIBezierPath *shadowRectPath = [UIBezierPath bezierPathWithRect:shadowContentRect];
//            [shadowRectPath appendPath:shadowContentCutoutPath];
            
            [[UIColor whiteColor] setFill];
            
            CGColorRef redColor = CGColorRetain([UIColor colorWithWhite:0.f alpha:0.25f].CGColor);
            CGContextSetShadowWithColor(context, CGSizeMake(0.f, 1.f), 5.f, redColor);
            CGColorRelease(redColor);
            
            CGContextAddPath(context, fullRectPath.CGPath);
            CGContextFillPath(context);
        }
        CGContextRestoreGState(context);
        
        CGContextAddPath(context, fullRectPath.CGPath);
        CGContextClip(context);
        
        [self drawGradientInContext:context inRect:rect];
        
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

- (void)drawGradientInContext:(CGContextRef)context inRect:(CGRect)rect{
    
    CGContextSaveGState(context);
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
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
}

@end
