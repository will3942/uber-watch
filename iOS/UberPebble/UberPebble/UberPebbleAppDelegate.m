//
//  UberPebbleAppDelegate.m
//  UberPebble
//
//  Created by Joshua Balfour on 01/09/2013.
//  Copyright (c) 2013 Josh Balfour. All rights reserved.
//

#import "UberPebbleAppDelegate.h"
#import <PebbleKit/PebbleKit.h>
#import <CoreLocation/CoreLocation.h>
#import "KBPebbleMessageQueue.h"

@interface UberPebbleAppDelegate ()  <PBPebbleCentralDelegate, CLLocationManagerDelegate>
{
    CLLocationManager* _locationManager;
	KBPebbleMessageQueue* _messageQueue;
    NSDictionary* cities;
}
@end

@implementation UberPebbleAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    NSData *citiesjson = [@"{\"London (UK)\": [ [\"london\", \"51.5118602\", \"-0.1267962\"]], \"Atlanta\": [ [\"atlairport\", \"33.6367\", \"-84.44403\"], [\"atlnorcross\", \"33.94121\", \"-84.21353\"], [\"atlriverdale\", \"33.572611\", \"-84.413259\"], [\"atlmableton\", \"33.8187167\", \"-84.5824329\"], [\"atlalpharetta\", \"34.0753762\", \"-84.2940899\"]], \"New York\": [ [\"nymanhattan\", \"40.7498502\", \"-73.9955249\"], [\"nybrooklyn\", \"40.65\", \"-73.94999\"], [\"nyridgewood\", \"40.9792645\", \"-74.1165313\"], [\"nynewark\", \"40.735657\", \"-74.172366\"], [\"nyqueens\", \"40.7282239\", \"-73.7948516\"], [\"nybronx\", \"40.85\", \"-73.866667\"]], \"Los Angeles\": [ [\"laedendale\", \"34.0793445\", \"-118.2613771\"], [\"laeast\", \"34.0239015\", \"-118.172015\"], [\"la\", \"34.0522342\", \"-118.2436849\"], [\"lalongbeach\", \"33.80416\", \"-118.1580556\"], [\"lasanpedro\", \"33.7360619\", \"-118.2922461\"], [\"latorrance\", \"33.8358492\", \"-118.3406287\"], [\"lacompton\", \"33.8958492\", \"-118.2200712\"], [\"lawhittier\", \"33.9791793\", \"-118.032844\"], [\"lasantamonica\", \"34.0194543\", \"-118.4911912\"], [\"laelmonte\", \"34.0686206\", \"-118.02756\"], [\"lahollywood\", \"34.0928\", \"-118.3286613\"], [\"lavannuys\", \"34.18985\", \"-118.451357\"]], \"San Francisco\": [ [\"sfsanjose\", \"37.3393857\", \"-121.894955\"], [\"sfsunnyvale\", \"37.36883\", \"-122.0363496\"], [\"sfcupertino\", \"37.3229978\", \"-122.0321822\"], [\"sfpaloalto\", \"37.4418834\", \"-122.1430194\"], [\"sfsanmateo\", \"37.5629917\", \"-122.3255254\"], [\"sf\", \"37.7749295\", \"-122.4194155\"], [\"sfberkeley\", \"37.8715926\", \"-122.2727469\"], [\"sfoakland\", \"37.8043637\", \"-122.2711137\"], [\"sfhayward\", \"37.6688205\", \"-122.0807964\"]], \"Shanghai\": [ [\"sh\", \"31.230393\", \"121.473704\"], [\"shpudong\", \"31.2219589\", \"121.5447209\"]]}" dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error = Nil;
    cities = [NSJSONSerialization JSONObjectWithData:citiesjson options:kNilOptions error:&error];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.distanceFilter = 50.0;
    _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    _locationManager.delegate = self;
    
	_messageQueue = [[KBPebbleMessageQueue alloc] init];
	_messageQueue.watch = PBPebbleCentral.defaultCentral.lastConnectedWatch;
    [PBPebbleCentral.defaultCentral.lastConnectedWatch appMessagesGetIsSupported:^(PBWatch *watch, BOOL isAppMessagesSupported) {
		if (!isAppMessagesSupported)
		{
			[[[UIAlertView alloc] initWithTitle:@"Error" message:@"Pebble doesn't support AppMessages" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
			return;
		}
		
		uint8_t uuid[] = { 0x90, 0x05, 0xE0, 0x6F, 0x77, 0x4D, 0x4A, 0x57, 0x8D, 0x38, 0x8A, 0x0B, 0x6A, 0x24, 0xED, 0x12 };
		[watch appMessagesSetUUID:[NSData dataWithBytes:uuid length:sizeof(uuid)]];
		[_locationManager startUpdatingLocation];
        
        
        [watch appMessagesAddReceiveUpdateHandler:^(PBWatch *watch,NSDictionary *update){
            NSLog(@"%@",update);
            NSString* action= [update objectForKey:@(0)];
            if ([action isEqualToString:@"location"]){
                NSString*value= [update objectForKey:@(1)];
                [self sendToPebble:value];
            }
            return YES;
        }];
        
        
	}];
    
    return YES;
}
-(NSString*)getStreetAddress:(NSString*)latitude :(NSString*)longitude{
    
    NSString* url = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?latlng=%@,%@&sensor=false",latitude,longitude];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    NSError* error;
	NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if ([(NSString*)json[@"status"] isEqualToString:@"OVER_QUERY_LIMIT"]){
        return @"Error";
    }
    return json[@"results"][0][@"address_components"][1][@"long_name"];
}
- (NSString *) getDataFrom:(NSString *)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        NSLog(@"Error getting %@, HTTP status code %i", url, [responseCode statusCode]);
        return @"Error";
    }
    
    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
}
-(void)sendToPebble:(NSString*)value{
    NSString* urls;
    if ([value isEqualToString:@"My Location"]){
        urls = [NSString stringWithFormat:@"http://uber.will3942.com:43278/pebble/location/%@/%@",lat,lng];
    } else {
        urls = [NSString stringWithFormat:@"http://uber.will3942.com:43278/pebble/location/%@/%@",cities[value][0][1],cities[value][0][2]];
    }
    
    NSLog(@"%@",urls);
    NSURL* url = [NSURL URLWithString:urls];
    NSLog(@"%@",[url port]);
    NSString *das=[self getDataFrom:urls];
    if (![das isEqualToString:@"Error"]){
    
        NSData* data = [[[NSString alloc] initWithString: das] dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"%@",data);
        NSError* error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSLog(@"%@",json);
        NSString* latitude;
        NSString* longitude;
        for(int key = 0; key<[json count]; key++) {
            NSDictionary* value = [(NSArray*)json objectAtIndex:key];
            for (int key2 = 0; key2<[value count]; key2++){
                NSDictionary* thedictionary = [(NSArray*)value objectAtIndex: key2];
                latitude = [thedictionary objectForKey:@"latitude"];
                longitude = [thedictionary objectForKey:@"longitude"];
                NSString *sa = [self getStreetAddress:latitude :longitude];
                if (![sa isEqualToString:@"Error"]){
                    NSDictionary* message =
                    [[NSDictionary alloc] initWithObjectsAndKeys:
                     @"add_cab", @(0),
                     sa, @(1),
                     [NSString stringWithFormat:@"%ld km away", lroundf([[[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]] distanceFromLocation:
                                                        [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lng doubleValue]]]/1000)], @(2),
                     nil];
                    
                    [_messageQueue enqueue:message];
                }
            }
        }
        
    }
    NSDictionary* message =
    [[NSDictionary alloc] initWithObjectsAndKeys:
     @"completed", @(0),
     nil];
    
    [_messageQueue enqueue:message];
    
}

