//
//  ViewController.m
//  Demo-CoreLocation
//
//  Created by Jhonathan Wyterlin on 6/22/15.
//  Copyright (c) 2015 Jhonathan Wyterlin. All rights reserved.
//

#import "ViewController.h"

#import <CoreLocation/CoreLocation.h>

@interface ViewController ()<CLLocationManagerDelegate, UIAlertViewDelegate>

@property(nonatomic,strong) CLLocationManager *locationManager;
@property(nonatomic,strong) IBOutlet UIActivityIndicatorView *loadingGps;
@property(nonatomic) BOOL gpsDenied;

@property(nonatomic,strong) UILabel *zip;
@property(nonatomic,strong) UILabel *street;
@property(nonatomic,strong) UILabel *neighborhood;
@property(nonatomic,strong) UILabel *city;
@property(nonatomic,strong) UILabel *state;

@end

@implementation ViewController

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self initializeLocationManager];
    
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - IBAction methods

-(IBAction)find:(id)sender {
    [self findMe];
}

#pragma mark - CLLocationManagerDelegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    NSLog( @"locationManager: %@ didUpdateLocations: %@", manager, locations );
    
    [self.loadingGps stopAnimating];
    
    [self.locationManager stopUpdatingLocation];
    
    CLGeocoder *geocoder = [CLGeocoder new];
    
    [geocoder reverseGeocodeLocation:self.locationManager.location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        NSLog( @"reverseGeocodeLocation:completionHandler: Completion Handler called!" );
        
        NSLog( @"placemarks: %@", placemarks );
        
        NSLog( @"placemarks.count: %i", (int)placemarks.count );
        
        if ( error ) {
            NSLog( @"Geocode failed with error: %@", error );
            return;
        }
        
        CLPlacemark *placemark = placemarks[0];
        
        NSLog( @"placemark: %@", placemark );
        
        // Get Location Info
        
        // Zip
        NSString *postalCode = placemark.addressDictionary[@"ZIP"];
        NSString *postalCodeExtension = placemark.addressDictionary[@"PostCodeExtension"];
        
        if ( ! postalCodeExtension )
            postalCodeExtension = @"000";
        
        self.zip.text = [NSString stringWithFormat:@"ZIP: %@-%@", postalCode, postalCodeExtension];
        
        // Street
        
        // You can use this
        self.street.text = placemark.addressDictionary[@"Thoroughfare"];
        
        // Or this
        NSString *streetName = placemark.addressDictionary[@"Name"];
        
        // Get street address until comma
        BOOL containComma = NO;
        
        if ( [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0 ) {
            if ( streetName )
                containComma = ( [streetName rangeOfString:@","].location != NSNotFound );
        } else {
            containComma = [streetName containsString:@","];
        }
        
        if ( containComma ) {
            NSRange range = [streetName rangeOfString:@","];
            NSRange rangeToSubstring = NSMakeRange( 0, range.location );
            streetName = [streetName substringWithRange:rangeToSubstring];
        }
        
        self.street.text = [NSString stringWithFormat:@"Street: %@", streetName];
        
        // Neighborhood
        NSString *neighborhood = placemark.addressDictionary[@"SubLocality"];
        
        self.neighborhood.text = neighborhood;
        
        // City
        NSString *city = placemark.addressDictionary[@"City"];
        
        self.city.text = city;
        
        // State
        NSString *state = placemark.addressDictionary[@"State"];
        
        self.state.text = state;
        
    }];
    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    NSLog( @"locationManager: %@ didFailWithError: %@", manager, error );
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:error.localizedDescription
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    [self.loadingGps stopAnimating];
    
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    NSLog( @"didChangeAuthorizationStatus: %i", status );
    
    self.gpsDenied = ( status == kCLAuthorizationStatusDenied );
    
}

#pragma mark - Private methods

-(void)initializeLocationManager {
    
    // this creates the CCLocationManager that will find your current location
    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = CLLocationDistanceMax;
    
    if ( [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)] ) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
}

-(void)findMe {
    
    if ( self.gpsDenied ) {
        
        NSString *title = @"The app has no access to Location Services";
        NSString *message = @"You can allow access to \nSettings > Privacy > \nServ. location";
        
        if ( [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0 ) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
            
        } else {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:@"Settings", nil];
            alert.tag = 121;
            [alert show];
            
        }
        
    } else {
        
        [self.loadingGps startAnimating];
        
        [self.locationManager startUpdatingLocation];
        
    }
    
}

#pragma mark - UIAlertView Delegate Methods

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ( alertView.tag == 121 && buttonIndex == 1 ) {
        // code for opening settings app in iOS 8
        [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    }
    
}

#pragma mark - Creating components

-(UILabel *)zip {
    
    if ( ! _zip ) {
        
        int x = 15;
        int y = 70;
        int width = [UIScreen mainScreen].bounds.size.width - ( 2 * x );
        int height = 21;
        
        _zip = [[UILabel alloc] initWithFrame:CGRectMake( x, y, width, height )];
        [self.view addSubview:_zip];
        
    }
    
    return _zip;
    
}

-(UILabel *)street {
    
    if ( ! _street ) {
        
        int x = 15;
        int y = 95;
        int width = [UIScreen mainScreen].bounds.size.width - ( 2 * x );
        int height = 21;
        
        _street = [[UILabel alloc] initWithFrame:CGRectMake( x, y, width, height )];
        [self.view addSubview:_street];
        
    }
    
    return _street;
    
}

-(UILabel *)neighborhood {
    
    if ( ! _neighborhood ) {
        
        int x = 15;
        int y = 120;
        int width = [UIScreen mainScreen].bounds.size.width - ( 2 * x );
        int height = 21;
        
        _neighborhood = [[UILabel alloc] initWithFrame:CGRectMake( x, y, width, height )];
        [self.view addSubview:_neighborhood];
        
    }
    
    return _neighborhood;
    
}

-(UILabel *)city {
    
    if ( ! _city ) {
        
        int x = 15;
        int y = 145;
        int width = [UIScreen mainScreen].bounds.size.width - ( 2 * x );
        int height = 21;
        
        _city = [[UILabel alloc] initWithFrame:CGRectMake( x, y, width, height )];
        [self.view addSubview:_city];
        
    }
    
    return _city;
    
}

-(UILabel *)state {
    
    if ( ! _state ) {
        
        int x = 15;
        int y = 170;
        int width = [UIScreen mainScreen].bounds.size.width - ( 2 * x );
        int height = 21;
        
        _state = [[UILabel alloc] initWithFrame:CGRectMake( x, y, width, height )];
        [self.view addSubview:_state];
        
    }
    
    return _state;
    
}

@end
