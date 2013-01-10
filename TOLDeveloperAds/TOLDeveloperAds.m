//
//  TOLDeveloperAds.m
//  DeveloperAdsDemo
//
//  Created by Lars Anderson on 1/8/13.
//  Copyright (c) 2013 Lars Anderson. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TOLDeveloperAds.h"
#import "LARSAdController.h"

#import "AFNetworking.h"

static NSString * const kTOLDevAdsBaseURL = @"https://itunes.apple.com";
static NSString * const kTOLDevAdsLookupPath = @"lookup";
static CGFloat kTOLDevAdsRefreshInterval = 5.f;
static NSTimeInterval const kTOLDevAdsSecondsInDay = 86400;

/** keys for track metadata */
static NSString * const kTOLDevAdsAppKeyArtistName = @"artistName";
static NSString * const kTOLDevAdsAppKeyIconURL = @"artworkUrl100";
static NSString * const kTOLDevAdsAppKeyAverageRatingCurrentVersion = @"averageUserRatingForCurrentVersion";
static NSString * const kTOLDevAdsAppKeyBundleId = @"bundleId";
static NSString * const kTOLDevAdsAppKeyFormattedPrice = @"formattedPrice";
static NSString * const kTOLDevAdsAppKeyRatingCountForCurrentVersion = @"userRatingCountForCurrentVersion";
static NSString * const kTOLDevAdsAppKeyLinkURL = @"trackViewUrl";
static NSString * const kTOLDevAdsAppKeyName = @"trackName";

@interface TOLDeveloperAds ()

@property (nonatomic, strong) NSTimer *adTimer;
@property (nonatomic, strong) AFHTTPClient *httpClient;
@property (nonatomic, strong) NSArray *developerApps;
@property (nonatomic, copy) NSDictionary *developerMeta;
@property (nonatomic) NSInteger currentAdIndex;
@property (nonatomic, strong) NSDate *metadataTimestamp;
@property (nonatomic, strong) NSMutableIndexSet *adIndex;
@property (nonatomic, readwrite) BOOL adLoaded;

@end

@implementation TOLDeveloperAds

- (instancetype)init{
    self = [super init];
    if (self) {
        NSURL *baseURL = [NSURL URLWithString:kTOLDevAdsBaseURL];
        
        _httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
        [_httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        
        _adIndex = [NSMutableIndexSet indexSet];
    }
    return self;
}

#pragma mark - TOLDeveloperAds Specific Methods
- (void)requestNextAdBanner{
    if ([self secondsFromDate:self.metadataTimestamp] > kTOLDevAdsSecondsInDay) {
        typeof(self) __weak weakSelf = self;
        
        //refresh metadata, load into ivars
        [self
         fetchDeveloperMetadataWithSuccess:^(void){
             [weakSelf requestNextAdBanner];
         }
         failure:^(NSError *error){
             TOLWLog(@"Error fetching dev metadata: %@", error);
             typeof(self) blockSelf = self;
             
             blockSelf.adLoaded = NO;
             [blockSelf.adManager adFailedForNetworkAdapterClass:self.class];
         }];
    }
    else if(self.developerApps.count > 0){
        
        NSInteger index = 0;
        if (self.developerApps.count > 1) {
            //Only transition if there is more than a single app - no need otherwise
            index = [self.adIndex firstIndex];
            
            if (index == NSNotFound) {
                [self refreshAdIndex];
                
                index = [self.adIndex firstIndex];
            }
            
            if (self.adLoaded) {
                CATransition *transition = [CATransition animation];
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                transition.type = kCATransitionReveal;
                transition.subtype = kCATransitionFromBottom;
                
                [self.bannerView.layer addAnimation:transition forKey:@"inventory-transition"];
            }
        }
    
        [self loadInfoAtIndex:index];
        [self.adManager adSucceededForNetworkAdapterClass:self.class];
    }
    else{
        [self.adManager adFailedForNetworkAdapterClass:self.class];
    }
}

#pragma mark - Helpers
- (NSTimeInterval)secondsFromDate:(NSDate *)date{
    if (date == nil) {
        return NSTimeIntervalSince1970;
    }
    
    NSInteger seconds = [[NSDate date] timeIntervalSinceDate:date];
    
    return seconds;
}

- (NSInteger)randomNumberLessThan:(NSInteger)lessThan{
    return arc4random_uniform(lessThan);
}

- (CGRect)frameForCurrentOrientation{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    return [self frameForOrientation:orientation];
}

- (CGRect)frameForOrientation:(UIInterfaceOrientation)orientation{
    CGRect frame;
    frame.origin = CGPointZero;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //ipad sized
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            frame.size.height = kTOLDeveloperBannerViewPadHeightLandscape;
            frame.size.width = kTOLDeveloperBannerViewPadWidthLandscape;
        }
        else{
            frame.size.height = kTOLDeveloperBannerViewPadHeightPortrait;
            frame.size.width = kTOLDeveloperBannerViewPadWidthPortrait;
        }
    }
    else{
        //ipod sized
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            frame.size.height = kTOLDeveloperBannerViewPodHeightLandscape;
            frame.size.width = kTOLDeveloperBannerViewPodWidthLandscape;
        }
        else{
            frame.size.height = kTOLDeveloperBannerViewPodHeightPortrait;
            frame.size.width = kTOLDeveloperBannerViewPodWidthPortrait;
        }
    }
    
    return frame;
}

