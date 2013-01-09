//
//  TOLDeveloperAds.m
//  DeveloperAdsDemo
//
//  Created by Lars Anderson on 1/8/13.
//  Copyright (c) 2013 Lars Anderson. All rights reserved.
//

#import "TOLDeveloperAds.h"
#import "AFNetworking.h"

static NSString * const kTOLDevAdsBaseURL = @"https://itunes.apple.com";
static NSString * const kTOLDevAdsLookupPath = @"lookup";
static CGFloat kTOLDevAdsRefreshInterval = 30.f;

/** keys for track metadata */
static NSString * const kTOLDevAdsAppKeyArtistName = @"artistName";
static NSString * const kTOLDevAdsAppKeyIconURL = @"artworkUrl100";
static NSString * const kTOLDevAdsAppKeyAverageRatingCurrentVersion = @"averageUserRatingForCurrentVersion";
static NSString * const kTOLDevAdsAppKeyBundleId = @"bundleId";
static NSString * const kTOLDevAdsAppKeyFormattedPrice = @"formattedPrice";
static NSString * const kTOLDevAdsAppKeyRatingCountForCurrentVersion = @"userRatingCountForCurrentVersion";
static NSString * const kTOLDevAdsAppKeyLinkURL = @"trackViewUrl";


@interface TOLDeveloperAds ()

@property (strong, nonatomic) NSTimer *adTimer;
@property (strong, nonatomic) AFHTTPClient *httpClient;
@property (strong, nonatomic) NSArray *developerApps;
@property (copy, nonatomic) NSDictionary *developerMeta;
@property (nonatomic) NSInteger currentAppDisplayed;
@property (strong, nonatomic) NSDate *metadataTimestamp;

@end

@implementation TOLDeveloperAds

- (instancetype)init{
    self = [super init];
    if (self) {
        NSURL *baseURL = [NSURL URLWithString:kTOLDevAdsBaseURL];
        
        _httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
        [_httpClient setDefaultHeader:@"Content Type" value:@"application/json"];
        [_httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
    }
    return self;
}

#pragma mark - TOLDeveloperAds Specific Methods
- (void)requestNextAdBanner{
    [self fetchDeveloperMetadataWithSuccess:nil failure:nil];
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
- (void)fetchDeveloperMetadataWithSuccess:(void(^)(NSDictionary *meta))successBlock
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
             if ([object[@"wrapperType"] isEqualToString:@"artist"]) {
                 self.developerMeta = object;
             }
             else{
                 [apps addObject:object];
             }
         }
         
         NSAssert(self.developerMeta != nil, @"Artist data is still nil after fetch!");
         
         self.developerApps = apps;
     
         self.metadataTimestamp = [NSDate date];
     
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"error: %@", error.localizedDescription);
     }];
}

- (NSDictionary *)developerAppsFromDictionary:(NSDictionary *)allAppObjects{
    
}

#pragma mark - Required Methods
- (void)layoutBannerForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    //TODO: layout banner view
}

#pragma mark - Optional Methods
- (void)startAdRequests{
    if (self.adTimer == nil) {
        self.adTimer = [NSTimer timerWithTimeInterval:kTOLDevAdsRefreshInterval
                                               target:self
                                             selector:@selector(requestNextAdBanner)
                                             userInfo:nil
                                              repeats:YES];
        
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
}

@end
