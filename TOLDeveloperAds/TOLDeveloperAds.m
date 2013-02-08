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
#import <NSHash/NSString+NSHash.h>
#import <Reachability/Reachability.h>

#import "SLColorArt.h"
#import "LEColorPicker.h"

static NSString * const kTOLDevAdsBaseURL = @"https://itunes.apple.com";
static NSString * const kTOLDevAdsLookupPath = @"lookup";
static CGFloat kTOLDevAdsRefreshInterval = 5.f;
static NSTimeInterval const kTOLDevAdsSecondsInDay = 86400;

/** keys for track metadata */
static NSString * const kTOLDevAdsAppKeyArtistName = @"artistName";
static NSString * const kTOLDevAdsAppKeyIconURL60 = @"artworkUrl60"; //options are 60, 100, 512
static NSString * const kTOLDevAdsAppKeyIconURL100 = @"artworkUrl100";
static NSString * const kTOLDevAdsAppKeyIconURL512 = @"artworkUrl512";
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

@interface TOLDevAdsCacheManager : NSObject

+ (NSString *)cacheDirectoryPath;
+ (NSString *)metadataPathForDevId:(NSString *)devId;
+ (NSDictionary *)cachedMetadataForDevId:(NSString *)devId;
+ (BOOL)cacheMetadata:(NSDictionary *)metadata forDevId:(NSString *)devId;
+ (UIImage *)cachedImageForImageURLPath:(NSString *)urlPath;
+ (BOOL)cacheImage:(UIImage *)image withPath:(NSString *)urlPath;
+ (BOOL)isImageCachedAtURLPath:(NSString *)urlPath;

@end

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
@property (nonatomic, strong) Reachability *reachability;

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
    bannerView.appIconImage = colorArt.scaledImage;
    bannerView.primaryColor = colorArt.primaryColor;
    
    bannerView.secondaryColor = colorArt.secondaryColor;
}

- (void)applyColorsFromLEColorsDictionary:(NSDictionary *)colorsPickedDictionary toBannerView:(TOLDeveloperBannerView *)bannerView{
    UIColor *backgroundColor = [colorsPickedDictionary objectForKey:@"BackgroundColor"];
    UIColor *primaryColor = [colorsPickedDictionary objectForKey:@"PrimaryTextColor"];
    UIColor *secondaryColor = [colorsPickedDictionary objectForKey:@"SecondaryTextColor"];
    
    bannerView.primaryColor = backgroundColor;
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

#pragma mark - Property Overrides
- (Reachability *)reachability{
    if (_reachability == nil) {
        _reachability = [Reachability reachabilityForInternetConnection];
        [_reachability startNotifier];
    }
    return _reachability;
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
    
    NSString *imageURLString = adInfo[kTOLDevAdsAppKeyIconURL60];
    NSString *imageURL100 = adInfo[kTOLDevAdsAppKeyIconURL100];
    NSString *imageURL512 = adInfo[kTOLDevAdsAppKeyIconURL512];
    
    if (self.reachability.isReachableViaWiFi == NO) {
        
        BOOL has512Image = [TOLDevAdsCacheManager isImageCachedAtURLPath:imageURL512];
        
        if (has512Image) {
            TOLLog(@"On WWAN, but have cached image, using larger cached image");
            imageURLString = imageURL512;
        }
        //revert to small images when possible on cell connections
        else if ([imageURL100 isEqualToString:imageURL512] == NO) {
            TOLLog(@"Using available 100x100 image on WWAN");
            imageURLString = imageURL100;
        }
        else{
            TOLLog(@"No 100x100 or cached 512x512 image - reverting to fetching smallest image");
        }
    }
    else{
        TOLLog(@"Reachable via Wifi - Using larger images");
        //we can use larger images on WiFi
        imageURLString = imageURL512;
    }
    
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
             
             CGSize iconSize = [blockSelf.bannerView iconImageSize];
             UIImage *resizedImage = [self image:image resizedToSize:iconSize];
             
             [LEColorPicker
              pickColorFromImage:image
              onComplete:^(NSDictionary *colorsPickedDictionary) {
                  
                  blockSelf.bannerView.appName = adInfo[kTOLDevAdsAppKeyName];
                  blockSelf.bannerView.price = adInfo[kTOLDevAdsAppKeyFormattedPrice];
                  blockSelf.bannerView.percentage = [adInfo[kTOLDevAdsAppKeyAverageRatingCurrentVersion] floatValue]/5.f;
                  //                 [blockSelf applyColorsFromSLColors:colorArt toBannerView:blockSelf.bannerView];
                  
                  blockSelf.bannerView.appIconImage = resizedImage;
                  [blockSelf applyColorsFromLEColorsDictionary:colorsPickedDictionary toBannerView:blockSelf.bannerView];
                  
                  blockSelf.adLoaded = YES;
                  blockSelf.adLoading = NO;
                  
                  [blockSelf.adManager adSucceededForNetworkAdapterClass:blockSelf.class];
                  
                  [blockSelf.bannerView setNeedsDisplay];
                  
                  if(completionBlock){
                      completionBlock();
                  }
              }];
         });
         
