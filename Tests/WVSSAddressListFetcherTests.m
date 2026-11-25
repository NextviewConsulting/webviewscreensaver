//
//  WVSSAddressListFetcherTests.m
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

@interface WVSSAddressListFetcherTests : XCTestCase
@end

@implementation WVSSAddressListFetcherTests

- (NSData *)json:(NSString *)string {
  return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSHTTPURLResponse *)responseForURL:(NSString *)url status:(NSInteger)status {
  return [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:url]
                                     statusCode:status
                                    HTTPVersion:@"HTTP/1.1"
                                   headerFields:nil];
}

#pragma mark - URL rules

- (void)testAllowsHTTPSURLs {
  XCTAssertTrue([WVSSAddressListFetcher isAllowedAddressURL:@"https://example.com/page"]);
  XCTAssertTrue([WVSSAddressListFetcher isAllowedAddressURL:@"HTTPS://EXAMPLE.COM/"]);
}

- (void)testRejectsNonHTTPSURLs {
  NSArray *rejected = @[
    @"http://example.com/", @"file:///etc/passwd", @"/Users/someone/index.html",
    @"javascript:alert(1)", @"https:///no-host", @"", @"zoommtg://join"
  ];
  for (NSString *url in rejected) {
    XCTAssertFalse([WVSSAddressListFetcher isAllowedAddressURL:url], @"%@", url);
  }
}

#pragma mark - Responses

- (void)testAcceptsHTTPS200 {
  XCTAssertTrue([WVSSAddressListFetcher
      isAcceptableResponse:[self responseForURL:@"https://example.com/list.json" status:200]]);
}

- (void)testRejectsErrorStatus {
  XCTAssertFalse([WVSSAddressListFetcher
      isAcceptableResponse:[self responseForURL:@"https://example.com/list.json" status:404]]);
}

- (void)testRejectsResponseThatEndedOnHTTP {
  // e.g. an HTTPS list URL that redirected to plain HTTP
  XCTAssertFalse([WVSSAddressListFetcher
      isAcceptableResponse:[self responseForURL:@"http://example.com/list.json" status:200]]);
}

- (void)testRejectsNonHTTPResponse {
  NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://x.y/"]
                                                      MIMEType:@"application/json"
                                         expectedContentLength:0
                                              textEncodingName:nil];
  XCTAssertFalse([WVSSAddressListFetcher isAcceptableResponse:response]);
  XCTAssertFalse([WVSSAddressListFetcher isAcceptableResponse:nil]);
}

#pragma mark - Parsing

- (void)testParsesValidList {
  NSError *error = nil;
  NSUInteger skipped = 99;
  NSArray *list = [WVSSAddressListFetcher
      addressesFromJSONData:[self json:@"[{\"url\":\"https://a.example/\",\"duration\":60},"
                                       @"{\"url\":\"https://b.example/\",\"duration\":-1}]"]
                    skipped:&skipped
                      error:&error];
  XCTAssertNil(error);
  XCTAssertEqual(list.count, 2u);
  XCTAssertEqual(skipped, 0u);
  XCTAssertEqualObjects(((WVSSAddress *)list[0]).url, @"https://a.example/");
  XCTAssertEqual(((WVSSAddress *)list[0]).duration, 60);
  XCTAssertEqual(((WVSSAddress *)list[1]).duration, -1);
}

- (void)testSkipsNonHTTPSEntries {
  NSUInteger skipped = 0;
  NSArray *list = [WVSSAddressListFetcher
      addressesFromJSONData:[self json:@"[{\"url\":\"https://ok.example/\",\"duration\":60},"
                                       @"{\"url\":\"http://plain.example/\",\"duration\":60},"
                                       @"{\"url\":\"file:///etc/hosts\",\"duration\":60},"
                                       @"{\"url\":\"/Users/someone/page.html\",\"duration\":60}]"]
                    skipped:&skipped
                      error:nil];
  XCTAssertEqual(list.count, 1u);
  XCTAssertEqual(skipped, 3u);
  XCTAssertEqualObjects(((WVSSAddress *)list[0]).url, @"https://ok.example/");
}

- (void)testRejectsMalformedLists {
  NSArray *bad = @[
    @"not json", @"{\"url\":\"https://a.example/\"}", @"[\"https://a.example/\"]",
    @"[{\"url\":\"https://a.example/\"}]", @"[{\"url\":42,\"duration\":60}]",
    @"[{\"url\":\"https://a.example/\",\"duration\":\"60\"}]"
  ];
  for (NSString *json in bad) {
    NSError *error = nil;
    NSArray *list = [WVSSAddressListFetcher addressesFromJSONData:[self json:json]
                                                          skipped:NULL
                                                            error:&error];
    XCTAssertNil(list, @"%@", json);
    XCTAssertNotNil(error, @"%@", json);
  }
}

- (void)testRejectsNilData {
  NSError *error = nil;
  XCTAssertNil([WVSSAddressListFetcher addressesFromJSONData:nil skipped:NULL error:&error]);
  XCTAssertNotNil(error);
}

- (void)testEmptyListIsValid {
  NSArray *list = [WVSSAddressListFetcher addressesFromJSONData:[self json:@"[]"]
                                                        skipped:NULL
                                                          error:nil];
  XCTAssertNotNil(list);
  XCTAssertEqual(list.count, 0u);
}

@end