- (void) locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray*)locations
{
	CLLocationCoordinate2D thecoords = manager.location.coordinate;
    lat = [NSString stringWithFormat:@"%f",thecoords.latitude];
    lng = [NSString stringWithFormat:@"%f",thecoords.longitude];
    
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (void) pebbleCentral:(PBPebbleCentral*)central watchDidConnect:(PBWatch*)watch isNew:(BOOL)isNew
{
	_messageQueue.watch = watch;
	
	[watch appMessagesGetIsSupported:^(PBWatch* watch, BOOL isAppMessagesSupported)
     {
         if (!isAppMessagesSupported)
         {
             [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Pebble doesn't support AppMessages" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
             return;
         }
         
         uint8_t uuid[] = { 0x90, 0x05, 0xE0, 0x6F, 0x77, 0x4D, 0x4A, 0x57, 0x8D, 0x38, 0x8A, 0x0B, 0x6A, 0x24, 0xED, 0x12 };
         [watch appMessagesSetUUID:[NSData dataWithBytes:uuid length:sizeof(uuid)]];
         [_locationManager startUpdatingLocation];
     }];
}

- (void) pebbleCentral:(PBPebbleCentral*)central watchDidDisconnect:(PBWatch*)watch
{
	[[[UIAlertView alloc] initWithTitle:@"Disconnected!" message:[watch name] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
	
	if (_messageQueue.watch == watch || [watch isEqual:_messageQueue.watch])
		_messageQueue.watch = nil;
}

@end
