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

#import "SLColorArt.h"
#import "LEColorPicker.h"

static NSString * const kTOLDevAdsBaseURL = @"https://itunes.apple.com";
static NSString * const kTOLDevAdsLookupPath = @"lookup";
static CGFloat kTOLDevAdsRefreshInterval = 5.f;
static NSTimeInterval const kTOLDevAdsSecondsInDay = 86400;

/** keys for track metadata */
static NSString * const kTOLDevAdsAppKeyArtistName = @"artistName";
static NSString * const kTOLDevAdsAppKeyIconURL = @"artworkUrl100"; //options are 60, 100, 512
static NSString * const kTOLDevAdsAppKeyAverageRatingCurrentVersion = @"averageUserRatingForCurrentVersion";
static NSString * const kTOLDevAdsAppKeyBundleId = @"bundleId";
static NSString * const kTOLDevAdsAppKeyFormattedPrice = @"formattedPrice";
static NSString * const kTOLDevAdsAppKeyRatingCountForCurrentVersion = @"userRatingCountForCurrentVersion";
static NSString * const kTOLDevAdsAppKeyLinkURL = @"trackViewUrl";
static NSString * const kTOLDevAdsAppKeyName = @"trackName";
static NSString * const kTOLDevAdsAppKeyKind = @"kind";

static NSString * const kTOLDevAdsResponseKeyResults = @"results";
static NSString * const kTOLDevAdsWrapperKeyWrapperType = @"wrapperType";
static NSString * const kTOLDevAdsWrapperTypeValueArtist = @"artist";

static NSString * const kTOLDevAdsAppKindMacSoftware = @"mac-software";
static NSString * const kTOLDevAdsAppKindSoftware = @"software";

#define isGiraffeScreen ([[UIScreen mainScreen] bounds].size.height == 568.f)

@interface TOLDeveloperAds () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSTimer *adTimer;
@property (nonatomic, strong) NSArray *developerApps;
@property (nonatomic, copy) NSDictionary *developerMeta;
@property (nonatomic) NSInteger currentAdIndex;
@property (nonatomic, strong) NSDate *metadataTimestamp;
@property (nonatomic, strong) NSMutableIndexSet *adIndex;
@property (nonatomic, readwrite) BOOL adLoaded;
@property (nonatomic, getter = isAdLoading) BOOL adLoading;
@property (nonatomic, strong) UIImageView *frameImageView;

@end

@implementation TOLDeveloperAds

- (instancetype)init{
    self = [super init];
    if (self) {
        _adIndex = [NSMutableIndexSet indexSet];
    }
    return self;
}

