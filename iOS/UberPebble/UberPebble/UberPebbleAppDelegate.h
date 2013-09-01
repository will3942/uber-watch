//
//  UberPebbleAppDelegate.h
//  UberPebble
//
//  Created by Joshua Balfour on 01/09/2013.
//  Copyright (c) 2013 Josh Balfour. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface UberPebbleAppDelegate : UIResponder <UIApplicationDelegate>{
    NSString* lat;
    NSString* lng;
}

@property (strong, nonatomic) UIWindow *window;

@end
