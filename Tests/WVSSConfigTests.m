//
//  WVSSConfigTests.m
//  WebViewScreenSaver
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import "WVSSAddress.h"
#import "WVSSAddressListFetcher.h"
#import "WVSSConfig.h"

@interface WVSSConfigTests : XCTestCase
@end

@implementation WVSSConfigTests {
  NSString *_suiteName;
  NSUserDefaults *_defaults;
}

- (void)setUp {
  [super setUp];
  _suiteName = [NSString stringWithFormat:@"wvss-tests-%@", NSUUID.UUID.UUIDString];
  _defaults = [[NSUserDefaults alloc] initWithSuiteName:_suiteName];
}

- (void)tearDown {
  [_defaults removePersistentDomainForName:_suiteName];
  [super tearDown];
}

// Simulates a finished download without touching the network.
- (void)deliverFetchedList:(NSArray *)list to:(WVSSConfig *)config {
  [(id<WVSSAddressListFetcherDelegate>)config addressListFetcher:nil didFinishWithArray:list];
}

- (void)testEmptyDefaultsGetSampleAddress {
  WVSSConfig *config = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  XCTAssertEqual(config.addresses.count, 1u);
  XCTAssertTrue(((WVSSAddress *)config.addresses[0]).url.length > 0);
}

- (void)testAddressesRoundTripThroughDefaults {
  WVSSConfig *config = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  [config.addresses removeAllObjects];
  [config.addresses addObject:[WVSSAddress addressWithURL:@"https://one.example/" duration:30]];
  [config.addresses addObject:[WVSSAddress addressWithURL:@"https://two.example/" duration:-1]];
  [config synchronize];

  WVSSConfig *reloaded = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  XCTAssertEqual(reloaded.addresses.count, 2u);
  XCTAssertEqualObjects(((WVSSAddress *)reloaded.addresses[0]).url, @"https://one.example/");
  XCTAssertEqual(((WVSSAddress *)reloaded.addresses[0]).duration, 30);
  XCTAssertEqual(((WVSSAddress *)reloaded.addresses[1]).duration, -1);
}

- (void)testPersistWebsiteDataIsOffByDefault {
  WVSSConfig *config = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  XCTAssertFalse(config.persistWebsiteData);

  [_defaults setBool:YES forKey:@"kScreenSaverPersistWebsiteData"];
  WVSSConfig *optedIn = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  XCTAssertTrue(optedIn.persistWebsiteData);
}

- (void)testFetchedListDoesNotOverwriteSavedList {
  WVSSConfig *config = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  [config.addresses removeAllObjects];
  [config.addresses addObject:[WVSSAddress addressWithURL:@"https://mine.example/" duration:30]];
  config.shouldFetchAddressList = YES;

  [self deliverFetchedList:@[ [WVSSAddress addressWithURL:@"https://remote.example/" duration:60] ]
                        to:config];
  [config synchronize];

  // The user's own list is untouched in memory and on disk.
  XCTAssertEqual(config.addresses.count, 1u);
  XCTAssertEqualObjects(((WVSSAddress *)config.addresses[0]).url, @"https://mine.example/");
  WVSSConfig *reloaded = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  XCTAssertEqual(reloaded.addresses.count, 1u);
  XCTAssertEqualObjects(((WVSSAddress *)reloaded.addresses[0]).url, @"https://mine.example/");
}

- (void)testActiveAddressesFollowFetchSetting {
  WVSSConfig *config = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  [config.addresses removeAllObjects];
  [config.addresses addObject:[WVSSAddress addressWithURL:@"https://mine.example/" duration:30]];

  // Fetching on, nothing downloaded yet: show the user's list.
  config.shouldFetchAddressList = YES;
  XCTAssertEqualObjects(((WVSSAddress *)config.activeAddresses[0]).url, @"https://mine.example/");

  // Downloaded list arrives: show it.
  [self deliverFetchedList:@[ [WVSSAddress addressWithURL:@"https://remote.example/" duration:60] ]
                        to:config];
  XCTAssertEqualObjects(((WVSSAddress *)config.activeAddresses[0]).url, @"https://remote.example/");

  // Fetching switched off: back to the user's list.
  config.shouldFetchAddressList = NO;
  XCTAssertEqualObjects(((WVSSAddress *)config.activeAddresses[0]).url, @"https://mine.example/");
}

- (void)testDoesNotFetchFromHTTPListURL {
  WVSSConfig *config = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  config.shouldFetchAddressList = YES;
  config.addressListURL = @"http://example.com/list.json";
  [config fetchIfNeeded];
  XCTAssertFalse(config.isFetching);
}

- (void)testOnlyOneFetchAtATime {
  WVSSConfig *config = [[WVSSConfig alloc] initWithUserDefaults:_defaults];
  config.shouldFetchAddressList = YES;
  // Port 9 on localhost: fails fast, never leaves this machine.
  config.addressListURL = @"https://127.0.0.1:9/list.json";
  [config fetchIfNeeded];
  XCTAssertTrue(config.isFetching);
  [config fetchIfNeeded];  // ignored while the first download runs
  XCTAssertTrue(config.isFetching);

  // A failed download clears the flag so the next cycle can retry.
  [(id<WVSSAddressListFetcherDelegate>)config
      addressListFetcher:nil
        didFailWithError:[NSError errorWithDomain:@"test" code:1 userInfo:nil]];
  XCTAssertFalse(config.isFetching);
}

@end
