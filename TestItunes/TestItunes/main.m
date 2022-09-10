//
//  main.m
//  TestItunes
//
//  Created by Jeff Verkoeyen on 9/9/22.
//

#import <Foundation/Foundation.h>
#import <iTunesLibrary/iTunesLibrary.h>

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    ITLibrary *library = [[ITLibrary alloc] initWithAPIVersion:@"1.0" error:nil];
    NSArray<ITLibMediaItem *> *items = [library allMediaItems];
    for (ITLibMediaItem * item in items) {
      id value = [item valueForProperty:ITLibMediaItemPropertyAlbumRating];
      NSLog(@"%@", value);
    }
      // insert code here...
      NSLog(@"Hello, World!");
  }
  return 0;
}
