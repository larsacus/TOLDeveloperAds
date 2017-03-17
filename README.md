# TOLDeveloperAds
===============

Easily create free, beautiful in-app banners for all of your other App Store apps with a single line of code:

``` objective-c
[[LARSAdController sharedManager] registerAdClass:[TOLDeveloperAds class] withPublisherId:@"284800461"];
```

Where the "publisher ID" is your developer id number given to you by Apple. You can find this number by going to [Apple's iTunes linkmaker](http://itunes.apple.com/linkmaker/) and searching for your developer name. When you find yourself in the "Artists" section, click "Artist Link" under your name. Your dev id should be in the link in the following format:

`https://itunes.apple.com/us/artist/tapbots/idXXXXXXXXX?uo=4`

All you need is the number denoted by X's above.

All App Store data about your apps will be downloaded and used on-the-fly to generate banners for your other ads.

This is generally what it will look like in portrait mode (thanks to [Eric Celedonia](http://dribbble.com/killerwalls) for the initial design):

![](Demo/devad.png)

# Development
**This project is very much in development and should not be used for production... yet.** If you are interested in using this in production or extending this to use for production, feel free to help out. Check the [issues](http://github.com/larsacus/TOLDeveloperAds/issues) for planned features not yet implemented or bugs being tracked.

If you don't/can't contribute to the project, feel free to submit an issue on features you would like to see or use-cases that may not currently be considered.

Check out the `Demo/` folder for the project being used for development, which should include all pods necessary.

# Dependencies
TOLDeveloperAds is depended by [LARSAdController](http://larsacus.github.com/LARSAdController). The easiest way to manage this dependency is by using Cocoapods:

``` ruby
pod 'LARSAdController/Core', '~>3.0'
```

The other following dependencies are *currently* required (but may not be when development stabilizes for release):

``` ruby
pod 'LEColorPicker', '~>1.0'
pod 'NSHash', '~>1.0'
pod 'Reachability', '~>3.1'
```

TOLDeveloperAds requires iOS 5.0+

# Features
Features of TOLDeveloperAds include:

1. Beautiful enough to include in even your *non* ad-enabled apps, maybe in a settings screen or on your "about" section
2. Free ads for all of your other apps
3. Link directly in-app StoreKit view controller, fallback to web link on tap
4. Customizable ad view by conforming your banner to `TOLDeveloperBannerProtocol` if you don't like the provided banner
5. Intelligent image caching and image downloading depending on connection to reduce user bandwidth
6. Auto-exclusion of current app running to not waste banner time
7. Auto-exclusion of mac apps
7. Leverages all the great features of [LARSAdController](http://larsacus.github.com/LARSAdController) to integrate your existing ads if you have them. Never have unfilled ad inventory again.

# MIT License
Copyright (c) 2014 Lars Anderson, theonlylars

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/larsacus/toldeveloperads/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

