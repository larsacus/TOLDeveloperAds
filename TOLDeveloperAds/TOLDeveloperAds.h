//
//  TOLDeveloperAds.h
//  DeveloperAdsDemo
//
//  Created by Lars Anderson on 1/8/13.
//  Copyright (c) 2013 Lars Anderson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TOLAdAdapter.h"
#import "TOLDeveloperBannerView.h"

@interface TOLDeveloperAds : NSObject <TOLAdAdapter>

@property (strong, nonatomic) TOLDeveloperBannerView *bannerView;
@property (nonatomic) BOOL adVisible;
@property (weak, nonatomic) id <LARSAdControllerDelegate> adManager;
@property (copy, nonatomic) NSString *publisherId;
@property (nonatomic, readonly) BOOL adLoaded;

- (void)layoutBannerForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

+ (BOOL)requiresPublisherId;
- (void)startAdRequests;
- (void)pauseAdRequests;
- (NSString *)friendlyNetworkDescription;


@end