//         dispatch_release(image_processing_queue);
     } failBlock:^(NSError *error) {
         TOLWLog(@"Error fetching image: %@", error.localizedDescription);
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
    
    NSDictionary *cachedMetadata = [TOLDevAdsCacheManager cachedMetadataForDevId:self.publisherId];
    if (cachedMetadata != nil) {
        [self populateAppListFromMetadata:cachedMetadata];
        
        if (successBlock) {
            successBlock();
        }
    }
    else{
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
             
             [TOLDevAdsCacheManager cacheMetadata:metadata forDevId:self.publisherId];
             
             [self populateAppListFromMetadata:metadata];
             
             if (successBlock) {
                 successBlock();
             }
         }];
    }
}

- (void)populateAppListFromMetadata:(NSDictionary *)metadata{
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
            TOLWLog(@"Skipping mac app with bundle ID %@", objectBundleId);
        }
    }
    
    NSAssert(self.developerMeta != nil, @"Artist data is still nil after fetch!");
    
    self.metadataTimestamp = [NSDate date];
    self.developerApps = apps;
    
    [self refreshAdIndex];
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
    
    UIImage *cachedImage = [TOLDevAdsCacheManager cachedImageForImageURLPath:imagePath];
    
    if ((cachedImage != nil) &&
        (successBlock != nil)) {
        successBlock(cachedImage);
    }
    else{
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
                 
                 [TOLDevAdsCacheManager cacheImage:image withPath:imagePath];
                 
                 if (successBlock) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         successBlock(image);
                     });
                 }
             }
         }];
    }
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
    self.bannerView.orientation = interfaceOrientation;
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

#pragma mark - Cache Manager

NSString * const kTOLDevAdsMetadataCacheDateKey = @"com.theonlylars.metadataCacheDate";

@implementation TOLDevAdsCacheManager

+ (NSString *)cacheDirectoryPath{
    NSString *systemCachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *cachesPath = [systemCachePath stringByAppendingPathComponent:@"com.theonlylars.dev-ads"];
    
    BOOL pathIsDirectory;
    if([[NSFileManager defaultManager] fileExistsAtPath:cachesPath isDirectory:&pathIsDirectory]){
        if (pathIsDirectory) {
            return cachesPath;
        }
    }
    else if([[NSFileManager defaultManager] createDirectoryAtPath:cachesPath withIntermediateDirectories:YES attributes:nil error:nil]){
        //directory created
        return cachesPath;
    }
    
    return nil;
}

+ (NSString *)metadataPathForDevId:(NSString *)devId{
    NSString *cacheDirectory = [self cacheDirectoryPath];
    NSString *plistName = [NSString stringWithFormat:@"%@.plist", devId];
    NSString *metadataPath = [cacheDirectory stringByAppendingPathComponent:plistName];
    
    return metadataPath;
}

+ (NSDictionary *)cachedMetadataForDevId:(NSString *)devId{
    
    NSString *metadataPath = [self metadataPathForDevId:devId];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:metadataPath]) {
        NSDictionary *cachedMetadata = [NSDictionary dictionaryWithContentsOfFile:metadataPath];
        NSDate *cacheDate = cachedMetadata[kTOLDevAdsMetadataCacheDateKey];
        if ([cacheDate timeIntervalSinceNow] > -kTOLDevAdsSecondsInDay) {
            return cachedMetadata;
        }
    }
    
    return nil;
}

+ (BOOL)cacheMetadata:(NSDictionary *)metadata forDevId:(NSString *)devId{
    NSMutableDictionary *mutableMetadata = [metadata mutableCopy];
    mutableMetadata[kTOLDevAdsMetadataCacheDateKey] = [NSDate date];
    
    NSString *metadataPath = [self metadataPathForDevId:devId];
    
    return [mutableMetadata writeToFile:metadataPath atomically:YES];
}

+ (NSString *)imagePathForImageWithURLPath:(NSString *)urlPath{
    NSString *cachesDirectoryPath = [self cacheDirectoryPath];
    
    NSString *cachedImageName = [[urlPath MD5] stringByAppendingPathExtension:@"png"];
    NSString *fullImagePath = [cachesDirectoryPath stringByAppendingPathComponent:cachedImageName];
    
    return fullImagePath;
}

+ (UIImage *)cachedImageForImageURLPath:(NSString *)urlPath{
    NSString *fullImagePath = [self imagePathForImageWithURLPath:urlPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:fullImagePath]) {
        UIImage *cachedImage = [UIImage imageWithContentsOfFile:fullImagePath];
        return cachedImage;
    }
    
    return nil;
}

+ (BOOL)isImageCachedAtURLPath:(NSString *)urlPath{
    NSString *fullImagePath = [self imagePathForImageWithURLPath:urlPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    return [fileManager fileExistsAtPath:fullImagePath];
}

+ (BOOL)cacheImage:(UIImage *)image withPath:(NSString *)urlPath{
    NSString *imagePath = [self imagePathForImageWithURLPath:urlPath];
    
    NSData *imageData = UIImagePNGRepresentation(image);
    
    return [imageData writeToFile:imagePath atomically:YES];
}

@end