#pragma mark - TOLDeveloperAds Specific Methods
- (void)requestNextAdBanner{
    if (self.isAdLoading == NO) {
        if ([self secondsFromDate:self.metadataTimestamp] > kTOLDevAdsSecondsInDay) {
            typeof(self) __weak weakSelf = self;
            //refresh metadata, load into ivars
            
            [self
             fetchDeveloperMetadataWithSuccess:^(void){
                 [weakSelf requestNextAdBanner];
             }
             failure:^(NSError *error){
                 TOLWLog(@"Error fetching dev metadata: %@", error);
                 typeof(weakSelf) blockSelf = weakSelf;
                 
                 blockSelf.adLoading = NO;
                 blockSelf.adLoaded = NO;
                 
                 [blockSelf.adManager adFailedForNetworkAdapterClass:blockSelf.class];
             }];
        }
        else if(self.developerApps.count > 0){
            self.adLoading = YES;
            
            NSInteger index = 0;
            if (self.developerApps.count > 1) {
                //Only transition if there is more than a single app - no need otherwise
                index = [self.adIndex firstIndex];
                
                if (index == NSNotFound) {
                    [self refreshAdIndex];
                    
                    index = [self.adIndex firstIndex];
                }
                
                [self loadInfoAtIndex:index completion:^{
                    CATransition *transition = [CATransition animation];
                    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                    transition.type = kCATransitionReveal;
                    transition.subtype = kCATransitionFromBottom;
                    
                    [self.bannerView.layer addAnimation:transition forKey:@"inventory-transition"];
                }];
            }
        }
        else{
            [self.adManager adFailedForNetworkAdapterClass:self.class];
        }
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

- (void)applyColorsFromSLColors:(SLColorArt *)colorArt toBannerView:(TOLDeveloperBannerView *)bannerView{
    bannerView.appIconImageView.image = colorArt.scaledImage;
    bannerView.backgroundColor = colorArt.primaryColor;
    
    bannerView.appNameLabel.textColor = colorArt.secondaryColor;
    bannerView.appNameLabel.shadowColor = colorArt.backgroundColor;
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    bannerView.appNameLabel.shadowOffset = CGSizeMake(0.f, -1.f/scale);
}

- (void)applyColorsFromLEColorsDictionary:(NSDictionary *)colorsPickedDictionary toBannerView:(TOLDeveloperBannerView *)bannerView{
    UIColor *backgroundColor = [colorsPickedDictionary objectForKey:@"BackgroundColor"];
    UIColor *primaryColor = [colorsPickedDictionary objectForKey:@"PrimaryTextColor"];
    UIColor *secondaryColor = [colorsPickedDictionary objectForKey:@"SecondaryTextColor"];
    
    bannerView.backgroundColor = backgroundColor;
    
    bannerView.appNameLabel.textColor = primaryColor;
    bannerView.appNameLabel.shadowColor = secondaryColor;
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    bannerView.appNameLabel.shadowOffset = CGSizeMake(0.f, -1.f/scale);
}

- (UIImage *)image:(UIImage *)image resizedToSize:(CGSize)newSize{
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGImageRef imageRef = CGImageRetain(image.CGImage);
    CGColorSpaceRef genericColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 newSize.width*scale,
                                                 newSize.height*scale,
                                                 8, (4 * newSize.width*scale),
                                                 genericColorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(genericColorSpace);
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextDrawImage(context, CGRectMake(0.f, 0.f, newSize.width*scale, newSize.height*scale), imageRef);
    CGImageRelease(imageRef);
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *newUIImage = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    
    return newUIImage;
}

#pragma mark - Frame
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
            if (isGiraffeScreen) {
                frame.size.width = kTOLDeveloperBannerViewPodWidthLandscapeGiraffe;
            }
            else{
                frame.size.width = kTOLDeveloperBannerViewPodWidthLandscape;
            }
        }
        else{
            frame.size.height = kTOLDeveloperBannerViewPodHeightPortrait;
            frame.size.width = kTOLDeveloperBannerViewPodWidthPortrait;
        }
    }
    
    return frame;
}

#pragma mark - Inventory
- (void)loadInfoAtIndex:(NSInteger)index completion:(void(^)(void))completionBlock{
    NSDictionary *adInfo = self.developerApps[index];
    
    [self.adIndex removeIndex:index];
    self.currentAdIndex = index;
    
    [self populateBannerWithInfo:adInfo completion:completionBlock];
}

