//
//  WVSSAddress.h
//  WebViewScreenSaver
//
//  Created by Alastair Tse on 26/04/2015.
//
//  Copyright 2015 Alastair Tse.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

extern NSString *const kWVSSAddressURLKey;
extern NSString *const kWVSSAddressTimeKey;

// Shortest time a page is shown before moving on. Stops a duration of 0 (a typo or a
// bad remote list) from reloading pages in a tight loop.
extern NSTimeInterval const kWVSSMinimumDuration;

@interface WVSSAddress : NSObject
@property(nonatomic, strong) NSString *url;
@property(nonatomic, assign) NSInteger duration;

+ (NSString *)defaultAddressURL;
+ (NSInteger)defaultDuration;

+ (WVSSAddress *)addressWithURL:(NSString *)url duration:(NSInteger)duration;
+ (WVSSAddress *)defaultAddress;

- (NSDictionary *)dictionaryRepresentation;

// Seconds to show this address: a negative duration means forever (returns -1),
// anything else is at least kWVSSMinimumDuration.
- (NSTimeInterval)effectiveDuration;

@end
