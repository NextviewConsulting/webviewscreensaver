//
//  WVSSConfig.h
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

@class WVSSAddress;

@interface WVSSConfig : NSObject

// The user's own list, edited in the settings sheet and saved to user defaults.
@property(nonatomic, strong, readonly) NSMutableArray *addresses;
// The last list downloaded from addressListURL. Never saved over `addresses`.
@property(nonatomic, copy, readonly) NSArray *fetchedAddresses;
// YES while an address list download is in progress.
@property(nonatomic, assign, readonly, getter=isFetching) BOOL fetching;
@property(nonatomic, strong) NSString *addressListURL;
@property(nonatomic, assign) BOOL shouldFetchAddressList;
// Keep cookies/logins between runs. Off by default; set via `defaults` (see README).
@property(nonatomic, assign) BOOL persistWebsiteData;

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;
- (void)synchronize;
- (void)fetchIfNeeded;

// The list the screensaver should show: the fetched list when fetching is on and a
// list has arrived, otherwise the user's own list.
- (NSArray *)activeAddresses;

@end