- (void)populateBannerWithInfo:(NSDictionary *)adInfo completion:(void(^)(void))completionBlock{
    
    NSString *imageURLString = adInfo[kTOLDevAdsAppKeyIconURL];
    
    typeof(self) __weak weakSelf = self;

    [self
     fetchImageWithPath:imageURLString
     completion:^(UIImage *image) {
         dispatch_queue_t image_processing_queue = dispatch_queue_create("com.theonlylars.image-processing", 0);
         dispatch_set_target_queue(image_processing_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
         
         dispatch_async(image_processing_queue, ^{
             typeof(weakSelf) blockSelf = weakSelf;
             
             //             CGSize imageSize = blockSelf.bannerView.appIconImageView.bounds.size;
             
             //             SLColorArt *colorArt = [[SLColorArt alloc] initWithImage:image
             //                                                           scaledSize:imageSize];
             
             CGSize iconSize = blockSelf.bannerView.appIconImageView.bounds.size;
             UIImage *resizedImage = [self image:image resizedToSize:iconSize];
             
             [LEColorPicker
              pickColorFromImage:image
              onComplete:^(NSDictionary *colorsPickedDictionary) {
                  
                  blockSelf.bannerView.appNameLabel.text = adInfo[kTOLDevAdsAppKeyName];
                  blockSelf.bannerView.priceLabel.text = adInfo[kTOLDevAdsAppKeyFormattedPrice];
                  //                 [blockSelf applyColorsFromSLColors:colorArt toBannerView:blockSelf.bannerView];
                  CGSize iconSize = blockSelf.bannerView.appIconImageView.bounds.size;
                  blockSelf.bannerView.appIconImageView.image = resizedImage;
                  [blockSelf applyColorsFromLEColorsDictionary:colorsPickedDictionary toBannerView:blockSelf.bannerView];
                  
                  blockSelf.adLoaded = YES;
                  blockSelf.adLoading = NO;
                  
                  [blockSelf.adManager adSucceededForNetworkAdapterClass:blockSelf.class];
                  
                  if(completionBlock){
                      completionBlock();
                  }
              }];
         });
         
//         dispatch_release(image_processing_queue);
     } failBlock:^(NSError *error) {
         NSLog(@"Error fetching image: %@", error.localizedDescription);
         typeof(weakSelf) blockSelf = weakSelf;
         
         blockSelf.adLoading = NO;
         
         [blockSelf.adManager adFailedForNetworkAdapterClass:blockSelf.class];
     }];
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
    NSURL *baseURL = [NSURL URLWithString:kTOLDevAdsBaseURL];
    
    NSDictionary *params = @{
        @"id" : self.publisherId,
        @"entity":@"software",
        @"lang":languageCode,
        @"country": countryCode
    };
    
    NSString *paramsString = [self urlEncodedParamsForDictionary:params];
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kTOLDevAdsLookupPath, paramsString];
    NSURL *url = [NSURL URLWithString:urlString relativeToURL:baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
   
    NSMutableDictionary *headerFields = [request.allHTTPHeaderFields mutableCopy];
    
    if (headerFields == nil) {
        headerFields = [NSMutableDictionary dictionary];
    }
    
    [headerFields setObject:@"application/json" forKey:@"content-type"];
    
    [request setAllHTTPHeaderFields:headerFields];
    
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         if (error != nil){
             if(failBlock != nil) {
                 //Something bad happened during fetch - bail and report
                 failBlock(error);
             }
             return;
         }
         
         NSError *jsonReadingError = nil;
         NSDictionary *metadata = [NSJSONSerialization
                                   JSONObjectWithData:data
                                   options:NSJSONReadingAllowFragments
                                   error:&jsonReadingError];
         
         if ((jsonReadingError != nil)) {
             if ((failBlock != nil)) {
                 //something else bad happened during parse - bail and report
                 failBlock(jsonReadingError);
             }
             return;
         }
         
         NSArray *objects = metadata[kTOLDevAdsResponseKeyResults];
         NSMutableArray *apps = [NSMutableArray array];
         NSString *currentBundleID = [[NSBundle mainBundle] bundleIdentifier];
         
         //artist should be first, but just in case
         for (NSDictionary *object in objects) {
             NSString *objectBundleId = object[kTOLDevAdsAppKeyBundleId];
             NSString *objectKind = object[kTOLDevAdsAppKeyKind];
             NSString *wrapperType = object[kTOLDevAdsWrapperKeyWrapperType];
             
             BOOL isMacSoftware = [objectKind isEqualToString:kTOLDevAdsAppKindMacSoftware];
             BOOL isCurrentApp = [objectBundleId isEqualToString:currentBundleID];
             BOOL isArtist = [wrapperType isEqualToString:kTOLDevAdsWrapperTypeValueArtist];
             
             if (isArtist) {
                 self.developerMeta = object;
             }
             else if((isCurrentApp == NO) &&
                     (isMacSoftware == NO)){
                 [apps addObject:object];
             }
             else if(isMacSoftware){
                 NSLog(@"Skipping mac app with bundle ID %@", objectBundleId);
             }
         }
         
         NSAssert(self.developerMeta != nil, @"Artist data is still nil after fetch!");
         
         self.metadataTimestamp = [NSDate date];
         self.developerApps = apps;
         
         [self refreshAdIndex];
         
         if (successBlock) {
             successBlock();
         }
     }];
}

