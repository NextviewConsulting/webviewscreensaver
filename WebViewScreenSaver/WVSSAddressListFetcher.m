//
//  WVSSAddressFetcher.m
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

#import "WVSSAddressListFetcher.h"
#import "WVSSAddress.h"
#import "WVSSLog.h"

NSErrorDomain const WVSSAddressListErrorDomain = @"WVSSAddressListErrorDomain";

@interface WVSSAddressListFetcher () {
  NSURLSessionTask *_task;
}

@end

@implementation WVSSAddressListFetcher

- (id)initWithURL:(NSString *)url {
  self = [super init];
  if (self) {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    // Ephemeral session: no cookies or cache shared with the rest of the process.
    NSURLSession *session = [NSURLSession
        sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
    _task = [session
        dataTaskWithRequest:request
          completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                              NSError *_Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self didFinishLoading:data response:response error:error];
            });
          }];
    [_task resume];
    [session finishTasksAndInvalidate];
  }
  return self;
}

+ (BOOL)isAllowedAddressURL:(NSString *)urlString {
  if (![urlString isKindOfClass:NSString.class]) return NO;
  NSURL *url = [NSURL URLWithString:urlString];
  return [url.scheme.lowercaseString isEqualToString:@"https"] && url.host.length > 0;
}

+ (BOOL)isAcceptableResponse:(NSURLResponse *)response {
  if (![response isKindOfClass:NSHTTPURLResponse.class]) return NO;
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
  return httpResponse.statusCode == 200 &&
         [httpResponse.URL.scheme.lowercaseString isEqualToString:@"https"];
}

+ (NSError *)errorWithReason:(NSString *)reason {
  return [NSError errorWithDomain:WVSSAddressListErrorDomain
                             code:-1
                         userInfo:@{NSLocalizedDescriptionKey : reason}];
}

+ (NSArray *)addressesFromJSONData:(NSData *)data
                           skipped:(NSUInteger *)skipped
                             error:(NSError **)error {
  if (skipped) *skipped = 0;
  if (data == nil) {
    if (error) *error = [self errorWithReason:@"No data"];
    return nil;
  }

  NSError *jsonError = nil;
  id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
  if (json == nil) {
    if (error) *error = jsonError;
    return nil;
  }
  if (![json isKindOfClass:NSArray.class]) {
    if (error) *error = [self errorWithReason:@"Expected a JSON array"];
    return nil;
  }

  NSMutableArray *parsed = [NSMutableArray array];
  NSUInteger skippedCount = 0;
  for (id item in (NSArray *)json) {
    if (![item isKindOfClass:NSDictionary.class]) {
      if (error) *error = [self errorWithReason:@"Expected each entry to be an object"];
      return nil;
    }
    id url = item[@"url"];
    id duration = item[@"duration"];
    if (![url isKindOfClass:NSString.class] || ![duration isKindOfClass:NSNumber.class]) {
      if (error) *error = [self errorWithReason:@"Expected a string url and a number duration"];
      return nil;
    }

    // A remote list may only point at HTTPS pages: no plain HTTP, no file:// or
    // scheme-less entries that would load files from this Mac.
    if (![self isAllowedAddressURL:url]) {
      skippedCount++;
      continue;
    }
    [parsed addObject:[WVSSAddress addressWithURL:url
                                         duration:[(NSNumber *)duration integerValue]]];
  }

  if (skipped) *skipped = skippedCount;
  return parsed;
}

- (void)didFinishLoading:(NSData *)data
                response:(NSURLResponse *)response
                   error:(NSError *)error {
  if (error != nil) {
    [self.delegate addressListFetcher:self didFailWithError:error];
    return;
  }

  // Reject non-200 answers and redirects that ended up off HTTPS.
  if (![self.class isAcceptableResponse:response]) {
    NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class]
                           ? ((NSHTTPURLResponse *)response).statusCode
                           : 0;
    NSError *responseError =
        [NSError errorWithDomain:WVSSAddressListErrorDomain
                            code:status
                        userInfo:@{NSLocalizedDescriptionKey : @"Unexpected address list response"}];
    [self.delegate addressListFetcher:self didFailWithError:responseError];
    return;
  }

  NSUInteger skipped = 0;
  NSError *parseError = nil;
  NSArray *parsed = [self.class addressesFromJSONData:data skipped:&skipped error:&parseError];
  if (parsed == nil) {
    [self.delegate addressListFetcher:self didFailWithError:parseError];
    return;
  }
  if (skipped > 0) {
    WVSSLog(@"Skipped %lu non-https entries from address list", (unsigned long)skipped);
  }
  WVSSLog(@"fetching URLS finished");
  [self.delegate addressListFetcher:self didFinishWithArray:parsed];
}

@end