#pragma mark - Inventory
- (void)loadInfoAtIndex:(NSInteger)index{
    NSDictionary *adInfo = self.developerApps[index];
    
    [self.adIndex removeIndex:index];
    self.currentAdIndex = index;
    
    [self populateDevBannerWithInfo:adInfo];
    self.adLoaded = YES;
}

- (void)populateDevBannerWithInfo:(NSDictionary *)adInfo{
    
    //TODO: make this block on image downloading (don't say ad is successfully loaded until image comes back)
    NSString *imageURLString = adInfo[kTOLDevAdsAppKeyIconURL];
    NSURL *imageURL = [NSURL URLWithString:imageURLString];
    
    [self.bannerView.appIconImageView setImageWithURL:imageURL];
    self.bannerView.appNameLabel.text = adInfo[kTOLDevAdsAppKeyName];
}

/**
 http://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html
 
 My developer id: 379660208
 https://itunes.apple.com/lookup?id=379660208
 
 Look up all of Yelp's apps:
 https://itunes.apple.com/lookup?id=284910353&entity=software
 
 Look up all of my apps:
 https://itunes.apple.com/lookup?id=379660208&entity=software
 
 Electronic Arts: 284800461
 
 http://itunes.apple.com/linkmaker/
 
 Electronic Arts in Germany, in German
 https://itunes.apple.com/lookup?id=284800461&country=de&lang=de&output=json&entity=software
 
 */
- (void)fetchDeveloperMetadataWithSuccess:(void(^)(void))successBlock
                                  failure:(void(^)(NSError *error))failBlock{
    
    NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    NSString *languageCode = [currentLocale objectForKey:NSLocaleLanguageCode];
    
    NSDictionary *params = @{
        @"id" : self.publisherId,
        @"entity":@"software",
        @"lang":languageCode,
        @"country": countryCode
    };
    
    [self.httpClient
     getPath:kTOLDevAdsLookupPath
     parameters:params
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
         NSError *error = nil;
         NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
         
         NSArray *objects = data[@"results"];
         NSMutableArray *apps = [NSMutableArray array];
         
         //artist should be first, but just in case
         for (NSDictionary *object in objects) {
             NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
             
             if ([object[@"wrapperType"] isEqualToString:@"artist"]) {
                 self.developerMeta = object;
             }
             else if([object[kTOLDevAdsAppKeyBundleId] isEqualToString:bundleIdentifier] == NO){
                 [apps addObject:object];
             }
         }
         
         NSAssert(self.developerMeta != nil, @"Artist data is still nil after fetch!");
         
         self.metadataTimestamp = [NSDate date];
         self.developerApps = apps;
         
         [self refreshAdIndex];
         
         if (successBlock) {
             successBlock();
         }
     
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if (failBlock) {
             failBlock(error);
         }
     }];
}

- (void)refreshAdIndex{
    [self.adIndex removeAllIndexes];
    [self.adIndex addIndexesInRange:NSMakeRange(0, self.developerApps.count)];
}

#pragma mark - Required TOLAdAdapter Methods
- (void)layoutBannerForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    self.bannerView.frame = [self frameForOrientation:interfaceOrientation];
}

- (TOLDeveloperBannerView *)bannerView{
    if (_bannerView == nil) {
        CGRect frame = [self frameForCurrentOrientation];
        _bannerView = [[TOLDeveloperBannerView alloc] initWithFrame:frame];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bannerTapped:)];
        [_bannerView addGestureRecognizer:tapGesture];
    }
    
    return _bannerView;
}

#pragma mark - Touch Handling
- (void)bannerTapped:(UITapGestureRecognizer *)tapGesture{
    NSString *destinationURLString = self.developerApps[self.currentAdIndex][kTOLDevAdsAppKeyLinkURL];
    destinationURLString = [destinationURLString componentsSeparatedByString:@"?"][0];
    
    NSURL *destinationURL = [NSURL URLWithString:destinationURLString];
    
    [[UIApplication sharedApplication] openURL:destinationURL];
}

#pragma mark - Optional Methods
- (void)startAdRequests{
    if (self.adTimer == nil) {
        self.adTimer = [NSTimer scheduledTimerWithTimeInterval:kTOLDevAdsRefreshInterval
                                                        target:self
                                                      selector:@selector(requestNextAdBanner)
                                                      userInfo:nil
                                                       repeats:YES];
        
        //Immediately start a new request
        [self requestNextAdBanner];
    }
    
    [[NSRunLoop currentRunLoop] addTimer:self.adTimer forMode:NSDefaultRunLoopMode];
}

- (void)pauseAdRequests{
    [self.adTimer invalidate];
}

+ (BOOL)requiresPublisherId{
    return YES;
}

- (NSString *)friendlyNetworkDescription{
    return @"Developer Ads";
}

- (void)dealloc{
    [self.adTimer invalidate];
    self.adTimer = nil;
    
    _bannerView = nil;
    self.developerApps = nil;
    [self.adIndex removeAllIndexes], self.adIndex = nil;
    self.developerMeta = nil;
    self.metadataTimestamp = nil;
    self.httpClient = nil;
}

@end