- (void)fetchImageWithPath:(NSString *)imagePath
                completion:(void(^)(UIImage *image))successBlock
                 failBlock:(void(^)(NSError *error))failBlock{
    NSURL *url = [NSURL URLWithString:imagePath];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    NSString *last = [imagePath lastPathComponent];
    last = [last componentsSeparatedByString:@"?"][0];
    NSString *fileExtension = [[last componentsSeparatedByString:@"."] lastObject];
    
    NSMutableDictionary *headerFields = [request.allHTTPHeaderFields mutableCopy];
    
    if (headerFields == nil) {
        headerFields = [NSMutableDictionary dictionary];
    }
    
    NSString *contentType = [NSString stringWithFormat:@"image/%@", fileExtension];
    [headerFields setObject:contentType forKey:@"content-type"];
    
    [request setAllHTTPHeaderFields:headerFields];
    
    NSOperationQueue *imageQueue = [[NSOperationQueue alloc] init];
    imageQueue.name = @"com.theonlylars.imagequeue";
    
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:imageQueue
     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
         
         if (error != nil) {
             if (failBlock != nil) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     failBlock(error);
                 });
             }
             return;
         }
         
         if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
             NSUInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
             NSRange successRange = NSMakeRange(200, 99);
             NSIndexSet *successSet = [NSIndexSet indexSetWithIndexesInRange:successRange];
             
             if ((error != nil) ||
                 ([successSet containsIndex:statusCode] == NO)) {
                 if (failBlock) {
                     if (error == nil) {
                         NSString *errorDescriptionString = [NSString stringWithFormat:@"Image fetch returned a non-successful status code (%i) for image path: %@", statusCode, response.URL.absoluteString];
                         NSDictionary *userInfo = @{
                             NSLocalizedDescriptionKey : errorDescriptionString
                         };
                         
                         error = [NSError errorWithDomain:@"com.theonlylars.DevAds"
                                                     code:statusCode
                                                 userInfo:userInfo];
                     }
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         failBlock(error);
                     });
                 }
                 return;
             }
             
             //should have a successful image fetch here
             UIImage *image = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
             
             if (successBlock) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     successBlock(image);
                 });
             }
         }
     }];
}

- (void)refreshAdIndex{
    [self.adIndex removeAllIndexes];
    [self.adIndex addIndexesInRange:NSMakeRange(0, self.developerApps.count)];
}

#pragma mark - HTTP Helpers
- (NSString *)urlEncodedParamsForDictionary:(NSDictionary *)params{
    NSMutableString *paramsString = [NSMutableString stringWithString:@"?"];
    NSArray *allKeys = [params allKeys];
    
    for (NSString *key in allKeys) {
        id value = [params objectForKey:key];
        NSString *newParam = [NSString stringWithFormat:@"%@=%@",key,value];
        [paramsString appendString:newParam];
        
        if (([allKeys indexOfObject:key] != allKeys.count-1)) {
            //not last key, append '&'
            [paramsString appendString:@"&"];
        }
    }
    
    return paramsString;
}

#pragma mark - Required TOLAdAdapter Methods
- (void)layoutBannerForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    self.bannerView.frame = [self frameForOrientation:interfaceOrientation];
    [self.bannerView setNeedsDisplay];
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
}

@end
