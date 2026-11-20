//
//  WVSSConfig.m
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

#import "WVSSConfig.h"
#import "WVSSAddress.h"
#import "WVSSAddressListFetcher.h"
#import "WVSSLog.h"

// ScreenSaverDefault Keys
static NSString *const kScreenSaverFetchURLsKey = @"kScreenSaverFetchURLs";  // BOOL
static NSString *const kScreenSaverURLsURLKey = @"kScreenSaverURLsURL";      // NSString (URL)
static NSString *const kScreenSaverURLListKey = @"kScreenSaverURLList";  // NSArray of NSDictionary
static NSString *const kScreenSaverPersistWebsiteDataKey =
    @"kScreenSaverPersistWebsiteData";  // BOOL, default NO

@interface WVSSConfig () <WVSSAddressListFetcherDelegate>
@property(nonatomic, strong) NSUserDefaults *userDefaults;
@property(nonatomic, strong) NSMutableArray *addresses;
@end

@implementation WVSSConfig {
  WVSSAddressListFetcher *_fetcher;
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
  self = [super init];
  if (self) {
    self.userDefaults = userDefaults;

    self.addresses = [self loadAddressesFromUserDefaults:userDefaults];
    self.addressListURL = [userDefaults stringForKey:kScreenSaverURLsURLKey];
    self.shouldFetchAddressList = [userDefaults boolForKey:kScreenSaverFetchURLsKey];
    self.persistWebsiteData = [userDefaults boolForKey:kScreenSaverPersistWebsiteDataKey];

    // NSLog(@"Loaded Addresses: %@", self.addresses);

    if (!self.addresses) {
      self.addresses = [NSMutableArray array];
    }
    
    [self appendSampleAddressIfEmpty];
    [self fetchIfNeeded];
  }
  return self;
}

- (void)appendSampleAddressIfEmpty {
  if (self.shouldFetchAddressList) return;

  if (!self.addresses.count) {
    [self.addresses addObject:[WVSSAddress defaultAddress]];
  }
}

- (NSMutableArray *)loadAddressesFromUserDefaults:(NSUserDefaults *)userDefaults {
  NSArray *addressesFromUserDefaults =
      [[userDefaults arrayForKey:kScreenSaverURLListKey] mutableCopy];
  NSMutableArray *addresses = [NSMutableArray array];
  for (NSDictionary *addressDictionary in addressesFromUserDefaults) {
    NSString *url = addressDictionary[kWVSSAddressURLKey];
    NSInteger time = [addressDictionary[kWVSSAddressTimeKey] integerValue];
    if (url) {
      WVSSAddress *address = [WVSSAddress addressWithURL:url duration:time];
      [addresses addObject:address];
    }
  }
  return addresses;
}

- (void)saveAddressesToUserDefaults:(NSUserDefaults *)userDefaults {
  NSMutableArray *addressesForUserDefaults = [NSMutableArray array];
  for (WVSSAddress *address in self.addresses) {
    [addressesForUserDefaults addObject:[address dictionaryRepresentation]];
  }
  // NSLog(@"Saved Addresses: %@", addressesForUserDefaults);

  [userDefaults setObject:addressesForUserDefaults forKey:kScreenSaverURLListKey];
}

- (void)synchronize {
  [self saveAddressesToUserDefaults:self.userDefaults];
  [self.userDefaults setBool:self.shouldFetchAddressList forKey:kScreenSaverFetchURLsKey];

  if (self.addressListURL.length) {
    [self.userDefaults setObject:self.addressListURL forKey:kScreenSaverURLsURLKey];
  } else {
    [self.userDefaults removeObjectForKey:kScreenSaverURLsURLKey];
  }
  [self.userDefaults synchronize];
}

- (void)addAddressWithURL:(NSString *)url duration:(NSInteger)duration {
  WVSSAddress *address = [WVSSAddress addressWithURL:url duration:duration];
  [self.addresses addObject:address];
}

- (void)fetchIfNeeded {
  if (!self.shouldFetchAddressList) return;

  NSString *addressFetchURL = self.addressListURL;
  if (!addressFetchURL.length) return;

  // Only fetch the list over HTTPS so it cannot be swapped in transit.
  NSURL *listURL = [NSURL URLWithString:addressFetchURL];
  if (![listURL.scheme.lowercaseString isEqualToString:@"https"] || listURL.host.length == 0) {
    WVSSLog(@"Ignoring address list URL: only https:// URLs are allowed");
    return;
  }

  _fetcher = [[WVSSAddressListFetcher alloc] initWithURL:addressFetchURL];
  _fetcher.delegate = self;
}

#pragma mark - WVSSAddressListFetcherDelegate

- (void)addressListFetcher:(WVSSAddressListFetcher *)fetcher didFailWithError:(NSError *)error {
  // Log domain/code only: the description can contain the list URL (and any token in it).
  WVSSLog(@"Fetching address list failed: %@ (%ld)", error.domain, (long)error.code);
}

- (void)addressListFetcher:(WVSSAddressListFetcher *)fetcher
        didFinishWithArray:(NSArray *)response {
  [self.addresses removeAllObjects];
  [self.addresses addObjectsFromArray:response];
}

@end
