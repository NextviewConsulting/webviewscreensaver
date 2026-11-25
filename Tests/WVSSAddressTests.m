//
//  WVSSAddressTests.m
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

@interface WVSSAddressTests : XCTestCase
@end

@implementation WVSSAddressTests

- (void)testZeroDurationIsRaisedToMinimum {
  WVSSAddress *address = [WVSSAddress addressWithURL:@"https://example.com/" duration:0];
  XCTAssertEqualWithAccuracy(address.effectiveDuration, kWVSSMinimumDuration, 0.001);
}

- (void)testShortDurationIsRaisedToMinimum {
  WVSSAddress *address = [WVSSAddress addressWithURL:@"https://example.com/" duration:1];
  XCTAssertEqualWithAccuracy(address.effectiveDuration, kWVSSMinimumDuration, 0.001);
}

- (void)testNormalDurationIsKept {
  WVSSAddress *address = [WVSSAddress addressWithURL:@"https://example.com/" duration:600];
  XCTAssertEqualWithAccuracy(address.effectiveDuration, 600, 0.001);
}

- (void)testNegativeDurationMeansForever {
  WVSSAddress *address = [WVSSAddress addressWithURL:@"https://example.com/" duration:-1];
  XCTAssertTrue(address.effectiveDuration < 0);
}

- (void)testDefaultAddressHasURL {
  // Must never be nil: a nil URL crashes dictionaryRepresentation when saving settings.
  WVSSAddress *address = [WVSSAddress defaultAddress];
  XCTAssertTrue(address.url.length > 0);
  XCTAssertNotNil([address dictionaryRepresentation]);
}

- (void)testDictionaryRepresentation {
  WVSSAddress *address = [WVSSAddress addressWithURL:@"https://example.com/" duration:42];
  NSDictionary *dict = [address dictionaryRepresentation];
  XCTAssertEqualObjects(dict[kWVSSAddressURLKey], @"https://example.com/");
  XCTAssertEqualObjects(dict[kWVSSAddressTimeKey], @42);
}

@end
