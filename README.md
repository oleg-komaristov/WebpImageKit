# WebpImageKit

[![Version](https://img.shields.io/cocoapods/v/WebpImageKit.svg?style=flat)](https://cocoapods.org/pods/WebpImageKit)
[![License](https://img.shields.io/cocoapods/l/WebpImageKit.svg?style=flat)](https://cocoapods.org/pods/WebpImageKit)
[![Platform](https://img.shields.io/cocoapods/p/WebpImageKit.svg?style=flat)](https://cocoapods.org/pods/WebpImageKit)

## Example

### UIImage from NSData

```obj-c
#import <WebpImageKit/WebpImageKit.h>

NSData *data = [NSData dataWithContentsOfFile:@"image.webp"];
UIImage *image = [UIImage webpAnyImageWithData:data];
```

### UIImage to NSData

```obj-c
#import <WebpImageKit/WebpImageKit.h>

UIImage *image = [UIImage imageNamed:@"TestImage"];
WIKEncoderConfigBuilder *builder = [WIKEncoderConfigBuilder builderWithImageQuality:0.6];
NSData *data = [image webpDataWithConfig:[builder construct]];
```

## Requirements

iOS 12 or later.

## Installation

WebpImageKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'WebpImageKit'
```

## Author

Oleg Komaristov

## License

WebpImageKit is available under the MIT license. See the LICENSE file for more info.
