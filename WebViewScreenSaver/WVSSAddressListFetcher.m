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

NSExceptionName const WVSSInvalidArgumentException = @"WVSSInvalidArgumentException";

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
  NSURL *url = [NSURL URLWithString:urlString];
  return [url.scheme.lowercaseString isEqualToString:@"https"] && url.host.length > 0;
}

- (void)didFinishLoading:(NSData *)data
                response:(NSURLResponse *)urlResponse
                   error:(NSError *)error {
  if (error != nil) {
    [self.delegate addressListFetcher:self didFailWithError:error];
    return;
  }

  // Reject non-200 answers and redirects that ended up off HTTPS.
  NSHTTPURLResponse *httpResponse =
      [urlResponse isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)urlResponse : nil;
  if (httpResponse.statusCode != 200 ||
      ![httpResponse.URL.scheme.lowercaseString isEqualToString:@"https"] || data == nil) {
    NSError *responseError = [NSError
        errorWithDomain:WVSSInvalidArgumentException
                   code:httpResponse.statusCode
               userInfo:@{NSLocalizedDescriptionKey : @"Unexpected address list response"}];
    [self.delegate addressListFetcher:self didFailWithError:responseError];
    return;
  }

  NSError *jsonError = nil;
  id response = [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingMutableContainers
                                                  error:&jsonError];
  if (jsonError) {
    [self.delegate addressListFetcher:self didFailWithError:jsonError];
    return;
  }

  NSMutableArray *parsed = [[NSMutableArray alloc] init];
  NSUInteger skipped = 0;

  @try {
    expectClass(response, NSArray.class);
    for (NSDictionary *item in (NSArray *)response) {
      expectClass(item, NSDictionary.class);

      id url = item[@"url"];
      id duration = item[@"duration"];

      expectClass(url, NSString.class);
      expectClass(duration, NSNumber.class);

      // A remote list may only point at HTTPS pages: no plain HTTP, no file:// or
      // scheme-less entries that would load files from this Mac.
      if (![self.class isAllowedAddressURL:url]) {
        skipped++;
        continue;
      }

      [parsed addObject:[WVSSAddress addressWithURL:url duration:[(NSNumber *)duration intValue]]];
    }

    if (skipped > 0) {
      WVSSLog(@"Skipped %lu non-https entries from address list", (unsigned long)skipped);
    }

    [self.delegate addressListFetcher:self didFinishWithArray:parsed];
  } @catch (NSException *exception) {
    if ([exception.name isEqualToString:WVSSInvalidArgumentException]) {
      NSError *error = [NSError errorWithDomain:WVSSInvalidArgumentException
                                           code:-1
                                       userInfo:@{NSLocalizedDescriptionKey : exception.reason}];
      [self.delegate addressListFetcher:self didFailWithError:error];
    } else {
      [exception raise];
    }
  }

  WVSSLog(@"fetching URLS finished");
}

void expectClass(id target, Class aclass) {
  if (![target isKindOfClass:aclass]) {
    NSString *reason =
        [NSString stringWithFormat:@"Expected %@ but got %@", NSStringFromClass(aclass),
                                   NSStringFromClass([target class])];
    NSException *exc = [NSException exceptionWithName:WVSSInvalidArgumentException
                                               reason:reason
                                             userInfo:nil];
    [exc raise];
  }
}

@end
